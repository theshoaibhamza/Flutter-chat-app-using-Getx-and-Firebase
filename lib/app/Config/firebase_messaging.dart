import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

String? token;
void configureMessagingPermissions() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    // Ask user permission (important for iOS + Android 13+)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    if (Platform.isIOS) {
      token = await messaging.getAPNSToken();
      print("APNS : " + token.toString());
    } else {
      // Get token
      token = await messaging.getToken();
      print("FCM Token: $token");
    }

    // Save this token to Firestore under the current user
  } catch (e) {
    print("Error : " + e.toString());
  }
}

Future<void> sendPushMessage(
  String token,
  String body,
  String title,
  String userId,
) async {
  try {
    String accessToken = await AccessTokenFirebase.getAccessToken();

    print("Your Access Token : " + accessToken);

    final response = await http.post(
      Uri.parse(
        "https://fcm.googleapis.com/v1/projects/mychatapp-f9186/messages:send",
      ),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken", // OAuth2 token
      },
      body: jsonEncode({
        "message": {
          "token": token, // ✅ correct place for device token
          "notification": {"title": title, "body": body},
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "userId": userId,
          },
        },
      }),
    );

    if (response.statusCode == 200) {
      print("Notification Sent Successfully");
    } else {
      print("FCM request failed: ${response.statusCode}");
      print("Response body: ${response.body}");
    }
  } catch (e) {
    print("Error sending push notification: $e");
  }
}

class AccessTokenFirebase {
  static String firebaseMessagingScope =
      "https://www.googleapis.com/auth/firebase.messaging";

  static Future<String> getAccessToken() async {
    try {
      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson({
          "type": "service_account",
          "project_id": "mychatapp-f9186",
          "private_key_id": "d1c3cc6a5d69188f7e5ce4d9db29b25a4a26aad5",
          "private_key":
              "-----BEGIN PRIVATE KEY-----\nMIIEuwIBADANBgkqhkiG9w0BAQEFAASCBKUwggShAgEAAoIBAQDbenzubkfpF8b/\nAXPzr27hwRfXmtttxAH2Okz4V/OGpCMA3mpzCg/ENJ1mja0Bnp5Df0wkQYM7acrB\nhpdE+XUgk1Qy0+yARjYFTN2aPog/0TxLkRxClNhkMXzg1nMb6vF8PlEpdBWDJB7F\nflYlZ9JnQWCB8N90XziBypf3ihcbRGDYFfAj+rr7wimCNBqG9tmCyfj5c6UI+eAA\nDgc3EBjliNv453JMjfhjj5k9raUZQ1adYQu++NUa9fnuSsqojHY8J3b8dV2gxTYa\nP8+DQBO6AOBOoaDaThofyYgvs3SnBfL089OYWch4rRQHZSl+zKF9T+Aw2ebD5j5L\nduz9KHTDAgMBAAECgf9/syxQIvtp4hUUISNBcGIgCNqIB6bWKowzeeHKzu4QEj7P\nshVewSU5vbXn4PJQ4gXxijRDNrG1DWla5ktXVoNwz7Nrvm8KM55LXmnDMAIvUQ6n\nGrKtZZKCRdVnHZENqTYJ91EIE7iBFSxerBb3pGRojp1SJuCjPGDy4Z9QSy2icNTJ\nZO5MTnhhIHuJVy1wOK2f0HlpMninlHqzmpzSMNf2b10oKAuqnwI8obNrxILuSPl9\nMlmpymyhgf7iojEmbPS/xi6DBV2evu4//8N9RcUAIMqXV9Sxd7bQ2ee8RVLSEoe4\nRbAB3Tqg8QM5g9nlxWUqL3RTFKNgdLz318NQVGECgYEA8fj74PWoRQTL7Jujel/x\nNDgOOpE6Wh7JoUwi9kIpnog4MSDGdV7YPyzaKwcqkiBxmCs/xbfxClDkDe4SiXzY\n8mx0YtNK/l4Ehg+1amDiZ0h8ilsYdxhd6WENUt9U73D+D8p+991IVC31nSW5EKDm\n8WKvMz7w7sliI9Hrved0L+ECgYEA6DOtkzBMUSMXrzeJN3+8SmJPBTv22spG6XoW\nqFRK0iQ7EPKfYPjC1tBfU5Dvd4/Nje9TskSMunVAKgeCjThHP+2aP8XaxmN3JAgO\nPRkLiTZmAbg0TkI3HtJVEWfLqoEqkqlzoay0BIjZu9eXApA1PfMnVOMhVVTq3DvW\nRSF3CSMCgYA620pBFN/iMeF8YvsnuBCOmBf17P9ZjmWTA1b5uWwwMIgigwti3zgQ\nXdOPZcXYF2YqElMHv880qCpgrQj7Qk/u36yLoUN7jdjh1w5Ums5XOw14BeJ0jYvC\nSaYZA1PAjiZuJt4tYjjGqQs2N0fFoK2sB0oAWA34tylU9ym1XognYQKBgCboCcxg\nyljJ/XzxXD99WqpIAJ+K5ZjRTcJvH37C6Op/AZqcXJId/F+L+H0DCuzInpOKp0Z2\nb/IKFV81dO1+oYmXoUHQQBD/t4XFB8W6/ZDXGY5uM+1s8NlsOq646oo+LEj4tZRA\nYMVlvL3ZqMbYLOOda1iw2fP3T4bpS8S3j79rAoGBAJMzsF8+W3HdPwZZrACS6zPM\nKIJziVLljJSPlGJrThAYI28PY5lePfDi21D0TX4QSzh5PYoP0SrzVkZxmpZtjNj6\nC9iItxiLFfsG2iOf+XOrJfWWHHow3VPEVU7CYpgIoVf1/X5MdTRjTtE10UQ0tMKk\ngsHpBUHf5ADxvG8LlrJT\n-----END PRIVATE KEY-----\n",
          "client_email":
              "firebase-adminsdk-fbsvc@mychatapp-f9186.iam.gserviceaccount.com",
          "client_id": "109498091723269948879",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url":
              "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url":
              "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40mychatapp-f9186.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com",
        }),
        [firebaseMessagingScope],
      );
      final accessToken = client.credentials.accessToken.data;
      return accessToken;
    } catch (e) {
      print("Exception : " + e.toString());
      return "Exception " + e.toString();
    }
  }
}
