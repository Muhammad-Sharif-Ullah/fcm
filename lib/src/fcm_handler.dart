import 'dart:convert';
import 'dart:io';
import "package:http/http.dart" as http;

import 'package:googleapis_auth/auth_io.dart';

/// Due to differences of clock speed, network latency, etc. we
/// will shorten expiry dates by 20 seconds.
const maxExpectedTimeDiffInSeconds = 20;

class FcmHandler {
  FcmHandler._();
  static final FcmHandler instance = FcmHandler._();

  static final _serviceAccessFile = './lib/src/service_account.json';

  static Future<Map<String, dynamic>> readAccountFile() {
    try {
      final String jsonString = File(_serviceAccessFile).readAsStringSync();
      return Future.value(jsonDecode(jsonString));
    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  Future<String> createAccessToken() async {
    return await readAccountFile().then((json) {
      final String clientEmail = json['client_email'];
      final String tokenURI = json['token_uri'];
      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 -
          maxExpectedTimeDiffInSeconds;
      final jwtHeader = {"alg": "RS256", "typ": "JWT"};
      final jwtHeaderBase64 =
          base64UrlEncode(utf8.encode(jsonEncode(jwtHeader)));
      final jwtClaimSet = {
        "iss": clientEmail,
        "scope": "https://www.googleapis.com/auth/cloud-platform",
        "aud": tokenURI,
        "exp": timestamp + 3600,
        "iat": timestamp,
        if (json['impersonated_user'] != null) "sub": json['impersonated_user'],
      };
      final jwtClaimSetBase64 =
          base64UrlEncode(utf8.encode(jsonEncode(jwtClaimSet)));
      final jwtSignatureInput = '$jwtHeaderBase64.$jwtClaimSetBase64';
      final jwtSignatureInputInBytes = utf8.encode(jwtSignatureInput);

      final String jwtSignature = base64UrlEncode(utf8.encode('''
        $jwtSignatureInputInBytes
      '''));
      final String jwtToken = '$jwtSignatureInput.$jwtSignature';

      return jwtToken;
    }).onError((e, stack) {
      print('Error creating access token: $e');
      return '';
    });
  }

  Future<void> sendNotification(final String deviceToken) async {
    // Send notification
    return await readAccountFile().then((json) async {
      final String accessToken = await createAccessToken();
      final String fcmUrl =
          'https://fcm.googleapis.com/v1/projects/${json['project_id']}/messages:send';
      final String fcmMessage = '''
        {
          "message": {
            "notification": {
              "title": "FCM Message",
              "body": "This is a message from FCM"
            },
            "data": {
            "large-icon": "https://sales.made-in-bd.net/Files/Employee/2023-11-22/1700634592719e45464e4c0454db3bcab92927fe6bf05.JPEG",
            "image": "https://cdn.pixabay.com/photo/2014/06/03/19/38/board-361516_960_720.jpg",
            "category": "leave",
            "type": "accepted",
            "title": "Only ABCD ",
            "body": "Nothing-forground",
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "ticket-id" null
          },
            "token": "$deviceToken"
          }
        }
      ''';
      // log('')
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.postUrl(Uri.parse(fcmUrl));
      request.headers.set('Authorization', 'Bearer $accessToken');
      request.headers.set('Content-Type', 'application/json');
      request.write(fcmMessage);
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      print('Response: $responseBody');
    }).onError((e, stack) {
      print('Error sending notification: $e');
    });
  }

  Future<AccessCredentials> obtainCredentials() async {
    final Map<String, dynamic> json = await readAccountFile();
    var accountCredentials = ServiceAccountCredentials.fromJson({
      "private_key_id": json['private_key_id'],
      "private_key": json['private_key'],
      "client_email": json['client_email'],
      "client_id": json['client_id'],
      "type": "service_account"
    });
    final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
    var client = http.Client();
    AccessCredentials credentials =
        await obtainAccessCredentialsViaServiceAccount(
            accountCredentials, scopes, client);

    client.close();
    print(
        "Oauth2 Credential -------------\n${credentials.toJson()}\n---------------------");
    return credentials;
  }

  Future<void> sendOTP() async {
    final credential = await obtainCredentials();

    final client = http.Client();
    final response = await client.post(
      Uri.parse(
          'https://fcm.googleapis.com/v1/projects/hr-portal-e8a8c/messages:send'),
      headers: {
        'Authorization': 'Bearer ${credential.accessToken.data}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': {
          'notification': {
            'title': 'OTP',
            'body': 'Your OTP is 123456',
          },
          'data': {
            'category': 'leave',
            'type': 'accepted',
            'title': 'Only ABCD ',
            'body': 'Nothing-forground',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'ticket-id': null
          },
          'token':
              'cNGXU81nSG6AMb8YYj1Ny4:APA91bGZpAgw_gp6bl6kfgN4wIxCZLROt1duQiv-B43X5ggev1OBFuG59r6UpLOwvWm5ubq27DM5ehPq5-Ykhvf3VbpiMGZk6wae25oG1mqVMw-5Bhv5Xo14DJ3_SaR2V1DhLVowMou9',
        },
      }),
    );

    print(response.body);
    client.close();
  }
}



/*
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.ICAgICAgICB7CiAgICAgICAgICAiaXNzIjogImZpcmViYXNlLWFkbWluc2RrLW9naTlsQGhyLXBvcnRhbC1lOGE4Yy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsCiAgICAgICAgICAic2NvcGUiOiAiaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jb2x1ZC1wbGF0Zm9ybSBodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2ZpcmViYXNlLm1lc3NhZ2luZyIsCiAgICAgICAgICAiYXVkIjogaHR0cHM6Ly9vYXV0aDIuZ29vZ2xlYXBpcy5jb20vdG9rZW4sCiAgICAgICAgICAiZXhwIjogMTcyNDg0NTY4OSwKICAgICAgICAgICJpYXQiOiAxNzI0NzU5Mjg5CiAgICAgICAgfQogICAgICA=.ICAgICAgICBleUpoYkdjaU9pSlNVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuSUNBZ0lDQWdJQ0I3Q2lBZ0lDQWdJQ0FnSUNBaWFYTnpJam9nSW1acGNtVmlZWE5sTFdGa2JXbHVjMlJyTFc5bmFUbHNRR2h5TFhCdmNuUmhiQzFsT0dFNFl5NXBZVzB1WjNObGNuWnBZMlZoWTJOdmRXNTBMbU52YlNJc0NpQWdJQ0FnSUNBZ0lDQWljMk52Y0dVaU9pQWlhSFIwY0hNNkx5OTNkM2N1WjI5dloyeGxZWEJwY3k1amIyMHZZWFYwYUM5amIyeDFaQzF3YkdGMFptOXliU0JvZEhSd2N6b3ZMM2QzZHk1bmIyOW5iR1ZoY0dsekxtTnZiUzloZFhSb0wyWnBjbVZpWVhObExtMWxjM05oWjJsdVp5SXNDaUFnSUNBZ0lDQWdJQ0FpWVhWa0lqb2dhSFIwY0hNNkx5OXZZWFYwYURJdVoyOXZaMnhsWVhCcGN5NWpiMjB2ZEc5clpXNHNDaUFnSUNBZ0lDQWdJQ0FpWlhod0lqb2dNVGN5TkRnME5UWTRPU3dLSUNBZ0lDQWdJQ0FnSUNKcFlYUWlPaUF4TnpJME56VTVNamc1Q2lBZ0lDQWdJQ0FnZlFvZ0lDQWdJQ0E9CiAgICAgIA==
*/