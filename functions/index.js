const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Set global options (e.g., region)
setGlobalOptions({ region: "us-central1", invoker: "public" });

// Firestore Constants (matching client-side)
const USERS_COLLECTION = 'users';
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
