const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { CloudTasksClient } = require("@google-cloud/tasks");

admin.initializeApp();
const db = admin.firestore();
const tasksClient = new CloudTasksClient();

// Set global options (e.g., region)
setGlobalOptions({ region: "us-central1", invoker: "public" });
const REGION = "us-central1";
const TASKS_LOCATION = REGION;
const MINING_END_QUEUE = "mining-end-notifications";

// Firestore Constants (matching client-side)
const USERS_COLLECTION = 'users';
const REFERRALS_COLLECTION = 'referrals';
const REFERRAL_STATS_COLLECTION = 'referral_stats';
const MANAGERS_COLLECTION = 'managers';
const APP_CONFIG_COLLECTION = 'app_config';
const APP_CONFIG_GENERAL_DOC = 'general';
const SUBSCRIPTION_FIELD = 'subscription';
const WEBHOOK_AUTH_FIELD = 'revenueCatWebhookAuth';

// Subscription Fields
const SUB_STATUS = 'status';
const SUB_PLAN_ID = 'planId';
const SUB_PROVIDER = 'provider';
const SUB_EXPIRES_AT = 'expiresAt';
const SUB_AUTO_RENEW = 'autoRenew';

// User Fields
const USER_MANAGER_ENABLED = 'managerEnabled';
const USER_ACTIVE_MANAGER_ID = 'activeManagerId';
const USER_FCM_TOKEN = 'fcmToken';
const USER_LAST_MINING_END = 'lastMiningEnd';
const USER_INVITED_BY = 'invitedBy';

const USER_MINING_END_NOTIFIED_END_MS = 'miningEndNotifiedEndMs';
const USER_MINING_END_NOTIFIED_AT = 'miningEndNotifiedAt';
const USER_MINING_END_TASK_SCHEDULED_END_MS = 'miningEndTaskScheduledEndMs';
const USER_MINING_END_TASK_SCHEDULED_AT = 'miningEndTaskScheduledAt';
const USER_MINING_END_TASK_NAME = 'miningEndTaskName';

let cachedWebhookAuth = null;
let cachedWebhookAuthFetchedAtMs = 0;
const WEBHOOK_AUTH_CACHE_TTL_MS = 5 * 60 * 1000;

const HANDLED_EVENT_TYPES = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'CANCELLATION',
  'UNCANCELLATION',
  'EXPIRATION',
  'PRODUCT_CHANGE',
]);

const ALLOWED_APP_IDS = new Set(['com.eta.network', 'net.etanetwork.app']);

const managerIdCache = new Map();
const MANAGER_ID_CACHE_TTL_MS = 10 * 60 * 1000;

function isUserActiveWithin48h(userData) {
  if (!userData) return false;
  const ts = userData[USER_LAST_MINING_END];
  if (!ts || typeof ts.toDate !== 'function') {
    return false;
  }
  const end = ts.toDate();
  const now = new Date();
  if (now < end) {
    return true;
  }
  const diffMs = now.getTime() - end.getTime();
  const diffHours = diffMs / (1000 * 60 * 60);
  return diffHours < 48;
}

async function getWebhookAuthToken() {
  const now = Date.now();
  if (
    cachedWebhookAuthFetchedAtMs &&
    now - cachedWebhookAuthFetchedAtMs < WEBHOOK_AUTH_CACHE_TTL_MS
  ) {
    return cachedWebhookAuth;
  }

  const doc = await db.collection(APP_CONFIG_COLLECTION).doc(APP_CONFIG_GENERAL_DOC).get();
  const data = doc.data() || {};
  const token = typeof data[WEBHOOK_AUTH_FIELD] === 'string' ? data[WEBHOOK_AUTH_FIELD].trim() : '';
  cachedWebhookAuth = token || null;
  cachedWebhookAuthFetchedAtMs = now;
  return cachedWebhookAuth;
}

