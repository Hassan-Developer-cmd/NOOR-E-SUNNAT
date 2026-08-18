const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Callable Cloud Function: updateUserPasswordWithOtp
 * Verifies the 6-digit OTP token in Firestore and updates the user's password in Firebase Auth using Admin SDK.
 */
exports.updateUserPasswordWithOtp = functions.https.onCall(async (data, context) => {
  const { email, otp, newPassword } = data || {};

  if (!email || !otp || !newPassword) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields: email, otp, or newPassword."
    );
  }

  const cleanEmail = email.toLowerCase().trim();

  if (newPassword.length < 6) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters long."
    );
  }

  // 1. Verify OTP in Firestore
  const otpDoc = await admin.firestore().collection("password_resets").doc(cleanEmail).get();
  if (!otpDoc.exists) {
    throw new functions.https.HttpsError("not-found", "OTP reset request not found.");
  }

  const otpData = otpDoc.data();
  const nowMillis = Date.now();

  let expiresMillis = 0;
  if (otpData.expiresAt) {
    if (typeof otpData.expiresAt.toMillis === "function") {
      expiresMillis = otpData.expiresAt.toMillis();
    } else if (otpData.expiresAt instanceof Date) {
      expiresMillis = otpData.expiresAt.getTime();
    } else if (typeof otpData.expiresAt === "string") {
      expiresMillis = new Date(otpData.expiresAt).getTime();
    }
  }

  if (
    otpData.otp.toString().trim() !== otp.toString().trim() ||
    !otpData.verified ||
    expiresMillis < nowMillis
  ) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Invalid or expired OTP verification token."
    );
  }

  // 2. Fetch User UID by Email and Update Password in Firebase Auth
  try {
    const userRecord = await admin.auth().getUserByEmail(cleanEmail);
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });
  } catch (authError) {
    if (authError.code === "auth/user-not-found") {
      throw new functions.https.HttpsError("not-found", "No user found with this email address.");
    }
    throw new functions.https.HttpsError(
      "internal",
      authError.message || "Failed to update user password."
    );
  }

  // 3. Delete the used OTP record
  try {
    await admin.firestore().collection("password_resets").doc(cleanEmail).delete();
  } catch (_) {}

  return {
    success: true,
    message: "Password updated successfully in Firebase Auth",
  };
});

/**
 * Firestore Trigger: sendBroadcastNotification
 * Automatically dispatches high-importance FCM push notifications to all users (even when app is closed)
 * whenever a new notification is added to the Firestore 'notifications' collection.
 */
exports.sendBroadcastNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const title = data.title || data.title_en || "NOOR E SUNNAT Notification";
    const body = data.body || data.body_en || "";
    const target = data.target || "all_users";
    const notificationType = data.type || "announcement";

    const payload = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        id: context.params.notificationId || "",
        type: notificationType,
        title: title,
        body: body,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
          priority: "max",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            contentAvailable: true,
          },
        },
      },
      topic:
        target === "all" || target === "all_users" || target === "broadcast" || target === "active_today"
          ? "all_users"
          : target,
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log("FCM push notification successfully dispatched:", response);
      return response;
    } catch (error) {
      console.error("Error dispatching FCM push notification:", error);
      return null;
    }
  });

