// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('====================================================');
  print('TESTING EMAILJS WELCOME EMAIL API IN REAL TIME');
  print('====================================================\n');

  const String serviceId = 'service_vgjbxj8';
  const String welcomeTemplateId = 'template_281ript';
  const String publicKey = 'uzTJrrG9BN7RVLC40';
  const String targetEmail = 'flowerpeshawar6@gmail.com';
  final Uri url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  print('>>> Testing Welcome Email API (Template: $welcomeTemplateId)...');
  try {
    final welcomePayload = {
      'service_id': serviceId,
      'template_id': welcomeTemplateId,
      'user_id': publicKey,
      'template_params': {
        'email': targetEmail,
        'to_email': targetEmail,
        'recipient_email': targetEmail,
        'user_email': targetEmail,
        'user_name': 'Hassan Developer',
        'name': 'Hassan Developer',
        'app_name': 'Islamic App',
        'reply_to': targetEmail,
        'from_name': 'Islamic App',
        'subject': 'Welcome to Islamic App | Assalamu Alaikum',
      },
    };

    final welcomeResponse = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost',
      },
      body: jsonEncode(welcomePayload),
    );

    print('Welcome Email HTTP Status: ${welcomeResponse.statusCode}');
    print('Welcome Email Response Body: ${welcomeResponse.body}');
    if (welcomeResponse.statusCode == 200) {
      print(' [PASSED] Welcome Email API is working 100% properly!\n');
    } else {
      print(' [FAILED] Welcome Email API returned non-200 status.\n');
    }
  } catch (e) {
    print(' [ERROR] Welcome Email exception: $e\n');
  }

  print('====================================================');
  print('EMAIL API TEST SUITE FINISHED');
  print('====================================================');
}