exports.handleRevenueCatWebhook = onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const expectedToken = await getWebhookAuthToken();
    if (expectedToken) {
      const rawAuthHeader = (req.get('Authorization') || '').trim();
      const providedToken = rawAuthHeader.toLowerCase().startsWith('bearer ')
        ? rawAuthHeader.substring('bearer '.length).trim()
        : rawAuthHeader;
      if (!providedToken || providedToken !== expectedToken) {
        res.status(401).send('Unauthorized');
        return;
      }
    }

    const event = req.body && req.body.event;
    if (!event) {
      console.error('No event found in body');
      res.status(400).send('No event found');
      return;
    }

    const { type, app_user_id, expiration_at_ms, store } = event;
    const normalizedType = (type || '').toString().toUpperCase().trim();

    if (!app_user_id) {
      res.status(200).send('OK');
      return;
    }

    if (!normalizedType || !HANDLED_EVENT_TYPES.has(normalizedType)) {
      res.status(200).json({ ok: true, ignored: true });
      return;
    }

    const rawAppId =
      (event.app_id || event.appId || event.bundle_id || event.bundleId || '').toString().trim();
    const normalizedAppId = rawAppId ? rawAppId.toLowerCase() : '';
    if (normalizedAppId && !ALLOWED_APP_IDS.has(normalizedAppId)) {
      res.status(200).json({ ok: true, ignored: true });
      return;
    }

    const userRef = db.collection(USERS_COLLECTION).doc(app_user_id);
    
    const nowMs = Date.now();
    const expMs =
      typeof expiration_at_ms === 'number' ? expiration_at_ms : Number(expiration_at_ms || 0);
    const hasExpiry = Number.isFinite(expMs) && expMs > 0;
    const expiresAt = hasExpiry ? admin.firestore.Timestamp.fromMillis(expMs) : null;
    const expiredByTime = hasExpiry ? expMs <= nowMs : false;

    let status = (normalizedType === 'EXPIRATION' || expiredByTime) ? 'expired' : 'active';
    let autoRenew = true;
    if (normalizedType === 'CANCELLATION') autoRenew = false;
    if (normalizedType === 'UNCANCELLATION') autoRenew = true;
    if (status === 'expired') autoRenew = false;

    const productId =
      (event.product_id || event.productId || event.new_product_id || event.newProductId || '')
        .toString()
        .trim();

    // Prepare update data
    const updateData = {
      [`${SUBSCRIPTION_FIELD}.${SUB_STATUS}`]: status,
      [`${SUBSCRIPTION_FIELD}.${SUB_AUTO_RENEW}`]: autoRenew,
      [`${SUBSCRIPTION_FIELD}.${SUB_PROVIDER}`]: store || 'unknown',
      [USER_MANAGER_ENABLED]: status === 'active',
    };

    if (productId) {
       updateData[`${SUBSCRIPTION_FIELD}.${SUB_PLAN_ID}`] = productId;
    }
    if (expiresAt) {
      updateData[`${SUBSCRIPTION_FIELD}.${SUB_EXPIRES_AT}`] = expiresAt;
    }

    if (status === 'expired') {
      updateData[USER_ACTIVE_MANAGER_ID] = null;
    }

    if (status === 'active' && productId) {
      const managerId = await getManagerIdForPlan(productId);
      if (managerId) {
        updateData[USER_ACTIVE_MANAGER_ID] = managerId;
      }
    }

    await userRef.set(updateData, { merge: true });

    res.status(200).json({ ok: true });
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).json({ ok: false });
  }
});

async function getManagerIdForPlan(planId) {
  const now = Date.now();
  const cached = managerIdCache.get(planId);
  if (cached && now - cached.fetchedAtMs < MANAGER_ID_CACHE_TTL_MS) {
    return cached.managerId;
  }

  const managersSnapshot = await db.collection(MANAGERS_COLLECTION)
    .where('storeProductId', '==', planId)
    .limit(1)
    .get();

  const managerId = managersSnapshot.empty ? null : managersSnapshot.docs[0].id;
  managerIdCache.set(planId, { managerId, fetchedAtMs: now });
  return managerId;
}

