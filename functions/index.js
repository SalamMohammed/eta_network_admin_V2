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
const REFERRAL_SHARDS_COLLECTION = 'referral_shards';
const REFERRAL_ALERTS_COLLECTION = 'referral_alerts';
const REFERRAL_INVITER_ID = 'inviterId';
const REFERRAL_INVITEE_ID = 'inviteeId';
const REFERRAL_TIMESTAMP = 'timestamp';
const REFERRAL_IS_ACTIVE = 'isActive';
const REFERRAL_INVITEE_USERNAME = 'inviteeUsername';

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
const USER_INVITED_BY = 'invitedBy';
const USER_TOTAL_INVITED = 'totalInvited';
const USER_USERNAME = 'username';

const USER_MINING_END_NOTIFIED_END_MS = 'miningEndNotifiedEndMs';
const USER_MINING_END_NOTIFIED_AT = 'miningEndNotifiedAt';
const USER_MINING_END_TASK_SCHEDULED_END_MS = 'miningEndTaskScheduledEndMs';
const USER_MINING_END_TASK_SCHEDULED_AT = 'miningEndTaskScheduledAt';
const USER_MINING_END_TASK_NAME = 'miningEndTaskName';

// Earnings / Migration Fields (must match client Firestore constants)
const USER_TOTAL_POINTS = 'totalPoints';
const USER_HOURLY_RATE = 'hourlyRate';
const USER_LAST_MINING_START = 'lastMiningStart';
const USER_LAST_MINING_END = 'lastMiningEnd';
const USER_LAST_SYNCED_AT = 'lastSyncedAt';
const USER_MIGRATION_FLAG = 'migrationUnifiedEarnings';
const USER_BONUS_24_APPLIED = 'bonus24Applied';
const USER_RATE_BASE = 'rateBase';
const USER_RATE_STREAK = 'rateStreak';
const USER_RATE_RANK = 'rateRank';
const USER_RATE_REFERRAL = 'rateReferral';
const USER_RATE_MANAGER = 'rateManager';
const USER_RATE_ADS = 'rateAds';
const USER_MANAGER_BONUS_PER_HOUR = 'managerBonusPerHour';
const USER_MANAGED_COIN_SELECTIONS = 'managedCoinSelections';

const USER_MINING_MAP = 'mining';
const USER_WALLET_MAP = 'wallet';

const EARNINGS_SUBCOLLECTION = 'earnings';
const EARNINGS_REALTIME_DOC = 'realtime';

const USER_COINS_SUBCOLLECTION = 'coins';
const USER_COINS_GLOBAL_COLLECTION = 'user_coins';

// Shared coins aggregation
const SHARED_COINS_COLLECTION = 'shared_coins_pages';
const SHARED_COINS_META_DOC = 'meta';
const SHARED_COINS_META_FIELD_LAST_PAGE = 'lastPageIndex';
const SHARED_COINS_FIELD_PAGE_INDEX = 'pageIndex';
const SHARED_COINS_FIELD_COINS = 'coins';
const SHARED_COINS_FIELD_COUNT = 'count';
const SHARED_COINS_MAX_BYTES = 900000;

// User coin mining fields
const COIN_OWNER_ID = 'ownerId';
const COIN_NAME = 'name';
const COIN_SYMBOL = 'symbol';
const COIN_IMAGE_URL = 'imageUrl';
const COIN_DESCRIPTION = 'description';
const COIN_HOURLY_RATE = 'hourlyRate';
const COIN_TOTAL_POINTS = 'totalPoints';
const COIN_LAST_MINING_START = 'lastMiningStart';
const COIN_LAST_MINING_END = 'lastMiningEnd';
const COIN_LAST_SYNCED_AT = 'lastSyncedAt';
const COIN_SOCIAL_LINKS = 'socialLinks';

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

const ALLOWED_APP_IDS = new Set(['com.eta.network', 'net.etanetwork.app', 'net.etanetwork.app.test']);

const managerIdCache = new Map();
const MANAGER_ID_CACHE_TTL_MS = 10 * 60 * 1000;
const referralShardMetaCache = new Map();
const referralUsernameCache = new Map();

