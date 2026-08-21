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
  static const String cloudFunctionProxyEndpoint =
      'https://us-central1-islamic-app-ed1ed.cloudfunctions.net/sendFCMBroadcastHttp';

  /// Embedded fallback Service Account configuration (islamic-app-ed1ed)
  static const Map<String, dynamic> _embeddedServiceAccount = {
    "type": "service_account",
    "project_id": "islamic-app-ed1ed",
    "private_key_id": "4c86a78ce111801435edc56080a39fead51467a5",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDK4DwpxziXhR+x\n/4KFwFIyICJDZj7r6i0xwVYfYaRZNPd3SuTYOtAnpYlSfGDxi4AEJY7KWvDZZWjS\n2Cg15SLYcxZ+9c8l1OH/VVwD8pSoNm3ualylEwStE9WnHqtpSQjfwg39ftUOSHgi\nvFm1Va6ctSYmvAoJXo2zAqhUvuz9iEkKY5rwtxg4R/TM6DXrD2CMj9hOuAuhgigt\nQrz8IudE0x1NtRb9jHlgyH7mGYF3vlJY3wlvkORjrTpPvI0FdKBU7slf+u2JZ9Nc\nmiQbbj8DXjIDxoQwn771apu2uX3acwxazGJjfSa9a2BRHxL0kLMJDZ90H7HJHZfY\noQ1KFXX7AgMBAAECggEANsn2FYZS90Chfa22by6wRA8/kZo0VfwJNo2zF4iEHP9b\n8aCNSwQfIQXonxkuCS2WZghKlsWWk+96Lq7ntR5rma8DHUh/KAVk/1LrJbnGgeMp\nLyEUYhRPx/o6UgbLXgS2W8+JfbNaEKBrqV3akElSfcnCQuW3hC4/8F9AXJqvYAyK\nLAvdqzQ/IFm5BUlBwB5BF7QFejE7gA6dQNAuALChnYH5ERwxWvsdcsZqTtLrMXiq\nbrRoTO38/3vH84Q6EvjXaL99r0fKkx50zJx4FoVFOZGxAd07efw+i4Qcnm9RfnaF\n39hR5JhPafmgGtS1JMnSGqqc1MToWs00taqangHP8QKBgQDmAmiEi3F1dIrdK8ky\nNIRBX8vG5gU43LAiAm7RSTKGCewTTZcS6uIraTWt/sxI7ZhwrxwsWrZ8ClbrrWBG\nR1G44DmKZRZkvCYE+bduHDrdfpnGLIS0BLSTdMpDNJ4vTIHv+bARLFo1xdhg1pSN\n2Wz6ZJS+9fOIZlefKhiDoU/XAwKBgQDhzOxhsdTpjsX3x4E9WNhQR/Ts04Fu0Vg7\nX+A3xH09v2ZJLazmY9wgjSnDGe/pqUqMo0iZObt/t1P4309AB0wFILAA9hkkc4HE\ngZ4vNMVBR81lJoCcgK6osVFEwb/lEiwelkcey3Z8WnqnW1hB8SpN0W5Ayg4PYjN8\nc5ZvAe/XqQKBgQDB1t+8bEPnB5uLvz3lCKs46QG0Et/txtbNIp2/1N82ZSBGOEqM\nT9ThXt41T5lcEJg6xuiIXL6TlKciIVAUikBN/PGhN4YCySmFYen7auEVD3+KqrP/\nfkOsTW2z66EwHVsYIaYHIwi3bo/nNI+nZ8hW0PMmZ+KgXheT9IcKT6UYfwKBgQDd\nzAQ5povEa8kMLb1GfFnm6fetFckjCKHJmNDPFsQK/lJD+YjHujmFBASMr5KZDAC9\nirqKQEpsFrF2WiwnccN7mfMozpQ92PQUCVpPdl94U0ZvYFWe5UwrShnRFxwesC4E\nUYtEtYkKd3nZoIFeLL1oORs6qv8Kn2SBj6yqF9X3GQKBgQCBb8e2pyHAF611gTRY\n7SqP+sIKrP9254Sj4/BpZ7T4tJXrpf35ELSamuHBei9Mig3VaF/BfA2QOC7UheZP\nXGjDpndJMA/s8GDaZQ32H8u2DMJTm4TdZHSXprBKr0cA38qjvaIektJjNlDJI18E\n2k1kDXQMkPejsMO2HR/2IbMxdw==\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@islamic-app-ed1ed.iam.gserviceaccount.com",
    "client_id": "114161757705768045022",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url":
        "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40islamic-app-ed1ed.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  static AccessToken? _cachedToken;
  static String? _cachedServiceAccountJson;

  /// Loads service account JSON from memory, local file, Firestore app_config, or embedded fallback.
  static Future<Map<String, dynamic>> getServiceAccountCredentials() async {
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

    // 4. Return embedded fallback credentials
    return Map<String, dynamic>.from(_embeddedServiceAccount);
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

    try {
      final credsMap = await getServiceAccountCredentials();
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

  /// Builds strictly typed FCM v1 broadcast payload for topic targeting.
  static Map<String, dynamic> buildBroadcastPayload({
    required String title,
    required String body,
    String topic = 'all_users',
    String type = 'broadcast',
    String? id,
    String? route,
    String? eventId,
    String? questionId,
  }) {
    final cleanTopic = topic.replaceAll('/topics/', '');
    return {
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
  }

  /// Builds strictly typed FCM v1 payload for 1-to-1 device token targeting.
  static Map<String, dynamic> buildTokenPayload({
    required String fcmToken,
    required String title,
    required String body,
    String type = 'question_answered',
    String? id,
    String? route,
    String? questionId,
  }) {
    return {
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
  }

  /// Sends a broadcast push notification to a topic (default: "all_users") via FCM v1 REST API
  /// with automatic fallback to Cloud Function HTTP proxy (for browser CORS handling).
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
    final payload = buildBroadcastPayload(
      title: title,
      body: body,
      topic: cleanTopic,
      type: type,
      id: id,
      route: route,
      eventId: eventId,
      questionId: questionId,
    );

    // 1. Direct FCM v1 HTTP Dispatch via Google Authenticated Client
    try {
      final credsMap = await getServiceAccountCredentials();
      final credentials = ServiceAccountCredentials.fromJson(credsMap);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);
      final response = await client.post(
        Uri.parse(fcmV1Endpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      );
      client.close();

      if (kDebugMode) {
        print(
          'FcmV1Service.sendBroadcast status: ${response.statusCode} response: ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('FcmV1Service.sendBroadcast auth client note: $e');
    }

    // 2. Fallback: Direct FCM v1 HTTP POST using Bearer token
    try {
      final token = await getOAuth2AccessToken();
      if (token != null) {
        final response = await http.post(
          Uri.parse(fcmV1Endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(payload),
        );

        if (kDebugMode) {
          print(
            'FcmV1Service.sendBroadcast bearer status: ${response.statusCode} response: ${response.body}',
          );
        }

        if (response.statusCode == 200) {
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) print('FcmV1Service.sendBroadcast direct bearer note: $e');
    }

    // 3. Fallback to Cloud Function HTTP Proxy (CORS-enabled for Web browsers)
    try {
      final proxyResponse = await http.post(
        Uri.parse(cloudFunctionProxyEndpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'title': title.trim(),
          'body': body.trim(),
          'target': cleanTopic,
          'type': type,
          'route': route ?? '/home',
          'id': id ?? '',
          'eventId': eventId ?? '',
          'questionId': questionId ?? '',
        }),
      );

      if (kDebugMode) {
        print(
          'FcmV1Service CloudFunction proxy status: ${proxyResponse.statusCode} response: ${proxyResponse.body}',
        );
      }

      if (proxyResponse.statusCode == 200) {
        return true;
      }
    } catch (proxyError) {
      if (kDebugMode) {
        print('FcmV1Service CloudFunction proxy note: $proxyError');
      }
    }

    return false;
  }

  /// Sends a targeted 1-to-1 push notification directly to a specific device FCM token via FCM v1 REST API
  /// with automatic fallback to Cloud Function HTTP proxy.
  static Future<bool> sendToToken({
    required String fcmToken,
    required String title,
    required String body,
    String type = 'question_answered',
    String? id,
    String? route,
    String? questionId,
  }) async {
    final payload = buildTokenPayload(
      fcmToken: fcmToken,
      title: title,
      body: body,
      type: type,
      id: id,
      route: route,
      questionId: questionId,
    );

    // 1. Direct FCM v1 HTTP Dispatch via Google Authenticated Client
    try {
      final credsMap = await getServiceAccountCredentials();
      final credentials = ServiceAccountCredentials.fromJson(credsMap);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);
      final response = await client.post(
        Uri.parse(fcmV1Endpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      );
      client.close();

      if (kDebugMode) {
        print(
          'FcmV1Service.sendToToken status: ${response.statusCode} response: ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('FcmV1Service.sendToToken auth client note: $e');
    }

    // 2. Fallback: Direct FCM v1 HTTP POST using Bearer token
    try {
      final token = await getOAuth2AccessToken();
      if (token != null) {
        final response = await http.post(
          Uri.parse(fcmV1Endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(payload),
        );

        if (kDebugMode) {
          print(
            'FcmV1Service.sendToToken bearer status: ${response.statusCode} response: ${response.body}',
          );
        }

        if (response.statusCode == 200) {
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) print('FcmV1Service.sendToToken direct bearer note: $e');
    }

    // 3. Fallback to Cloud Function HTTP Proxy
    try {
      final proxyResponse = await http.post(
        Uri.parse(cloudFunctionProxyEndpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'fcmToken': fcmToken.trim(),
          'title': title.trim(),
          'body': body.trim(),
          'type': type,
          'route': route ?? '/qna',
          'id': id ?? '',
          'questionId': questionId ?? '',
        }),
      );

      if (kDebugMode) {
        print(
          'FcmV1Service.sendToToken proxy status: ${proxyResponse.statusCode} response: ${proxyResponse.body}',
        );
      }

      if (proxyResponse.statusCode == 200) {
        return true;
      }
    } catch (proxyError) {
      if (kDebugMode) {
        print('FcmV1Service.sendToToken proxy note: $proxyError');
      }
    }

    return false;
  }
}