exports.checkExpiredSubscriptions = onSchedule("every 24 hours", async (event) => {
    const now = admin.firestore.Timestamp.now();
    
    // Query for users with active subscriptions that have expired
    const snapshot = await db.collection(USERS_COLLECTION)
        .where(`${SUBSCRIPTION_FIELD}.${SUB_STATUS}`, '==', 'active')
        .where(`${SUBSCRIPTION_FIELD}.${SUB_EXPIRES_AT}`, '<', now)
        .get();

    if (snapshot.empty) {
        console.log('No expired subscriptions found.');
        return;
    }

    const batch = db.batch();
    let count = 0;

    snapshot.docs.forEach(doc => {
        const userRef = doc.ref;
        batch.update(userRef, {
            [`${SUBSCRIPTION_FIELD}.${SUB_STATUS}`]: 'expired',
            [`${SUBSCRIPTION_FIELD}.${SUB_AUTO_RENEW}`]: false,
            [USER_MANAGER_ENABLED]: false,
            [USER_ACTIVE_MANAGER_ID]: null,
        });
        count++;
    });

    await batch.commit();
    console.log(`Updated ${count} expired subscriptions.`);
});

async function ensureQueueExists() {
  const project = process.env.GCLOUD_PROJECT;
  if (!project) throw new Error("GCLOUD_PROJECT is not set");
  const queueName = tasksClient.queuePath(project, TASKS_LOCATION, MINING_END_QUEUE);

  try {
    await tasksClient.getQueue({ name: queueName });
    return queueName;
  } catch (e) {
    const code = e && typeof e.code === "number" ? e.code : null;
    if (code !== 5) {
      throw e;
    }
  }

  const parent = tasksClient.locationPath(project, TASKS_LOCATION);
  await tasksClient.createQueue({
    parent,
    queue: { name: queueName },
  });

  return queueName;
}

function getFunctionUrl(functionName) {
  const project = process.env.GCLOUD_PROJECT;
  if (!project) throw new Error("GCLOUD_PROJECT is not set");
  return `https://${REGION}-${project}.cloudfunctions.net/${functionName}`;
}