async function upsertReferralInviteeShard(inviterId, inviteeUid, isActive, timestampValue, inviteeUsername) {
  if (!inviterId || !inviteeUid) {
    return;
  }
  const referralAggCollection = db.collection(REFERRALS_COLLECTION);
  const referralShardsMetaCollection = db.collection(REFERRAL_SHARDS_COLLECTION);

  let meta = referralShardMetaCache.get(inviterId);
  if (!meta) {
    const shardMetaRef = referralShardsMetaCollection.doc(inviterId);
    const shardMetaSnap = await shardMetaRef.get();
    const currentShard = shardMetaSnap.exists
      ? (shardMetaSnap.data().currentShard || 0)
      : 0;
    meta = { currentShard };
    referralShardMetaCache.set(inviterId, meta);
  }

  const shardMetaRef = referralShardsMetaCollection.doc(inviterId);
  const { currentShard } = meta;
  const aggDocId = currentShard === 0
    ? inviterId
    : `${inviterId}_shard_${currentShard}`;

  const newAggRef = referralAggCollection.doc(aggDocId);
  const timestampField = timestampValue || admin.firestore.FieldValue.serverTimestamp();
  const usernameField = typeof inviteeUsername === "string"
    ? inviteeUsername
    : null;
  await newAggRef.set(
    {
      invitees: {
        [inviteeUid]: {
          isActive: !!isActive,
          timestamp: timestampField,
          [REFERRAL_INVITEE_USERNAME]: usernameField,
        },
      },
    },
    { merge: true },
  );

  const newAggSnap = await newAggRef.get();
  if (!newAggSnap.exists) {
    return;
  }
  const data = newAggSnap.data() || {};
  const approxBytes = Buffer.byteLength(JSON.stringify(data));
  if (approxBytes <= 800000) {
    return;
  }

  console.warn('upsertReferralInviteeShard: referral aggregate near 1MB', {
    inviterId,
    approxBytes,
  });
  try {
    await db.collection(REFERRAL_ALERTS_COLLECTION).add({
      inviterId,
      sizeBytes: approxBytes,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.log('upsertReferralInviteeShard: failed to write referral_alerts', {
      inviterId,
      error: e && e.message,
    });
  }

  const nextShardIndex = meta.currentShard + 1;
  meta.currentShard = nextShardIndex;
  referralShardMetaCache.set(inviterId, meta);
  await shardMetaRef.set(
    { currentShard: nextShardIndex },
    { merge: true },
  );
}

function toNumber(value, defaultValue = 0) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim() !== "") {
    const n = Number(value);
    if (Number.isFinite(n)) return n;
  }
  return defaultValue;
}

