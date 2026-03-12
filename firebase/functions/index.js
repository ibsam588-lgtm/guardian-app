// firebase/functions/index.js
// Deploy: firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─────────────────────────────────────────────
//  Trigger: new time request created by child
//  → send push notification to parent
// ─────────────────────────────────────────────
exports.onTimeRequestCreated = functions.firestore
  .document('time_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { parentUid, childName, appName, requestedMinutes, childNote } = data;

    // Get parent's FCM token
    const parentDoc = await db.collection('parents').doc(parentUid).get();
    const fcmToken = parentDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    // Build notification
    const title = `${childName} wants more time`;
    const body = childNote
      ? `${requestedMinutes} more min on ${appName}: "${childNote}"`
      : `Requesting ${requestedMinutes} more minutes on ${appName}`;

    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      android: {
        priority: 'high',
        notification: {
          channelId: 'time_requests',
          sound: 'default',
          priority: 'max',
          visibility: 'public',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1,
            'content-available': 1,
          },
        },
      },
      data: {
        type: 'time_request',
        requestId: context.params.requestId,
        childName,
        appName,
        requestedMinutes: String(requestedMinutes),
      },
    });

    return null;
  });

// ─────────────────────────────────────────────
//  Trigger: request approved → notify child
// ─────────────────────────────────────────────
exports.onTimeRequestResponded = functions.firestore
  .document('time_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only fire when status changes from pending
    if (before.status !== 'pending' || after.status === 'pending') return null;

    const { childId, appName, status, grantedMinutes } = after;

    // Get child device FCM token
    const childDoc = await db.collection('children').doc(childId).get();
    const fcmToken = childDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    const approved = status === 'approved';
    const title = approved
      ? `You got ${grantedMinutes} more minutes! 🎉`
      : `Request denied`;
    const body = approved
      ? `Your parent approved extra time on ${appName}. Enjoy!`
      : `Sorry, your parent said no more time on ${appName} today.`;

    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      android: { priority: 'high' },
      data: {
        type: 'time_request_response',
        status,
        appName,
        grantedMinutes: String(grantedMinutes ?? 0),
      },
    });

    return null;
  });

// ─────────────────────────────────────────────
//  Scheduled: auto-expire pending requests after 10 min
// ─────────────────────────────────────────────
exports.expireTimeRequests = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const expired = await db.collection('time_requests')
      .where('status', '==', 'pending')
      .where('expiresAt', '<=', now)
      .get();

    const batch = db.batch();
    expired.docs.forEach(doc => {
      batch.update(doc.ref, { status: 'expired' });
    });

    await batch.commit();
    console.log(`Expired ${expired.size} time requests`);
    return null;
  });

// ─────────────────────────────────────────────
//  RevenueCat webhook: update subscription status
// ─────────────────────────────────────────────
exports.revenuecatWebhook = functions.https.onRequest(async (req, res) => {
  const event = req.body;
  const uid = event.app_user_id;
  const type = event.type;

  const statusMap = {
    'INITIAL_PURCHASE': 'active',
    'RENEWAL': 'active',
    'PRODUCT_CHANGE': 'active',
    'CANCELLATION': 'cancelled',
    'EXPIRATION': 'expired',
    'BILLING_ISSUE': 'billing_issue',
  };

  const status = statusMap[type] || 'unknown';

  await db.collection('parents').doc(uid).update({
    subscription: status,
    subscriptionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Updated subscription for ${uid}: ${status}`);
  res.status(200).send('ok');
});