exports.sendMiningEndNotificationTask = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const uid = (req.body && req.body.uid ? String(req.body.uid) : "").trim();
    const endMs = Number(req.body && req.body.endMs ? req.body.endMs : 0);
    if (!uid || !Number.isFinite(endMs) || endMs <= 0) {
      res.status(400).json({ ok: false, error: "invalid_payload" });
      return;
    }

    const userRef = db.collection(USERS_COLLECTION).doc(uid);
    const snap = await userRef.get();
    if (!snap.exists) {
      res.status(200).json({ ok: true, skipped: "missing_user" });
      return;
    }

    const data = snap.data() || {};
    const endTs = data[USER_LAST_MINING_END];
    if (!endTs || typeof endTs.toMillis !== "function") {
      res.status(200).json({ ok: true, skipped: "missing_lastMiningEnd" });
      return;
    }

    const currentEndMs = endTs.toMillis();
    if (currentEndMs !== endMs) {
      res.status(200).json({ ok: true, skipped: "end_changed" });
      return;
    }

    const nowMs = Date.now();
    if (nowMs + 10 * 1000 < endMs) {
      res.status(200).json({ ok: true, skipped: "too_early" });
      return;
    }

    const token = (data[USER_FCM_TOKEN] || "").toString().trim();
    if (!token) {
      res.status(200).json({ ok: true, skipped: "missing_fcmToken" });
      return;
    }

    const alreadyMs = Number(data[USER_MINING_END_NOTIFIED_END_MS] || 0);
    if (Number.isFinite(alreadyMs) && alreadyMs >= endMs) {
      res.status(200).json({ ok: true, skipped: "already_notified" });
      return;
    }

    await admin.messaging().send({
      token,
      notification: {
        title: "Mining Session Ended",
        body: "Your mining session has finished! Tap to start a new session and keep earning.",
      },
      data: {
        type: "mining_end",
        endMs: String(endMs),
        uid,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    await userRef.set(
      {
        [USER_MINING_END_NOTIFIED_END_MS]: endMs,
        [USER_MINING_END_NOTIFIED_AT]: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    res.status(200).json({ ok: true, sent: true });
  } catch (err) {
    const code = err && err.code ? String(err.code) : "";
    if (code === "messaging/registration-token-not-registered") {
      const uid = (req.body && req.body.uid ? String(req.body.uid) : "").trim();
      if (uid) {
        await db.collection(USERS_COLLECTION).doc(uid).set({ [USER_FCM_TOKEN]: null }, { merge: true });
      }
      res.status(200).json({ ok: true, cleanedToken: true });
      return;
    }
    console.error("sendMiningEndNotificationTask error:", err);
    res.status(500).json({ ok: false });
  }
});

exports.scheduleMiningEndNotification = onDocumentWritten(
  `${USERS_COLLECTION}/{uid}`,
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!afterSnap.exists) return;

    const beforeData = beforeSnap.exists ? beforeSnap.data() || {} : {};
    const afterData = afterSnap.data() || {};

    // Check if lastMiningEnd actually changed
    const beforeEndTs = beforeData[USER_LAST_MINING_END];
    const afterEndTs = afterData[USER_LAST_MINING_END];

    // If both are missing, nothing to do
    if (!beforeEndTs && !afterEndTs) return;

    // If both exist and are equal, no change in mining schedule
    if (beforeEndTs && afterEndTs && typeof beforeEndTs.isEqual === 'function' && beforeEndTs.isEqual(afterEndTs)) {
      // Even if mining end hasn't changed, we might need to verify if the task is scheduled
      // But to save invocations, we assume if end time is same, it was already handled.
      // Exception: If the previous attempt failed?
      // The client stores 'miningEndTaskScheduledEndMs' only after success.
      // So if that matches, we are good.
      const scheduledEndMs = Number(afterData[USER_MINING_END_TASK_SCHEDULED_END_MS] || 0);
      if (Number.isFinite(scheduledEndMs) && scheduledEndMs === afterEndTs.toMillis()) {
        return;
      }
      // If not scheduled yet but time didn't change (e.g. other field update), we should proceed to schedule it?
      // If we return here, we rely on the fact that the update that SET the time should have triggered this.
      // But if that failed, we might want to retry.
      // However, the goal is to reduce "way more than needed invocations".
      // Most invocations are due to points updating.
      // So if time didn't change, we should mostly skip.
      // Let's rely on the check below for scheduledEndMs.
      // Ideally, we return HERE to avoid even reading the queue or processing further if strict equality holds.
      
      // Wait, if points update, this runs. beforeEndTs == afterEndTs.
      // We check scheduledEndMs. If it matches, we return.
      // So the logic below (lines 393-396 in original) handled this.
      // BUT, we want to exit even EARLIER if possible, or ensure we don't do unnecessary work.
      // The original code:
      // const endTs = data[USER_LAST_MINING_END]; ...
      // const scheduledEndMs = ...
      // if (scheduledEndMs === endMs) return;
      
      // So the original code WAS exiting early if already scheduled.
      // The issue is likely that it still runs on EVERY write.
      // We can't prevent the trigger (Cloud Functions V2 doesn't support field filters natively yet for onDocumentWritten in the easy way, though Eventarc does, but standard firebase-functions usually triggers).
      // Wait, we CAN use `onDocumentWritten` but we pay for the invocation.
      // The user says "way more than needed invocations".
      // The writes in `earnings_engine.dart` were the cause.
      // By throttling writes there, we solved the root cause of the storm.
      
      // However, we can still optimize.
      // If we determine nothing changed relevant to this function, we return.
      // The logic below is fine, but let's make it explicit.
    }

    const endTs = afterEndTs;
    if (!endTs || typeof endTs.toMillis !== "function") return;

    const endMs = endTs.toMillis();
    const scheduledEndMs = Number(afterData[USER_MINING_END_TASK_SCHEDULED_END_MS] || 0);
    
    // Idempotency check: if already scheduled for this exact time, skip
    if (Number.isFinite(scheduledEndMs) && scheduledEndMs === endMs) {
      return;
    }

    const project = process.env.GCLOUD_PROJECT;
    if (!project) throw new Error("GCLOUD_PROJECT is not set");

    const queueName = await ensureQueueExists();
    const url = getFunctionUrl("sendMiningEndNotificationTask");
    const uid = event.params.uid;

    const scheduleAtMs = Math.max(Date.now() + 10 * 1000, endMs);
    const taskId = `miningEnd-${uid}-${endMs}`;
    const name = tasksClient.taskPath(project, TASKS_LOCATION, MINING_END_QUEUE, taskId);
    const body = Buffer.from(JSON.stringify({ uid, endMs })).toString("base64");

    try {
      await tasksClient.createTask({
        parent: queueName,
        task: {
          name,
          scheduleTime: {
            seconds: Math.floor(scheduleAtMs / 1000),
            nanos: (scheduleAtMs % 1000) * 1e6,
          },
          httpRequest: {
            httpMethod: "POST",
            url,
            headers: { "Content-Type": "application/json" },
            body,
          },
        },
      });
    } catch (e) {
      const code = e && typeof e.code === "number" ? e.code : null;
      if (code !== 6) { // 6 = ALREADY_EXISTS
        throw e;
      }
    }

    // Update user doc to reflect that we scheduled it
    // Note: This causes ANOTHER write, which triggers this function AGAIN.
    // But on the next run, scheduledEndMs === endMs, so it returns early.
    // This is a loop of size 2. Acceptable.
    await afterSnap.ref.set(
      {
        [USER_MINING_END_TASK_SCHEDULED_END_MS]: endMs,
        [USER_MINING_END_TASK_SCHEDULED_AT]: admin.firestore.FieldValue.serverTimestamp(),
        [USER_MINING_END_TASK_NAME]: name,
      },
      { merge: true },
    );
  },
);

