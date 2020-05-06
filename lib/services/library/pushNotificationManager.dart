import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/services/library/configuration.dart';
import 'package:the_spot/services/library/library.dart';

class PushNotificationsManager {
  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance =
      PushNotificationsManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  Configuration configuration;

  Future<void> init(BuildContext context) async {
    if (!_initialized) {
      // For iOS request permission first.
      _firebaseMessaging.requestNotificationPermissions();
      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          print("onMessage: $message");
          friendRequestInAppNotification(context, configuration, message['data']['userPseudo'], message['data']['picturePath'], message['data']['userId']).show(context);
          //TODO better UI for notification
        },
        onLaunch: (Map<String, dynamic> message) async {
          print("onLaunch: $message");
          // TODO optional
        },
        onResume: (Map<String, dynamic> message) async {
          print("onResume: $message");
          // TODO optional
        },
      );

      // For testing purposes print the Firebase Messaging token
      String token = await _firebaseMessaging.getToken();
      print("FirebaseMessaging token: $token");

      _initialized = true;
    }
  }

  void subscribeToTopic(String topic){
    _firebaseMessaging.subscribeToTopic(topic);
  }
  void unsubscribeFromTopic(String topic){
    _firebaseMessaging.unsubscribeFromTopic(topic);
  }
  Future<String> getToken() async {
    return await _firebaseMessaging.getToken();
  }

}
