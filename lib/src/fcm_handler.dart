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

  Future<AccessCredentials> obtainCredentials() async {
    // final Map<String, dynamic> json = await readAccountFile();
    var accountCredentials = ServiceAccountCredentials.fromJson({
      "private_key_id": "44db7dca907d74f09a5bdafba1ac44fafca73402",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCpsTkHL62T5NsK\nB7pMu1lu2eD/tSsnE9ZdYlOqw0xdCpqLGRCM5Jw8Ze/XEVfDPJ5+Hvo7l2Uhkm6Y\n3iwpEJy7PBNC0U1scyCo8cIz8af2pmDj7o+QguTau8RFaZTW2gtqEjseJgcXnKam\n7U3zF+GVzWuC1Ru9fvsa38Xyx1jpCCaZbDYx3cAD7pAVzD9nXSsPKLO6siOYbAMR\nFw6YMvVyZLB8QnU4eJQxBFBMP073Jqqap+Dbo4pzKuj5zpTBWifcMQax+IVuRSvt\nw6SwtvfSNAcqIqh+W6f+X98jdXcLX5iZGDvOk3KMRHaKEyKy4ojOJg4wQFPvU4Z8\nSCNQuQ1pAgMBAAECggEAE2+vowGUhZyQdCknbxOEblx5V4CWRT8R7hdNkwEUlZGZ\n2vXPffvPY2Gfo4gif8PJOZPtwHaaSEqf7VWBRGDZOt7qK9ySXCohowgx4MY8oVU0\nQtc3zWsYsG8ST4sE18kYxpj4+X6MkGlKc1M5+u6Q0Zo6Rr2HFGDffRgFccXgiqxK\n/YGKrS6myPEb8FM96yfs1NTENlXYgRdVhwZGfSNiryBKBVuLie3BvDIreQjAB1n+\nRMl8oaWKBb9rAOkbeqetnPwFJ9yOO9ZsRiiWXok4ILaW+TxaB4DHcS7/ir4/CWJk\nTqs6lE6aupjZm1bqEvD8TlhTPm7RX8Y3JpGA7fd0gQKBgQDdnCDHlrAbySBoY3h/\nS9LDLfboFEzJ1DTn8dkpyOrdENp37VoR/bDbK0ug1iBvWrwkDA/TgBAc/4CsM9OQ\nDoxrxZCk1yJISIylHvIYBLGUpWDZjOvLT3Z8hbBtZUtaDCm8DihpCulvbxeG4Lqg\nJ50ho8az8wailE/rBcH5LqpQyQKBgQDEBpHd/56pnWuDkww+WKA3MBK+FxteM714\nhSIvG5N4fC0HABztko2fEiwsDXcu3V2y0GwuMfJIDBgGo7PUmmoBkbyQcdL6i9s0\n0dMMku9IVnVNGQ0T7LkthNhpjLij9UnkE9y72Gj1PnDqRELs2bUvzca3z6XXqwBe\ntuggtFDHoQKBgFElAweyEIgMDDbM/Wk3HVRkdz0hecCJWFn5v3fCXuVVb3lsSoe9\n6c1GvCmHXlcH1U4psH3ULZJAqB/l1jiwaxBnRgBl2eK31e/8Nc8/oLp6F81xAUHv\ntcYAucpExeOSApIeaQOVgEZSWj4D+bH871dK/c4UVcCgJ+c5s34HbUupAoGAaOG/\nABG52bTBhreR0HXo2z5ceNqyKPf0A1zwSlYt1ERUby9vSumj3p2Bhtx5jVihvn/n\nsdvFbykRXdQO7szjtQ093+cW5DkaQyuVCWBAqOqhfmvN5IA/IAy5IdhKHmeqbl72\nNod2uOj8z0tQp5tgZ0Bpd4WhjUAQRZ0FnCH+KqECgYEA06yqVjcVlkYdfdTOwo1g\nDwajy3cYDyPCSdJAfAw6IdyTxzj6ZGabwk+G5Gt0WjWyazE3yyiJ/56nsKcTavwB\nK7e3f4CrknVPNfHXkV50G0MU2xsWwU3JyOxfmEg2TwkHHLvnhKyVT+uc7J50kE5k\naALWiI9JFxc0WRIrQV5SvLc=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-ogi9l@hr-portal-e8a8c.iam.gserviceaccount.com",
      "client_id": "102030587638583356672",
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

  Future<void> sendOTP({
    required final String deviceToken,
  }) async {
    final credential = await obtainCredentials();
    final serviceURL = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/hr-portal-e8a8c/messages:send');

    final client = http.Client();
    final response = await client.post(
      serviceURL,
      headers: {
        'Authorization': 'Bearer ${credential.accessToken.data}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': {
          'data': {
            'category': 'leave',
            'type': 'accepted',
            'title': 'Only ABCD ',
            'body': 'Nothing-forground',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'ticket-id': null
          },
          // 'topic': "leave",
          "token": deviceToken,
        },
      }),
    );

    print(response.body);
    client.close();
  }
}
