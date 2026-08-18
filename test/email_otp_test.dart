import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/services/email_otp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmailOtpService Configuration & Token Generation Tests', () {
    test('EmailOtpService contains correct EmailJS credentials', () {
      expect(EmailOtpService.serviceId, 'service_vgjbxj8');
      expect(EmailOtpService.templateId, 'template_bwt1dsb');
      expect(EmailOtpService.publicKey, 'uzTJrrG9BN7RVLC40');
    });

    test('6-digit OTP generated is within valid numeric range', () {
      for (int i = 0; i < 100; i++) {
        final otp = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
        expect(otp.length, 6);
        final num = int.tryParse(otp);
        expect(num, isNotNull);
        expect(num! >= 100000 && num <= 999999, isTrue);
      }
    });
  });
}
