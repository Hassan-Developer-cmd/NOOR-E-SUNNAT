const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * HTTP / Callable Cloud Function: updateUserPasswordWithOtp
 * Verifies the 6-digit OTP token in Firestore and updates the user's password in Firebase Auth using Admin SDK.
 * Supports both direct REST HTTP requests (with CORS) and Firebase Callable SDK requests.
 */
exports.updateUserPasswordWithOtp = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST.",
    });
  }

  try {
    const body = (req.body && req.body.data) ? req.body.data : (req.body || {});
    const { email, otp, newPassword } = body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        error: "Missing required fields: email, otp, or newPassword.",
      });
    }

    const cleanEmail = email.toLowerCase().trim();
    const cleanOtp = otp.toString().trim();

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        error: "Password must be at least 6 characters long.",
      });
    }

    // 1. Verify OTP in Firestore
    const otpDoc = await admin.firestore().collection("password_resets").doc(cleanEmail).get();
    if (!otpDoc.exists) {
      return res.status(404).json({
        success: false,
        error: "OTP reset request not found or expired.",
      });
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
      otpData.otp.toString().trim() !== cleanOtp ||
      !otpData.verified ||
      expiresMillis < nowMillis
    ) {
      return res.status(403).json({
        success: false,
        error: "Invalid or expired OTP verification token.",
      });
    }

    // 2. Fetch User UID by Email and Update Password in Firebase Auth
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(cleanEmail);
    } catch (userErr) {
      if (userErr.code === "auth/user-not-found") {
        return res.status(404).json({
          success: false,
          error: "No Firebase Auth user account found with this email address.",
        });
      }
      throw userErr;
    }

    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    // 3. Delete the used OTP record from Firestore
    try {
      await admin.firestore().collection("password_resets").doc(cleanEmail).delete();
    } catch (_) {}

    return res.status(200).json({
      result: {
        success: true,
        message: "Password updated successfully in Firebase Auth",
      },
      success: true,
      message: "Password updated successfully in Firebase Auth",
    });
  } catch (err) {
    console.error("updateUserPasswordWithOtp error:", err);
    return res.status(500).json({
      success: false,
      error: err.message || "Internal server error updating password.",
    });
  }
});

/**
 * Firestore Trigger: sendBroadcastNotification
 * Dispatches high-importance FCM push notifications.
 * Supports targeted 1-to-1 token delivery (when fcm_token or user target is specified)
 * and broadcast delivery (when target is all_users / broadcast).
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
    const directToken = data.fcm_token || data.token || null;

    const isBroadcast =
      target === "all" ||
      target === "all_users" ||
      target === "broadcast" ||
      target === "active_today";

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
        route: notificationType === "question_answered" || notificationType === "question_received" ? "/qna" : "/home",
        questionId: data.question_id || "",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
          priority: "max",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
          defaultSound: true,
          defaultVibrateTimings: true,
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
    };

    // 1-to-1 Direct Token Target
    if (directToken) {
      payload.token = directToken;
    } else if (isBroadcast) {
      payload.topic = "all_users";
    } else {
      // User-specific topic fallback (user_<userId>)
      payload.topic = `user_${target}`;
    }

    try {
      const response = await admin.messaging().send(payload);
      console.log("FCM notification successfully dispatched:", response);
      return response;
    } catch (error) {
      console.error("Error dispatching FCM notification:", error);
      return null;
    }
  });

/**
 * Firestore Trigger: onQuestionAnswered
 * Automatically sends targeted 1-to-1 push notification directly to the question author's FCM token
 * when an admin updates the question status to 'Answered'.
 */
exports.onQuestionAnswered = functions.firestore
  .document("user_questions/{questionId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data() || {};
    const afterData = change.after.data() || {};

    const wasAnswered = beforeData.status && beforeData.status.toLowerCase() === "answered";
    const isNowAnswered = afterData.status && afterData.status.toLowerCase() === "answered";

    // Only trigger when transitioned to Answered
    if (wasAnswered || !isNowAnswered) {
      return null;
    }

    const fcmToken = afterData.fcm_token || afterData.fcmToken;
    const userId = afterData.user_id || afterData.userId;

    if (!fcmToken && (!userId || userId === "guest")) {
      console.warn(`No FCM token or valid userId found for question ${context.params.questionId}. Skipping push notification.`);
      return null;
    }

    const payload = {
      notification: {
        title: "آپ کے سوال کا جواب دے دیا گیا ہے / Question Answered",
        body: "علمائے کرام نے آپ کے سوال کا جواب فراہم کر دیا ہے۔ دیکھنے کے لیے ٹیپ کریں۔",
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        route: "/qna",
        questionId: context.params.questionId,
        type: "question_answered",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
          priority: "max",
          defaultSound: true,
          defaultVibrateTimings: true,
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
    };

    if (fcmToken) {
      payload.token = fcmToken;
    } else {
      payload.topic = `user_${userId}`;
    }

    try {
      const response = await admin.messaging().send(payload);
      console.log(`1-to-1 FCM response notification sent for question ${context.params.questionId}:`, response);
      return response;
    } catch (error) {
      console.warn(`Targeted FCM delivery error for question ${context.params.questionId}:`, error);
      return null;
    }
  });
