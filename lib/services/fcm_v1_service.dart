import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmV1Service {
  static const String projectId = 'islamic-app-ed1ed';
  static const String fcmV1Endpoint =
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

  static AccessToken? _cachedToken;
  static String? _cachedServiceAccountJson;

  /// Loads service account JSON from file or Firestore app_config.
  static Future<Map<String, dynamic>?> getServiceAccountCredentials() async {
    // 1. Check in-memory cached string
    if (_cachedServiceAccountJson != null) {
      try {
        return jsonDecode(_cachedServiceAccountJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    // 2. Check local file (if running in IO environment)
    if (!kIsWeb) {
      try {
        final file = File('service-account.json');
        if (file.existsSync()) {
          final content = await file.readAsString();
          _cachedServiceAccountJson = content;
          return jsonDecode(content) as Map<String, dynamic>;
        }
      } catch (e) {
        if (kDebugMode) print('FcmV1Service file read note: $e');
      }
    }

    // 3. Check Firestore app_config collection
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('fcm_v1_credentials')
          .get();
      if (doc.exists && doc.data() != null) {
        final rawJson = doc.data()!['service_account_json'] as String?;
        if (rawJson != null && rawJson.isNotEmpty) {
          _cachedServiceAccountJson = rawJson;
          return jsonDecode(rawJson) as Map<String, dynamic>;
        }
        if (doc.data()!['client_email'] != null) {
          return Map<String, dynamic>.from(doc.data()!);
        }
      }
    } catch (e) {
      if (kDebugMode) print('FcmV1Service firestore read note: $e');
    }

    return null;
  }

  /// Saves or updates the Service Account JSON in Firestore app_config
  static Future<void> saveServiceAccountCredentials(String jsonStr) async {
    _cachedServiceAccountJson = jsonStr.trim();
    _cachedToken = null;
    await FirebaseFirestore.instance
        .collection('app_config')
        .doc('fcm_v1_credentials')
        .set({
      'service_account_json': jsonStr.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Generates a valid OAuth2 Bearer Access Token for FCM v1.
  static Future<String?> getOAuth2AccessToken() async {
    // Return cached token if still valid (with 60-second buffer)
    if (_cachedToken != null) {
      final now = DateTime.now().toUtc();
      if (_cachedToken!.expiry.isAfter(now.add(const Duration(seconds: 60)))) {
        return _cachedToken!.data;
      }
    }

    final credsMap = await getServiceAccountCredentials();
    if (credsMap == null) {
      if (kDebugMode) print('FcmV1Service: No service account credentials found');
      return null;
    }

    try {
      final credentials = ServiceAccountCredentials.fromJson(credsMap);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);
      _cachedToken = client.credentials.accessToken;
      client.close();
      return _cachedToken?.data;
    } catch (e) {
      if (kDebugMode) print('FcmV1Service OAuth2 Token Error: $e');
      return null;
    }
  }

  /// Sends a broadcast push notification to a topic (default: "all_users") via FCM v1.
  static Future<bool> sendBroadcast({
    required String title,
    required String body,
    String topic = 'all_users',
    String type = 'broadcast',
    String? id,
    String? route,
    String? eventId,
    String? questionId,
  }) async {
    final cleanTopic = topic.replaceAll('/topics/', '');
    final token = await getOAuth2AccessToken();
    if (token == null) {
      if (kDebugMode) print('FcmV1Service.sendBroadcast: Failed to acquire OAuth2 token');
      return false;
    }

    final messagePayload = {
      'message': {
        'topic': cleanTopic,
        'notification': {
          'title': title.trim(),
          'body': body.trim(),
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'type': type,
          'title': title.trim(),
          'body': body.trim(),
          'route': route ?? '/home',
          'id': id ?? '',
          'eventId': eventId ?? '',
          'questionId': questionId ?? '',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'high_importance_channel',
            'sound': 'default',
            'priority': 'high',
            'default_sound': true,
            'default_vibrate_timings': true,
            'notification_priority': 'PRIORITY_MAX',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
              'content-available': 1,
            },
          },
        },
      },
    };

    try {
      final response = await http.post(
        Uri.parse(fcmV1Endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(messagePayload),
      );

      if (kDebugMode) {
        print('FcmV1Service.sendBroadcast status: ${response.statusCode} response: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('FcmV1Service.sendBroadcast network error: $e');
      return false;
    }
  }

  /// Sends a targeted 1-to-1 push notification directly to a specific device FCM token via FCM v1.
  static Future<bool> sendToToken({
    required String fcmToken,
    required String title,
    required String body,
    String type = 'question_answered',
    String? id,
    String? route,
    String? questionId,
  }) async {
    final token = await getOAuth2AccessToken();
    if (token == null) {
      if (kDebugMode) print('FcmV1Service.sendToToken: Failed to acquire OAuth2 token');
      return false;
    }

    final messagePayload = {
      'message': {
        'token': fcmToken.trim(),
        'notification': {
          'title': title.trim(),
          'body': body.trim(),
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'type': type,
          'title': title.trim(),
          'body': body.trim(),
          'route': route ?? '/qna',
          'id': id ?? '',
          'questionId': questionId ?? '',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'high_importance_channel',
            'sound': 'default',
            'priority': 'high',
            'default_sound': true,
            'default_vibrate_timings': true,
            'notification_priority': 'PRIORITY_MAX',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
              'content-available': 1,
            },
          },
        },
      },
    };

    try {
      final response = await http.post(
        Uri.parse(fcmV1Endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(messagePayload),
      );

      if (kDebugMode) {
        print('FcmV1Service.sendToToken status: ${response.statusCode} response: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('FcmV1Service.sendToToken network error: $e');
      return false;
    }
  }
}
