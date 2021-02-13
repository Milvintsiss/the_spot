import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:the_spot/pages/profile_pages/profile.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/pages/chat_pages/chat_page.dart';
import 'package:the_spot/services/library/chatGroup.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'dart:math';

import 'database.dart';

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
                  friendRequestInAppNotification(context,
                          configuration: configuration,
                          userPseudo: message['data']['userPseudo'],
                          userPictureDownloadPath: message['data']
                              ['mainUserProfilePictureDownloadPath'],
                          userPictureHash: message['data']
                              ['mainUserProfilePictureHash'],
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
                if (usersTargetedIds.contains(configuration.userData.userId)) {
                  String chatGroupId = message['data']['conversationId'];
                  String conversationName = message['data']['conversationName'];
                  String conversationPictureDownloadPath = message['data']['conversationPictureDownloadPath'];
                  String conversationPictureHash = message['data']['conversationPictureHash'];
                  String _message = message['data']['message'];
                  String senderPseudo = message['data']['senderPseudo'];
                  bool isGroup = conversationName != '%#%NOT_GROUP%#%';


                  //sending in notification tray
                  FlutterLocalNotificationsPlugin
                      flutterLocalNotificationsPlugin =
                      FlutterLocalNotificationsPlugin();
                  var androidPlatformChannelSpecifics =
                      AndroidNotificationDetails(chatGroupId,
                          isGroup ? conversationName : senderPseudo, 'Discussion tray',
                          groupKey: chatGroupId,
                          importance: Importance.Max,
                          priority: Priority.High,
                          ticker: 'ticker');
                  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
                  var platformChannelSpecifics = NotificationDetails(
                      androidPlatformChannelSpecifics,
                      iOSPlatformChannelSpecifics);
                  await flutterLocalNotificationsPlugin.show(
                      0,
                      isGroup ? conversationName : senderPseudo,
                      isGroup ? senderPseudo + ": " + _message : _message, platformChannelSpecifics, payload: {
                    'type': 'message',
                    'message': message,
                    'senderPseudo': senderPseudo,
                    'conversationId': chatGroupId,
                    'conversationName': conversationName,
                    'conversationPictureDownloadPath': conversationPictureDownloadPath,
                    'conversationPictureHash': conversationPictureHash,
                    'usersIds': usersIds,
                  }.toString()
                  );

                  //showing in app notification
                  messageInAppNotification(
                    context,
                    configuration: configuration,
                    chatGroupId: chatGroupId,
                    conversationPictureDownloadPath:
                        conversationPictureDownloadPath,
                    conversationPictureHash: conversationPictureHash,
                    message: _message,
                    senderPseudo: senderPseudo,
                  ).show(context);
                }
              }
              break;
          }
        },
        onLaunch: (Map<String, dynamic> message) async {
          print("onLaunch: $message");
          switch (message['data']['type']) {
            case 'friendRequest':
              {}
              break;
            case 'message':
              {}
              break;
          }
        },
        onResume: (Map<String, dynamic> message) async {
          print("onResume: $message");
          switch (message['data']['type']) {
            case 'friendRequest':
              {
                UserProfile userProfile = (await Database().getUsersByIds(
                    context, [message['data']['userToAddId']],
                    mainUserId: configuration.userData.userId,
                    verifyIfFriendsOrFollowed: true))[0];
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Profile(
                              configuration: configuration,
                              userProfile: userProfile,
                            )));
              }
              break;
            case 'message':
              {
                ChatGroup chatGroup = await Database().getGroup(context,
                    groupId: message['data']['conversationId']);
                if (!chatGroup.isGroup)
                  chatGroup.members = await Database().getUsersByIds(
                      context,
                      [
                        chatGroup.membersIds.firstWhere(
                            (id) => id != configuration.userData.userId)
                      ],
                      mainUserId: configuration.userData.userId,
                      verifyIfFriendsOrFollowed: true);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatPage(
                              chatGroup: chatGroup,
                              configuration: configuration,
                            )));
              }
              break;
          }
        },
        onBackgroundMessage: messageHandle,
      );

      // For testing purposes print the Firebase Messaging token
      String token = await _firebaseMessaging.getToken();
      print("FirebaseMessaging token: $token");
      _initialized = true;
    }
  }

  static Future<dynamic> messageHandle(Map<String, dynamic> message) async {
    print('ok');
    return null;
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