function buildUserEarningsMigrationPlan({ uid, userData, realtimeData, subCoinsDocs, globalCoinsDocs }) {
  const miningMap = (userData && userData[USER_MINING_MAP]) || {};
  const walletMap = (userData && userData[USER_WALLET_MAP]) || {};

  const pickFromRealtimeOrUser = (field) => {
    if (realtimeData && Object.prototype.hasOwnProperty.call(realtimeData, field)) {
      return realtimeData[field];
    }
    if (userData && Object.prototype.hasOwnProperty.call(userData, field)) {
      return userData[field];
    }
    return undefined;
  };

  const hasRealtimeTotal =
    realtimeData && Object.prototype.hasOwnProperty.call(realtimeData, USER_TOTAL_POINTS);
  const finalTotalPoints = hasRealtimeTotal
    ? toNumber(realtimeData[USER_TOTAL_POINTS])
    : toNumber(userData && userData[USER_TOTAL_POINTS]);

  const pickRateField = (field) => {
    if (realtimeData && Object.prototype.hasOwnProperty.call(realtimeData, field)) {
      return realtimeData[field];
    }
    if (userData && Object.prototype.hasOwnProperty.call(userData, field)) {
      return userData[field];
    }
    if (miningMap && Object.prototype.hasOwnProperty.call(miningMap, field)) {
      return miningMap[field];
    }
    return undefined;
  };

  const coinsMap = {};

  const mergeCoinData = (existing, incoming) => {
    if (!existing || typeof existing !== "object") {
      return { ...incoming };
    }
    const merged = { ...existing, ...incoming };
    const existingTotal = toNumber(existing[COIN_TOTAL_POINTS], 0);
    const incomingTotal = toNumber(incoming[COIN_TOTAL_POINTS], 0);
    const sumTotal = existingTotal + incomingTotal;
    if (sumTotal !== 0) {
      merged[COIN_TOTAL_POINTS] = sumTotal;
    }
    return merged;
  };

  const collectCoins = (docs) => {
    if (!docs || !Array.isArray(docs)) return;
    for (const doc of docs) {
      const id = doc.id;
      if (!id) continue;
      const data = doc.data || {};
      const existing = coinsMap[id] || {};
      coinsMap[id] = mergeCoinData(existing, data);
    }
  };

  collectCoins(subCoinsDocs);
  collectCoins(globalCoinsDocs);

  const miningFromRealtime = {};
  if (realtimeData && typeof realtimeData === "object") {
    if (Object.prototype.hasOwnProperty.call(realtimeData, USER_LAST_MINING_START)) {
      miningFromRealtime[USER_LAST_MINING_START] = realtimeData[USER_LAST_MINING_START];
    }
    if (Object.prototype.hasOwnProperty.call(realtimeData, USER_LAST_MINING_END)) {
      miningFromRealtime[USER_LAST_MINING_END] = realtimeData[USER_LAST_MINING_END];
    }
    if (Object.prototype.hasOwnProperty.call(realtimeData, USER_LAST_SYNCED_AT)) {
      miningFromRealtime[USER_LAST_SYNCED_AT] = realtimeData[USER_LAST_SYNCED_AT];
    }
    if (Object.prototype.hasOwnProperty.call(realtimeData, USER_HOURLY_RATE)) {
      miningFromRealtime[USER_HOURLY_RATE] = realtimeData[USER_HOURLY_RATE];
    }
  }

  const newMiningMap = {
    ...miningMap,
    ...miningFromRealtime,
  };

  const rateFieldsInMining = [
    USER_RATE_BASE,
    USER_RATE_STREAK,
    USER_RATE_RANK,
    USER_RATE_REFERRAL,
    USER_RATE_MANAGER,
    USER_RATE_ADS,
    USER_MANAGER_BONUS_PER_HOUR,
  ];

  rateFieldsInMining.forEach((field) => {
    if (Object.prototype.hasOwnProperty.call(newMiningMap, field)) {
      delete newMiningMap[field];
    }
  });

  const existingWalletCoins =
    walletMap && typeof walletMap === "object" && walletMap.coins && typeof walletMap.coins === "object"
      ? walletMap.coins
      : {};

  const mergedCoins = {
    ...existingWalletCoins,
    ...coinsMap,
  };

  const newUserDoc = {
    [USER_TOTAL_POINTS]: finalTotalPoints,
    [USER_MIGRATION_FLAG]: true,
    [USER_MINING_MAP]: newMiningMap,
  };

  const walletWithoutCoins =
    walletMap && typeof walletMap === "object"
      ? Object.fromEntries(Object.entries(walletMap).filter(([key]) => key !== "coins"))
      : {};

  if (Object.keys(walletWithoutCoins).length > 0) {
    newUserDoc[USER_WALLET_MAP] = walletWithoutCoins;
  }

  Object.entries(mergedCoins).forEach(([coinId, coinData]) => {
    if (!coinId) {
      return;
    }
    newUserDoc[`${USER_WALLET_MAP}.coins.${coinId}`] = coinData;
  });

  const hourlyRateValue = newMiningMap[USER_HOURLY_RATE];
  if (hourlyRateValue !== undefined) {
    newUserDoc[USER_HOURLY_RATE] = hourlyRateValue;
  }
  const lastStartValue = newMiningMap[USER_LAST_MINING_START];
  if (lastStartValue !== undefined) {
    newUserDoc[USER_LAST_MINING_START] = lastStartValue;
  }
  const lastEndValue = newMiningMap[USER_LAST_MINING_END];
  if (lastEndValue !== undefined) {
    newUserDoc[USER_LAST_MINING_END] = lastEndValue;
  }
  const lastSyncedValue = newMiningMap[USER_LAST_SYNCED_AT];
  if (lastSyncedValue !== undefined) {
    newUserDoc[USER_LAST_SYNCED_AT] = lastSyncedValue;
  }

  const rateBase = pickRateField(USER_RATE_BASE);
  if (rateBase !== undefined) {
    newUserDoc[USER_RATE_BASE] = rateBase;
  }
  const rateStreak = pickRateField(USER_RATE_STREAK);
  if (rateStreak !== undefined) {
    newUserDoc[USER_RATE_STREAK] = rateStreak;
  }
  const rateRank = pickRateField(USER_RATE_RANK);
  if (rateRank !== undefined) {
    newUserDoc[USER_RATE_RANK] = rateRank;
  }
  const rateReferral = pickRateField(USER_RATE_REFERRAL);
  if (rateReferral !== undefined) {
    newUserDoc[USER_RATE_REFERRAL] = rateReferral;
  }
  const rateManager = pickRateField(USER_RATE_MANAGER);
  if (rateManager !== undefined) {
    newUserDoc[USER_RATE_MANAGER] = rateManager;
  }

  const userHasRootRateAds =
    userData && Object.prototype.hasOwnProperty.call(userData, USER_RATE_ADS);
  if (!userHasRootRateAds) {
    const rateAds = pickRateField(USER_RATE_ADS);
    if (rateAds !== undefined) {
      newUserDoc[USER_RATE_ADS] = rateAds;
    }
  }

  const managerBonusPerHour = pickRateField(USER_MANAGER_BONUS_PER_HOUR);
  if (managerBonusPerHour !== undefined) {
    newUserDoc[USER_MANAGER_BONUS_PER_HOUR] = managerBonusPerHour;
  }
  const managedCoinSelections = pickFromRealtimeOrUser(USER_MANAGED_COIN_SELECTIONS);
  if (managedCoinSelections !== undefined) {
    newUserDoc[USER_MANAGED_COIN_SELECTIONS] = managedCoinSelections;
  }

  const newRealtimeDoc = {
    ...realtimeData,
    [USER_TOTAL_POINTS]: finalTotalPoints,
    coins: coinsMap,
  };

  return {
    newUserDoc,
    newRealtimeDoc,
    finalTotalPoints,
  };
}

exports._test_buildUserEarningsMigrationPlan = buildUserEarningsMigrationPlan;

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

