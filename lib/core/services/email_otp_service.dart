import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Dedicated Service for dispatching Welcome Emails via EmailJS REST API.
class EmailWelcomeService {
  static const String serviceId = 'service_vgjbxj8';
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
        print('EmailWelcomeService.sendWelcomeEmail: status = ${response.statusCode}, body = ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('EmailWelcomeService.sendWelcomeEmail error: $e');
      }
      return false;
    }
  }
}

/// Backwards compatibility alias for EmailWelcomeService
typedef EmailOtpService = EmailWelcomeService;
