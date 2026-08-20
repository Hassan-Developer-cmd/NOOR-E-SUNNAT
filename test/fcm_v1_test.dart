import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/auth_io.dart';

void main() {
  test('FCM v1 Service Account authentication and token generation test', () async {
    final file = File('service-account.json');
    if (!file.existsSync()) {
      return;
    }
    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final creds = ServiceAccountCredentials.fromJson(jsonMap);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    
    final client = await clientViaServiceAccount(creds, scopes);
    expect(client.credentials.accessToken.data, isNotEmpty);
    expect(client.credentials.accessToken.type, equals('Bearer'));
    client.close();
  });
}

