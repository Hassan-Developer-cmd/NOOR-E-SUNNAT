import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:islamic_app/services/fcm_v1_service.dart';

void main() {
  HttpOverrides.global = null;

  group('FCM v1 Authentication & Token Generation Tests', () {
    test('Service Account credentials from file or embedded fallback are valid', () async {
      final creds = await FcmV1Service.getServiceAccountCredentials();
      expect(creds, isNotNull);
      expect(creds['project_id'], equals('islamic-app-ed1ed'));
      expect(creds['client_email'], contains('islamic-app-ed1ed'));
      expect(creds['private_key'], contains('BEGIN PRIVATE KEY'));
    });

    test('OAuth2 Bearer Access Token generation succeeds via Google APIs', () async {
      final file = File('service-account.json');
      Map<String, dynamic> jsonMap;
      if (file.existsSync()) {
        jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      } else {
        jsonMap = await FcmV1Service.getServiceAccountCredentials();
      }

      final creds = ServiceAccountCredentials.fromJson(jsonMap);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(creds, scopes);
      expect(client.credentials.accessToken.data, isNotEmpty);
      expect(client.credentials.accessToken.type, equals('Bearer'));
      client.close();
    });

    test('FcmV1Service.getOAuth2AccessToken returns valid Bearer token', () async {
      final token = await FcmV1Service.getOAuth2AccessToken();
      expect(token, isNotNull);
      expect(token!.length, greaterThan(20));
    });
  });

  group('FCM v1 REST Payload Structure Compliance Tests', () {
    test('buildBroadcastPayload satisfies mandatory terminated delivery spec', () {
      final payload = FcmV1Service.buildBroadcastPayload(
        title: 'Test Notification Title',
        body: 'Test Notification Body',
        topic: 'all_users',
        type: 'broadcast',
        route: '/home',
        id: 'notif_123',
      );

      expect(payload, contains('message'));
      final message = payload['message'] as Map<String, dynamic>;

      // 1. Topic
      expect(message['topic'], equals('all_users'));

      // 2. Top-level Notification block (Mandatory for terminated Android delivery)
      expect(message, contains('notification'));
      final notification = message['notification'] as Map<String, dynamic>;
      expect(notification['title'], equals('Test Notification Title'));
      expect(notification['body'], equals('Test Notification Body'));

      // 3. Data block
      expect(message, contains('data'));
      final data = message['data'] as Map<String, dynamic>;
      expect(data['click_action'], equals('FLUTTER_NOTIFICATION_CLICK'));
      expect(data['type'], equals('broadcast'));
      expect(data['route'], equals('/home'));
      expect(data['id'], equals('notif_123'));

      // 4. Android configuration block (Mandatory high priority & notification channel)
      expect(message, contains('android'));
      final android = message['android'] as Map<String, dynamic>;
      expect(android['priority'], equals('high'));

      final androidNotif = android['notification'] as Map<String, dynamic>;
      expect(androidNotif['channel_id'], equals('high_importance_channel'));
      expect(androidNotif['sound'], equals('default'));
      expect(androidNotif['default_sound'], isTrue);
      expect(androidNotif['default_vibrate_timings'], isTrue);
      expect(androidNotif['notification_priority'], equals('PRIORITY_MAX'));

      // 5. APNs configuration block
      expect(message, contains('apns'));
      final apns = message['apns'] as Map<String, dynamic>;
      expect(apns['payload']['aps']['sound'], equals('default'));
      expect(apns['payload']['aps']['content-available'], equals(1));
    });

    test('buildTokenPayload produces strictly compliant 1-to-1 payload', () {
      const testToken = 'fcm_sample_device_token_xyz_12345';
      final payload = FcmV1Service.buildTokenPayload(
        fcmToken: testToken,
        title: 'Question Answered',
        body: 'Scholar responded to your question',
        type: 'question_answered',
        route: '/qna',
        questionId: 'q_999',
      );

      final message = payload['message'] as Map<String, dynamic>;
      expect(message['token'], equals(testToken));
      expect(message['notification']['title'], equals('Question Answered'));
      expect(message['notification']['body'], equals('Scholar responded to your question'));
      expect(message['data']['route'], equals('/qna'));
      expect(message['data']['questionId'], equals('q_999'));
      expect(message['android']['notification']['channel_id'], equals('high_importance_channel'));
    });

    test('FcmV1Service.sendBroadcast dispatches live FCM v1 HTTP request with 200 OK', () async {
      final success = await FcmV1Service.sendBroadcast(
        title: 'NOOR E SUNNAT - Live Broadcast Test',
        body: 'Testing live FCM v1 endpoint delivery for all_users',
        topic: 'all_users',
        type: 'broadcast',
        route: '/home',
      );
      expect(success, isTrue);
    });
  });
}