exports.backfillMigrationUnifiedEarnings = onSchedule("0 3 * * *", async () => {
  const pageSize = 1000;
  const maxBatchWrites = 500;
  let lastDoc = null;
  let processed = 0;
  let updated = 0;
  let failed = 0;
  let page = 0;

  for (;;) {
    let query = db.collection(USERS_COLLECTION).orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snap = await query.get();
    if (snap.empty) {
      console.log(JSON.stringify({ op: "backfillMigrationUnifiedEarnings", level: "info", message: "completed", processed, updated, failed }));
      break;
    }

    page += 1;
    processed += snap.size;
    lastDoc = snap.docs[snap.docs.length - 1];

    const targets = [];
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      if (!Object.prototype.hasOwnProperty.call(data, USER_MIGRATION_FLAG)) {
        targets.push(doc.ref);
      }
    }

    for (let i = 0; i < targets.length; i += maxBatchWrites) {
      const slice = targets.slice(i, i + maxBatchWrites);
      if (!slice.length) continue;
      let attempts = 0;
      for (;;) {
        attempts += 1;
        const batch = db.batch();
        for (const ref of slice) {
          batch.update(ref, { [USER_MIGRATION_FLAG]: false });
        }
        try {
          await batch.commit();
          updated += slice.length;
          console.log(JSON.stringify({ op: "backfillMigrationUnifiedEarnings", level: "info", page, batchSize: slice.length, updatedSoFar: updated }));
          break;
        } catch (e) {
          console.error("backfillMigrationUnifiedEarnings batch error", e);
          if (attempts >= 3) {
            failed += slice.length;
            console.error(JSON.stringify({ op: "backfillMigrationUnifiedEarnings", level: "error", page, failedBatchSize: slice.length }));
            break;
          }
          await new Promise((resolve) => setTimeout(resolve, 1000 * attempts));
        }
      }
    }
  }
});

async function upsertSharedUserCoinPage(uid, coinData) {
  const metaRef = db.collection(SHARED_COINS_COLLECTION).doc(SHARED_COINS_META_DOC);
  const metaSnap = await metaRef.get();
  let lastPageIndex = 1;
  if (metaSnap.exists) {
    const d = metaSnap.data() || {};
    const v = d[SHARED_COINS_META_FIELD_LAST_PAGE];
    if (typeof v === "number" && Number.isInteger(v) && v > 0) {
      lastPageIndex = v;
    }
  }

  let pageIndex = lastPageIndex;

  while (true) {
    const pageId = String(pageIndex).padStart(5, "0");
    const pageRef = db.collection(SHARED_COINS_COLLECTION).doc(pageId);
    const pageSnap = await pageRef.get();
    const pageData = pageSnap.exists ? (pageSnap.data() || {}) : {};
    const coinsMap = pageData[SHARED_COINS_FIELD_COINS] || {};
    coinsMap[uid] = coinData;

    const newPageData = {
      [SHARED_COINS_FIELD_PAGE_INDEX]: pageIndex,
      [SHARED_COINS_FIELD_COINS]: coinsMap,
      [SHARED_COINS_FIELD_COUNT]: Object.keys(coinsMap).length,
    };

    const approxBytes = Buffer.byteLength(JSON.stringify(newPageData));
    if (approxBytes <= SHARED_COINS_MAX_BYTES || pageIndex !== lastPageIndex) {
      await pageRef.set(newPageData, { merge: false });
      if (pageIndex !== lastPageIndex) {
        await metaRef.set(
          { [SHARED_COINS_META_FIELD_LAST_PAGE]: pageIndex },
          { merge: true },
        );
      }
      break;
    }

    pageIndex += 1;
  }
}

async function deleteSharedUserCoin(uid) {
  const metaRef = db.collection(SHARED_COINS_COLLECTION).doc(SHARED_COINS_META_DOC);
  const metaSnap = await metaRef.get();
  if (!metaSnap.exists) {
    return;
  }
  const metaData = metaSnap.data() || {};
  const v = metaData[SHARED_COINS_META_FIELD_LAST_PAGE];
  let lastPageIndex = 1;
  if (typeof v === "number" && Number.isInteger(v) && v > 0) {
    lastPageIndex = v;
  }

  for (let pageIndex = 1; pageIndex <= lastPageIndex; pageIndex++) {
    const pageId = String(pageIndex).padStart(5, "0");
    const pageRef = db.collection(SHARED_COINS_COLLECTION).doc(pageId);
    const pageSnap = await pageRef.get();
    if (!pageSnap.exists) continue;
    const pageData = pageSnap.data() || {};
    const coinsMap = pageData[SHARED_COINS_FIELD_COINS] || {};
    if (!Object.prototype.hasOwnProperty.call(coinsMap, uid)) continue;

    delete coinsMap[uid];
    const newPageData = {
      [SHARED_COINS_FIELD_PAGE_INDEX]: pageIndex,
      [SHARED_COINS_FIELD_COINS]: coinsMap,
      [SHARED_COINS_FIELD_COUNT]: Object.keys(coinsMap).length,
    };
    await pageRef.set(newPageData, { merge: false });
  }
}

exports.onUserCoinWrite = onDocumentWritten(
  {
    document: `${USERS_COLLECTION}/{uid}/${USER_COINS_SUBCOLLECTION}/${USER_COINS_SUBCOLLECTION}`,
    region: REGION,
  },
  async (event) => {
    const uid = event.params.uid;
    const after = event.data.after;
    const before = event.data.before;

    if (after && after.exists) {
      const data = after.data() || {};
      await upsertSharedUserCoinPage(uid, data);
      return;
    }

    if (before && before.exists && (!after || !after.exists)) {
      await deleteSharedUserCoin(uid);
    }
  },
);

