import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailOtpService {
  static const String serviceId = 'service_vgjbxj8';
  static const String templateId = 'template_bwt1dsb';
  static const String publicKey = 'uzTJrrG9BN7RVLC40';

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
          },
        }),
      );

      if (kDebugMode) {
        print('EmailOtpService: EmailJS response code = ${response.statusCode}, body = ${response.body}');
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
}