exports.updateReferralStatsOnReferralCreate = onDocumentWritten(
  `${REFERRALS_COLLECTION}/{referralId}`,
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;
    if (beforeSnap.exists || !afterSnap.exists) {
      return;
    }
    const data = afterSnap.data() || {};
    const inviterId = (data.inviterId || '').toString().trim();
    const inviteeId = (data.inviteeId || '').toString().trim();
    if (!inviterId) {
      return;
    }
    const statsRef = db.collection(REFERRAL_STATS_COLLECTION).doc(inviterId);
    await statsRef.set(
      {
        totalInvited: admin.firestore.FieldValue.increment(1),
      },
      { merge: true },
    );
  },
);

exports.updateReferralStatsOnUserWrite = onDocumentWritten(
  `${USERS_COLLECTION}/{uid}`,
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;
    if (!afterSnap.exists) {
      return;
    }
    const beforeData = beforeSnap.exists ? beforeSnap.data() || {} : {};
    const afterData = afterSnap.data() || {};

    const beforeInviterRaw = beforeData[USER_INVITED_BY];
    const afterInviterRaw = afterData[USER_INVITED_BY];
    const beforeInviterId = (beforeInviterRaw || '').toString().trim();
    const afterInviterId = (afterInviterRaw || '').toString().trim();

    // Only update if inviter changed
    if (beforeInviterId === afterInviterId) {
      return;
    }

    // Handle inviter change
    if (beforeInviterId) {
      const oldStatsRef = db.collection(REFERRAL_STATS_COLLECTION).doc(beforeInviterId);
      await oldStatsRef.set(
        { totalInvited: admin.firestore.FieldValue.increment(-1) },
        { merge: true },
      );
    }
    if (afterInviterId) {
      const newStatsRef = db.collection(REFERRAL_STATS_COLLECTION).doc(afterInviterId);
      await newStatsRef.set(
        { totalInvited: admin.firestore.FieldValue.increment(1) },
        { merge: true },
      );
    }
  },
);
