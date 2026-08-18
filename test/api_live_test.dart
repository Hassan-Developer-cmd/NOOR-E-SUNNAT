import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:islamic_app/core/services/email_otp_service.dart';

void main() {
  test('Live EmailJS API check', () async {
    const serviceId = EmailOtpService.serviceId;
    const templateId = EmailOtpService.templateId;
    const publicKey = EmailOtpService.publicKey;

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
          'email': 'test@example.com',
          'passcode': '654321',
          'to_email': 'test@example.com',
          'otp': '654321',
        },
      }),
    );

    expect(response.statusCode, 200);
    expect(response.body, 'OK');
  });
}