exports.backfillSharedUserCoins = onSchedule(
  {
    schedule: "0 1 * * *",
    region: REGION,
  },
  async () => {
    const pageSize = 200;
    let lastUserDoc = null;
    let processedUsers = 0;
    let updatedCoins = 0;

    for (;;) {
      let query = db
        .collection(USERS_COLLECTION)
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(pageSize);

      if (lastUserDoc) {
        query = query.startAfter(lastUserDoc);
      }

      const userSnap = await query.get();
      if (userSnap.empty) {
        break;
      }

      lastUserDoc = userSnap.docs[userSnap.docs.length - 1];
      processedUsers += userSnap.size;

      const coinDocSnaps = await Promise.all(
        userSnap.docs.map((d) =>
          d.ref
            .collection(USER_COINS_SUBCOLLECTION)
            .doc(USER_COINS_SUBCOLLECTION)
            .get(),
        ),
      );

      for (let i = 0; i < userSnap.docs.length; i++) {
        const uid = userSnap.docs[i].id;
        const coinDoc = coinDocSnaps[i];
        if (!coinDoc.exists) {
          continue;
        }
        const data = coinDoc.data() || {};
        if (
          !Object.prototype.hasOwnProperty.call(data, COIN_OWNER_ID) ||
          typeof data[COIN_OWNER_ID] !== "string" ||
          data[COIN_OWNER_ID].trim() === ""
        ) {
          data[COIN_OWNER_ID] = uid;
        }
        await upsertSharedUserCoinPage(uid, data);
        updatedCoins += 1;
      }
    }

    console.log(
      JSON.stringify({
        op: "backfillSharedUserCoins",
        processedUsers,
        updatedCoins,
      }),
    );
  },
);

