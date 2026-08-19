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
