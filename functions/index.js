const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Set global options (e.g., region)
setGlobalOptions({ region: "us-central1" });

// Firestore Constants (matching client-side)
const USERS_COLLECTION = 'users';
const MANAGERS_COLLECTION = 'managers';
const APP_CONFIG_COLLECTION = 'app_config';
const SUBSCRIPTION_FIELD = 'subscription';

// Subscription Fields
const SUB_STATUS = 'status';
const SUB_PLAN_ID = 'planId';
const SUB_PROVIDER = 'provider';
const SUB_EXPIRES_AT = 'expiresAt';
const SUB_AUTO_RENEW = 'autoRenew';

// User Fields
const USER_MANAGER_ENABLED = 'managerEnabled';
const USER_ACTIVE_MANAGER_ID = 'activeManagerId';

exports.handleRevenueCatWebhook = onRequest(async (req, res) => {
  try {
    const event = req.body && req.body.event;
    if (!event) {
      console.error('No event found in body');
      res.status(400).send('No event found');
      return;
    }

    const { type, app_user_id, product_id, expiration_at_ms, store, entitlement_id } = event;

    if (!app_user_id) {
      console.log('No app_user_id, skipping');
      res.status(200).send('OK');
      return;
    }

    console.log(`Received event: ${type} for user: ${app_user_id}`);

    const userRef = db.collection(USERS_COLLECTION).doc(app_user_id);
    
    // We only care about events that change status/expiration
    // INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, PRODUCT_CHANGE

    let status = 'active';
    let expiresAt = null;
    let autoRenew = true;

    if (expiration_at_ms) {
      expiresAt = admin.firestore.Timestamp.fromMillis(expiration_at_ms);
    }

    if (type === 'EXPIRATION') {
      status = 'expired';
      autoRenew = false;
    } else if (type === 'CANCELLATION') {
      // Cancellation means auto-renew is off, but might still be active until expiration
      // RevenueCat sends CANCELLATION when user turns off auto-renew
      // We keep status active if expiration is in future (logic handled below/in app)
      // But for simplicity, we just flag autoRenew = false. Status remains active until actual expiry.
      // However, if we don't have the current status, we might assume active if not expired.
      autoRenew = false;
    } else if (type === 'Uncancellation') {
        autoRenew = true;
    }

    // Prepare update data
    const updateData = {
      [`${SUBSCRIPTION_FIELD}.${SUB_STATUS}`]: status,
      [`${SUBSCRIPTION_FIELD}.${SUB_AUTO_RENEW}`]: autoRenew,
      [`${SUBSCRIPTION_FIELD}.${SUB_PROVIDER}`]: store || 'unknown',
    };

    if (product_id) {
       updateData[`${SUBSCRIPTION_FIELD}.${SUB_PLAN_ID}`] = product_id;
    }
    if (expiresAt) {
      updateData[`${SUBSCRIPTION_FIELD}.${SUB_EXPIRES_AT}`] = expiresAt;
    }

    // Special handling for CANCELLATION: if type is CANCELLATION, we don't necessarily set status to 'expired' immediately.
    // The status depends on expiration date.
    // However, if type is EXPIRATION, we explicitly set status to 'expired'.
    
    // For INITIAL_PURCHASE and RENEWAL, status is 'active'.
    if (type === 'INITIAL_PURCHASE' || type === 'RENEWAL' || type === 'PRODUCT_CHANGE') {
        status = 'active';
        updateData[`${SUBSCRIPTION_FIELD}.${SUB_STATUS}`] = status;
    }

    await userRef.update(updateData);

    // If active, ensure manager is linked
    if (status === 'active' && product_id) {
       await syncManagerFromPlan(app_user_id, product_id);
    } else if (status === 'expired') {
        // Disable manager access
        await userRef.update({
            [USER_MANAGER_ENABLED]: false
        });
    }

    res.status(200).send('Processed');
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).send('Internal Server Error');
  }
});

async function syncManagerFromPlan(uid, planId) {
    const managersSnapshot = await db.collection(MANAGERS_COLLECTION)
        .where('storeProductId', '==', planId)
        .limit(1)
        .get();

    if (!managersSnapshot.empty) {
        const managerId = managersSnapshot.docs[0].id;
        await db.collection(USERS_COLLECTION).doc(uid).update({
            [USER_ACTIVE_MANAGER_ID]: managerId,
            [USER_MANAGER_ENABLED]: true
        });
    }
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
            [USER_MANAGER_ENABLED]: false
        });
        count++;
    });

    await batch.commit();
    console.log(`Updated ${count} expired subscriptions.`);
});
