import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/services/configuration.dart';
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

          switch (message['data']['type']) {
            case 'friendRequest':
              {
                if (message['data']['mainUserId'] ==
                    configuration.userData.userId) {
                  //send notification only if the user is connected on this device

                  friendRequestInAppNotification(
                          context,
                          configuration: configuration,
                          userPseudo: message['data']['userPseudo'],
                          userPictureDownloadPath: message['data']['mainUserProfilePictureDownloadPath'],
                          userPictureHash: message['data']['mainUserProfilePictureHash'],
                          userId: message['data']['userToAddId'])
                      .show(context);
                }
              }
              break;
            case 'message':
              {
                String usersIds = message['data']['usersIds'];
                List<String> usersTargetedIds = usersIds.split('/');
                usersTargetedIds.removeAt(0);
                if(usersTargetedIds.contains(configuration.userData.userId)){
                  messageInAppNotification(
                    context,
                    configuration: configuration,
                    chatGroupId: message['data']['conversationId'],
                    conversationPictureDownloadPath: message['data']['conversationPictureDownloadPath'],
                    conversationPictureHash: message['data']['conversationPictureHash'],
                    message: message['data']['message'],
                    senderPseudo: message['data']['senderPseudo'],
                  ).show(context);
                }
              }
              break;

          }
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

  void subscribeToTopic(String topic) {
    _firebaseMessaging.subscribeToTopic(topic);
  }

  void unsubscribeFromTopic(String topic) {
    _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<String> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
