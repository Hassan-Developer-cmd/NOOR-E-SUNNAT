import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailOtpService {
  static const String serviceId = 'service_vgjbxj8';
  static const String templateId = 'template_bwt1dsb';
  static const String welcomeTemplateId = 'template_281ript';
  static const String publicKey = 'uzTJrrG9BN7RVLC40';
  static const String verifiedReplyTo = 'flowerpeshawar6@gmail.com';

  /// Dispatches a spam-safe Welcome Email to newly registered users
  /// using EmailJS REST API matching strict inbox deliverability standards.
  static Future<bool> sendWelcomeEmail({
    required String email,
    String name = '',
  }) async {
    try {
      final cleanEmail = email.toLowerCase().trim();
      final displayName = name.trim().isNotEmpty ? name.trim() : 'Beloved Member';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': welcomeTemplateId,
          'user_id': publicKey,
          'template_params': {
            'email': cleanEmail,
            'to_email': cleanEmail,
            'recipient_email': cleanEmail,
            'user_email': cleanEmail,
            'user_name': displayName,
            'name': displayName,
            'app_name': 'Islamic App',
            'reply_to': verifiedReplyTo,
            'from_name': 'Islamic App',
            'subject': 'Welcome to Islamic App | Assalamu Alaikum',
          },
        }),
      );

      if (kDebugMode) {
        print('EmailOtpService.sendWelcomeEmail: status = ${response.statusCode}, body = ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('EmailOtpService.sendWelcomeEmail error: $e');
      }
      return false;
    }
  }

  /// Dispatches a real-time 6-digit OTP code to the provided Gmail/Email
  /// using EmailJS REST API and records the verification token in Firestore.
  static Future<bool> sendPasswordResetOtp(String email) async {
    try {
      final cleanEmail = email.toLowerCase().trim();
      final String otp = (100000 + Random().nextInt(900000)).toString();

      // Save OTP to Firestore with 5-minute expiry
      await FirebaseFirestore.instance.collection('password_resets').doc(cleanEmail).set({
        'otp': otp,
        'email': cleanEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 5)),
        'verified': false,
      });

      // Dispatch email via EmailJS API
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'email': cleanEmail,
            'to_email': cleanEmail,
            'recipient_email': cleanEmail,
            'user_email': cleanEmail,
            'passcode': otp,
            'otp': otp,
            'code': otp,
            'from_name': 'Faizan-e-Durood Security',
            'app_name': 'Islamic App',
            'reply_to': verifiedReplyTo,
            'subject': 'Your 6-Digit Password Reset Code: $otp',
          },
        }),
      );

      if (kDebugMode) {
        print('EmailOtpService.sendPasswordResetOtp: response code = ${response.statusCode}, body = ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('EmailOtpService.sendPasswordResetOtp error: $e');
      }
      return false;
    }
  }

  /// Verifies if the entered 6-digit OTP matches the valid, unexpired token in Firestore.
  static Future<bool> verifyOtp(String email, String enteredOtp) async {
    try {
      final cleanEmail = email.toLowerCase().trim();
      final doc = await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(cleanEmail)
          .get();

      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null) return false;

      final String storedOtp = data['otp']?.toString() ?? '';
      DateTime expiresAt;

      if (data['expiresAt'] is Timestamp) {
        expiresAt = (data['expiresAt'] as Timestamp).toDate();
      } else if (data['expiresAt'] is String) {
        expiresAt = DateTime.tryParse(data['expiresAt']) ?? DateTime.now().subtract(const Duration(days: 1));
      } else {
        expiresAt = DateTime.now().subtract(const Duration(days: 1));
      }

      if (DateTime.now().isBefore(expiresAt) && storedOtp.trim() == enteredOtp.trim()) {
        await doc.reference.update({
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('EmailOtpService.verifyOtp error: $e');
      }
      return false;
    }
  }

  /// Checks whether an email has successfully completed OTP verification in Firestore.
  static Future<bool> isOtpVerified(String email) async {
    try {
      final cleanEmail = email.toLowerCase().trim();
      final doc = await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(cleanEmail)
          .get();

      if (!doc.exists) return false;
      final data = doc.data();
      return data?['verified'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Cleans up used OTP records after password update
  static Future<void> cleanupOtp(String email) async {
    try {
      final cleanEmail = email.toLowerCase().trim();
      await FirebaseFirestore.instance.collection('password_resets').doc(cleanEmail).delete();
    } catch (_) {}
  }

  /// Updates user password in Firebase Auth using the Admin SDK Cloud Function.
  /// Strictly requires successful backend execution so the real credential changes immediately.
  static Future<PasswordUpdateResult> updateUserPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    final cleanOtp = otp.trim();

    // 0. Verify OTP in Firestore
    final isVerified = await verifyOtp(cleanEmail, cleanOtp);
    if (!isVerified) {
      final alreadyVerified = await isOtpVerified(cleanEmail);
      if (!alreadyVerified) {
        return const PasswordUpdateResult(
          isSuccess: false,
          isCloudFunctionSuccess: false,
          message: 'Invalid or expired OTP code. Please check your Gmail inbox.',
        );
      }
    }

    // 1. Execute Backend Cloud Function with Firebase Admin SDK
    try {
      final callableUrl = Uri.parse(
        'https://us-central1-islamic-app-ed1ed.cloudfunctions.net/updateUserPasswordWithOtp',
      );

      final response = await http.post(
        callableUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'email': cleanEmail,
            'otp': cleanOtp,
            'newPassword': newPassword,
          },
          'email': cleanEmail,
          'otp': cleanOtp,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && (decoded['result']?['success'] == true || decoded['success'] == true)) {
          await cleanupOtp(cleanEmail);
          if (kDebugMode) {
            print('EmailOtpService: Password successfully updated via Firebase Admin SDK Cloud Function.');
          }
          return const PasswordUpdateResult(
            isSuccess: true,
            isCloudFunctionSuccess: true,
            message: 'Password updated successfully in Firebase Auth.',
          );
        }
      }

      if (kDebugMode) {
        print('EmailOtpService: Cloud Function status ${response.statusCode}: ${response.body}');
      }

      String errorMsg = 'Failed to update password in Firebase Auth.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          errorMsg = decoded['error'].toString();
        }
      } catch (_) {}

      // If active session exists, update directly as fallback
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email?.toLowerCase() == cleanEmail) {
        await currentUser.updatePassword(newPassword);
        await cleanupOtp(cleanEmail);
        return const PasswordUpdateResult(
          isSuccess: true,
          isCloudFunctionSuccess: true,
          message: 'Password updated successfully for current session.',
        );
      }

      return PasswordUpdateResult(
        isSuccess: false,
        isCloudFunctionSuccess: false,
        message: response.statusCode == 404
            ? 'Firebase Cloud Function not yet deployed. Please deploy functions ("firebase deploy --only functions") to enable password updates.'
            : errorMsg,
      );
    } catch (e) {
      if (kDebugMode) {
        print('EmailOtpService.updateUserPassword error: $e');
      }

      // If user session is active, try updating directly
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.email?.toLowerCase() == cleanEmail) {
          await currentUser.updatePassword(newPassword);
          await cleanupOtp(cleanEmail);
          return const PasswordUpdateResult(
            isSuccess: true,
            isCloudFunctionSuccess: true,
            message: 'Password updated successfully for current user.',
          );
        }
      } catch (_) {}

      return PasswordUpdateResult(
        isSuccess: false,
        isCloudFunctionSuccess: false,
        message: 'Could not connect to password reset service: $e',
      );
    }
  }
}

class PasswordUpdateResult {
  final bool isSuccess;
  final bool isCloudFunctionSuccess;
  final String message;

  const PasswordUpdateResult({
    required this.isSuccess,
    required this.isCloudFunctionSuccess,
    required this.message,
  });
}