exports.migrateUserCoinsToUserSubdoc = onSchedule(
  {
    schedule: "0 2 * * *",
    region: REGION,
  },
  async () => {
    const pageSize = 200;
    let totalMigrated = 0;
    let lastDoc = null;

    for (;;) {
      let query = db
        .collection(USER_COINS_GLOBAL_COLLECTION)
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(pageSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snap = await query.get();

      if (snap.empty) {
        break;
      }

      lastDoc = snap.docs[snap.docs.length - 1];

      const batch = db.batch();
      let migratedInBatch = 0;

      for (const doc of snap.docs) {
        const data = doc.data() || {};
        let uid = doc.id;
        if (
          Object.prototype.hasOwnProperty.call(data, COIN_OWNER_ID) &&
          typeof data[COIN_OWNER_ID] === "string" &&
          data[COIN_OWNER_ID].trim() !== ""
        ) {
          uid = data[COIN_OWNER_ID].trim();
        }

        const userSnap = await db.collection(USERS_COLLECTION).doc(uid).get();
        if (!userSnap.exists) {
          continue;
        }

        const userCoinRef = db
          .collection(USERS_COLLECTION)
          .doc(uid)
          .collection(USER_COINS_SUBCOLLECTION)
          .doc(USER_COINS_SUBCOLLECTION);
        batch.set(userCoinRef, data, { merge: false });
        migratedInBatch += 1;
      }

      if (migratedInBatch > 0) {
        await batch.commit();
        totalMigrated += migratedInBatch;
      }
    }

    console.log(
      "migrateUserCoinsToUserSubdoc: migrated total",
      totalMigrated,
    );
  },
);

exports.migrateReferralStatsAndReferrals = onSchedule("0 4 * * *", async () => {
  const pageSize = 500;

  // Step 1: Migrate referral_stats -> users.totalInvited and delete referral_stats docs
  let lastStatsDoc = null;
  for (;;) {
    let statsQuery = db
      .collection(REFERRAL_STATS_COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (lastStatsDoc) {
      statsQuery = statsQuery.startAfter(lastStatsDoc);
    }

    const statsSnap = await statsQuery.get();
    if (statsSnap.empty) {
      break;
    }
    lastStatsDoc = statsSnap.docs[statsSnap.docs.length - 1];

    const batch = db.batch();
    for (const doc of statsSnap.docs) {
      const uid = doc.id;
      const data = doc.data() || {};
      const totalInvitedValue = typeof data[USER_TOTAL_INVITED] === "number"
        ? data[USER_TOTAL_INVITED]
        : typeof data.totalInvited === "number"
          ? data.totalInvited
          : 0;
      const userRef = db.collection(USERS_COLLECTION).doc(uid);
      batch.set(
        userRef,
        { [USER_TOTAL_INVITED]: totalInvitedValue },
        { merge: true },
      );
      batch.delete(doc.ref);
    }
    await batch.commit();
  }

  // Step 2: Migrate legacy referrals docs into sharded aggregator docs and delete legacy docs
  let lastReferralDoc = null;
  const usernameCache = new Map();
  for (;;) {
    let refQuery = db
      .collection(REFERRALS_COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (lastReferralDoc) {
      refQuery = refQuery.startAfter(lastReferralDoc);
    }

    const refSnap = await refQuery.get();
    if (refSnap.empty) {
      break;
    }
    lastReferralDoc = refSnap.docs[refSnap.docs.length - 1];

    for (const doc of refSnap.docs) {
      const data = doc.data() || {};
      const inviterId = (data[REFERRAL_INVITER_ID] || "").toString().trim();
      const inviteeId = (data[REFERRAL_INVITEE_ID] || "").toString().trim();

      // Skip docs that are not legacy referral entries (e.g., aggregator shards)
      if (!inviterId || !inviteeId) {
        continue;
      }

      const isActive = !!data[REFERRAL_IS_ACTIVE];
      const ts = data[REFERRAL_TIMESTAMP] || null;

      let inviteeUsername = "";
      if (usernameCache.has(inviteeId)) {
        inviteeUsername = usernameCache.get(inviteeId);
      } else {
        try {
          const userSnap = await db.collection(USERS_COLLECTION).doc(inviteeId).get();
          if (userSnap.exists) {
            const userData = userSnap.data() || {};
            inviteeUsername = (userData[USER_USERNAME] || "").toString().trim();
          }
        } catch (e) {
          inviteeUsername = "";
        }
        if (!inviteeUsername) {
          inviteeUsername = (data[REFERRAL_INVITEE_USERNAME] || "").toString().trim();
        }
        usernameCache.set(inviteeId, inviteeUsername);
      }

      await upsertReferralInviteeShard(inviterId, inviteeId, isActive, ts, inviteeUsername);
      await doc.ref.delete();
    }
  }
});

async function migrateUserEarningsCore(uid) {
  const userRef = db.collection(USERS_COLLECTION).doc(uid);
  const realtimeRef = userRef
    .collection(EARNINGS_SUBCOLLECTION)
    .doc(EARNINGS_REALTIME_DOC);
  const subCoinsQuery = userRef.collection(USER_COINS_SUBCOLLECTION);
  const globalCoinsQuery = db
    .collection(USER_COINS_GLOBAL_COLLECTION)
    .where(COIN_OWNER_ID, "==", uid);

  const result = await db.runTransaction(async (tx) => {
    const [userSnap, realtimeSnap, subCoinsSnap, globalCoinsSnap] =
      await Promise.all([
        tx.get(userRef),
        tx.get(realtimeRef),
        tx.get(subCoinsQuery),
        tx.get(globalCoinsQuery),
      ]);

    if (!userSnap.exists) {
      throw new Error(`User ${uid} not found`);
    }

    const userData = userSnap.data() || {};

    if (userData[USER_MIGRATION_FLAG] === true) {
      return {
        alreadyMigrated: true,
        migrationStatus: {
          userDocExists: true,
          flagPresent: true,
        },
      };
    }

    const realtimeData = realtimeSnap.exists ? (realtimeSnap.data() || {}) : {};

    const subCoinsDocs = subCoinsSnap.docs.map((d) => ({
      id: d.id,
      data: d.data(),
    }));

    const globalCoinsDocs = globalCoinsSnap.docs.map((d) => ({
      id: d.id,
      data: d.data(),
    }));

    try {
      const plan = buildUserEarningsMigrationPlan({
        uid,
        userData,
        realtimeData,
        subCoinsDocs,
        globalCoinsDocs,
      });

      tx.set(userRef, plan.newUserDoc, { merge: true });
      tx.set(realtimeRef, plan.newRealtimeDoc, { merge: true });

      return {
        alreadyMigrated: false,
        finalTotalPoints: plan.finalTotalPoints,
        migrationStatus: {
          userDocExists: true,
          realtimeDocExists: realtimeSnap.exists,
          subCoinsCount: subCoinsSnap.size,
          globalCoinsCount: globalCoinsSnap.size,
        },
      };
    } catch (e) {
      console.error("migrateUserEarnings transaction inner error", e);
      throw e;
    }
  });

  return result;
}

exports.migrateUserEarnings = onSchedule("0 3 * * *", async () => {
  const pageSize = 200;
  let processed = 0;
  let migrated = 0;
  let already = 0;
  let lastDoc = null;

  for (;;) {
    let query = db.collection(USERS_COLLECTION)
      .where(USER_MIGRATION_FLAG, "==", false)
      .limit(pageSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snap = await query.get();
    if (snap.empty) {
      break;
    }

    processed += snap.size;
    lastDoc = snap.docs[snap.docs.length - 1];

    for (const doc of snap.docs) {
      const uid = doc.id;
      try {
        const startMs = Date.now();
        const result = await migrateUserEarningsCore(uid);
        const durationMs = Date.now() - startMs;
        if (result.alreadyMigrated) {
          already += 1;
        } else {
          migrated += 1;
        }
        console.log(JSON.stringify({
          op: "migrateUserEarnings",
          uid,
          durationMs,
          alreadyMigrated: result.alreadyMigrated,
          migrationStatus: result.migrationStatus || null,
        }));
      } catch (e) {
        console.error("migrateUserEarnings scheduled error", e);
      }
    }
  }

  console.log(JSON.stringify({
    op: "migrateUserEarningsSummary",
    processed,
    migrated,
    alreadyMigrated: already,
  }));
});

exports.cleanupMigratedEarningsEarningsDocs = onSchedule("0 4 * * *", async () => {
  const pageSize = 200;
  let processed = 0;
  let deleted = 0;
  let missing = 0;
  let lastDoc = null;

  for (;;) {
    let query = db.collection(USERS_COLLECTION)
      .where(USER_MIGRATION_FLAG, "==", true)
      .limit(pageSize);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snap = await query.get();
    if (snap.empty) {
      break;
    }

    processed += snap.size;
    lastDoc = snap.docs[snap.docs.length - 1];

    for (const doc of snap.docs) {
      const uid = doc.id;
      try {
        const realtimeRef = doc.ref
          .collection(EARNINGS_SUBCOLLECTION)
          .doc(EARNINGS_REALTIME_DOC);
        const realtimeSnap = await realtimeRef.get();

        if (realtimeSnap.exists) {
          await realtimeRef.delete();
          deleted += 1;
          console.log(JSON.stringify({
            op: "cleanupEarningsDoc",
            uid,
            deleted: true,
          }));
        } else {
          missing += 1;
          console.log(JSON.stringify({
            op: "cleanupEarningsDoc",
            uid,
            deleted: false,
            reason: "missing",
          }));
        }
      } catch (e) {
        console.error("cleanupEarningsDoc error", e);
      }
    }
  }

  console.log(JSON.stringify({
    op: "cleanupEarningsDocSummary",
    processed,
    deleted,
    missing,
  }));
});

async function applyBonus24ToUser(uid) {
  const userRef = db.collection(USERS_COLLECTION).doc(uid);
  const nowTs = admin.firestore.Timestamp.now();

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) {
      return { ok: false, reason: "user_missing" };
    }
    const data = snap.data() || {};

    if (data[USER_BONUS_24_APPLIED] === true) {
      return { ok: true, skipped: "already_applied" };
    }

    const lastStart = data[USER_LAST_MINING_START];
    const lastEnd = data[USER_LAST_MINING_END];

    let miningActive = false;
    if (lastStart && typeof lastStart.toDate === "function") {
      const startDate = lastStart.toDate();
      const nowDate = nowTs.toDate();
      if (!lastEnd || typeof lastEnd.toDate !== "function") {
        if (nowDate >= startDate) {
          miningActive = true;
        }
      } else {
        const endDate = lastEnd.toDate();
        if (nowDate >= startDate && nowDate <= endDate) {
          miningActive = true;
        }
      }
    }

    if (miningActive) {
      return { ok: true, skipped: "mining_active" };
    }

    const currentTotal = toNumber(data[USER_TOTAL_POINTS]);
    const newTotal = currentTotal + 48;

    tx.set(
      userRef,
      {
        [USER_TOTAL_POINTS]: newTotal,
        [USER_BONUS_24_APPLIED]: true,
      },
      { merge: true },
    );

    return {
      ok: true,
      granted: true,
      previousTotal: currentTotal,
      newTotal,
    };
  });

  return result;
}

exports.applyOneTimeBonus24 = onSchedule("0 5 * * *", async () => {
  const pageSize = 200;
  let processed = 0;
  let granted = 0;
  let skippedAlready = 0;
  let skippedMining = 0;
  let errors = 0;
  let lastDoc = null;

  for (;;) {
    let query = db
      .collection(USERS_COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snap = await query.get();
    if (snap.empty) {
      break;
    }
    lastDoc = snap.docs[snap.docs.length - 1];
    processed += snap.size;

    for (const doc of snap.docs) {
      const uid = doc.id;
      try {
        const res = await applyBonus24ToUser(uid);
        if (!res || res.ok !== true) {
          errors += 1;
          console.error(
            "applyOneTimeBonus24 error state",
            uid,
            JSON.stringify(res || {}),
          );
          continue;
        }
        if (res.granted) {
          granted += 1;
        } else if (res.skipped === "already_applied") {
          skippedAlready += 1;
        } else if (res.skipped === "mining_active") {
          skippedMining += 1;
        }
      } catch (e) {
        errors += 1;
        console.error("applyOneTimeBonus24 error", uid, e);
      }
    }
  }

  console.log(
    JSON.stringify({
      op: "applyOneTimeBonus24Summary",
      processed,
      granted,
      skippedAlready,
      skippedMining,
      errors,
    }),
  );
});

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

// In-memory cache of last processed mining end timestamp per uid (per function instance).
const lastMiningEndCache = new Map();

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

    const uid = event.params.uid;
    console.log("scheduleMiningEndNotification: invoked", {
      uid,
      hasBefore: beforeSnap.exists,
      hasAfter: afterSnap.exists,
    });

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
      const endMsCurrent = afterEndTs.toMillis();
      const scheduledEndMs = Number(afterData[USER_MINING_END_TASK_SCHEDULED_END_MS] || 0);
      if (Number.isFinite(scheduledEndMs) && scheduledEndMs === endMsCurrent) {
        lastMiningEndCache.set(uid, endMsCurrent);
        console.log("scheduleMiningEndNotification: skip (same endTs and already scheduled)", {
          uid,
          endMs: endMsCurrent,
        });
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

    const cachedEndMs = lastMiningEndCache.get(uid);
    if (Number.isFinite(cachedEndMs) && cachedEndMs === endMs) {
      console.log("scheduleMiningEndNotification: skip (in-memory cache hit)", {
        uid,
        endMs,
      });
      return;
    }

    const scheduledEndMs = Number(afterData[USER_MINING_END_TASK_SCHEDULED_END_MS] || 0);
    
    // Idempotency check: if already scheduled for this exact time, skip
    if (Number.isFinite(scheduledEndMs) && scheduledEndMs === endMs) {
      lastMiningEndCache.set(uid, endMs);
      console.log("scheduleMiningEndNotification: skip (scheduledEndMs matches endMs)", {
        uid,
        endMs,
      });
      return;
    }

    const project = process.env.GCLOUD_PROJECT;
    if (!project) throw new Error("GCLOUD_PROJECT is not set");

    const queueName = await ensureQueueExists();
    const url = getFunctionUrl("sendMiningEndNotificationTask");

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
    lastMiningEndCache.set(uid, endMs);
    console.log("scheduleMiningEndNotification: scheduled task and updated cache", {
      uid,
      endMs,
    });
  },
);

const USER_REFERRAL_META_SUBCOLLECTION = 'referral_meta';
const USER_INVITED_BY_META_DOC = 'invitedBy';

exports.updateReferralStatsOnUserWrite = onDocumentWritten(
  `${USERS_COLLECTION}/{uid}/${USER_REFERRAL_META_SUBCOLLECTION}/${USER_INVITED_BY_META_DOC}`,
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;
    if (!afterSnap.exists) {
      return;
    }
    const afterData = afterSnap.data() || {};
    const alreadyApplied = !!afterData.statsApplied;
    if (alreadyApplied) {
      return;
    }

    const inviterRaw = afterData[REFERRAL_INVITER_ID];
    const inviterId = (inviterRaw || "").toString().trim();
    if (!inviterId) {
      return;
    }

    const uid = event.params.uid;
    const userRef = db.collection(USERS_COLLECTION).doc(uid);
    const userSnap = await userRef.get();
    const userData = userSnap.exists ? userSnap.data() || {} : {};
    const inviteeUsername = (userData[USER_USERNAME] || "").toString().trim();

    const newInviterUserRef = db.collection(USERS_COLLECTION).doc(inviterId);
    await newInviterUserRef.set(
      { [USER_TOTAL_INVITED]: admin.firestore.FieldValue.increment(1) },
      { merge: true },
    );
    await userRef.set(
      { [USER_INVITED_BY]: inviterId },
      { merge: true },
    );
    await upsertReferralInviteeShard(inviterId, uid, false, null, inviteeUsername);
    await afterSnap.ref.set({ statsApplied: true }, { merge: true });
  },
);

