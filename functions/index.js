const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.welcomeNotification = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;

  // 1️⃣ Create in-app notification (Firestore)
  const notifData = {
    title: "Welcome to KitaID!",
    body:
      "Thanks for creating your account. Your profile is ready, but your cards and documents will be uploaded within 24 hours.",
    category: "system",
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await admin.firestore()
    .collection("Users")
    .doc(uid)
    .collection("notifications")
    .add(notifData);

  // 2️⃣ Send push notification popup (FCM)
  const userDoc = await admin.firestore().collection("Users").doc(uid).get();
  const fcmToken = userDoc.data()?.fcmToken;

  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: notifData.title,
        body: notifData.body,
      },
      android: {
        priority: "high",
      },
    });
  }

  return null;
});