exports.refreshReferralActiveStatusDaily = onSchedule("0 5 * * *", async () => {
  const pageSize = 200;
  const twoDaysMs = 2 * 24 * 60 * 60 * 1000;
  let lastRefDoc = null;

  for (;;) {
    let refQuery = db
      .collection(REFERRALS_COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (lastRefDoc) {
      refQuery = refQuery.startAfter(lastRefDoc);
    }

    const refSnap = await refQuery.get();
    if (refSnap.empty) {
      break;
    }
    lastRefDoc = refSnap.docs[refSnap.docs.length - 1];

    for (const doc of refSnap.docs) {
      const data = doc.data() || {};
      const invitees = data.invitees;
      if (!invitees || typeof invitees !== "object") {
        continue;
      }

      const updates = {};
      let hasChanges = false;

      for (const [inviteeUid, inviteeData] of Object.entries(invitees)) {
        if (!inviteeUid || !inviteeData || typeof inviteeData !== "object") {
          continue;
        }

        const currentActive = !!inviteeData[REFERRAL_IS_ACTIVE];
        const userRef = db.collection(USERS_COLLECTION).doc(inviteeUid);
        const userSnap = await userRef.get();

        let shouldBeActive = false;
        if (userSnap.exists) {
          const userData = userSnap.data() || {};
          const lastEnd = userData[USER_LAST_MINING_END];
          if (lastEnd && typeof lastEnd.toMillis === "function") {
            const lastEndMs = lastEnd.toMillis();
            const nowMs = Date.now();
            if (nowMs - lastEndMs <= twoDaysMs) {
              shouldBeActive = true;
            }
          }
        }

        if (shouldBeActive !== currentActive) {
          updates[`invitees.${inviteeUid}.${REFERRAL_IS_ACTIVE}`] = shouldBeActive;
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await doc.ref.update(updates);
      }
    }
  }
});

exports.backfillInvitedByReferralMeta = onSchedule("30 5 * * *", async () => {
  const pageSize = 500;
  let lastUserDoc = null;

  for (;;) {
    let userQuery = db
      .collection(USERS_COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (lastUserDoc) {
      userQuery = userQuery.startAfter(lastUserDoc);
    }

    const userSnap = await userQuery.get();
    if (userSnap.empty) {
      break;
    }
    lastUserDoc = userSnap.docs[userSnap.docs.length - 1];

    for (const userDoc of userSnap.docs) {
      const uid = userDoc.id;
      const data = userDoc.data() || {};
      const inviterRaw = data[USER_INVITED_BY];
      const inviterId = (inviterRaw || "").toString().trim();
      if (!inviterId) {
        continue;
      }

      const metaRef = db
        .collection(USERS_COLLECTION)
        .doc(uid)
        .collection(USER_REFERRAL_META_SUBCOLLECTION)
        .doc(USER_INVITED_BY_META_DOC);
      const metaSnap = await metaRef.get();
      if (metaSnap.exists) {
        continue;
      }

      await metaRef.set({
        [REFERRAL_INVITER_ID]: inviterId,
        statsApplied: true,
        source: "migration",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
});
