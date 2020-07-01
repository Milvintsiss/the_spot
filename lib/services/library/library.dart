import 'dart:io';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/profile_pages/profile.dart';
import 'package:the_spot/services/library/profilePictureWidget.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/theme.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:the_spot/services/library/chatGroup.dart';
import 'package:the_spot/pages/chat_pages/chat_page.dart';

import '../database.dart';



Flushbar friendRequestInAppNotification(
    BuildContext context,
{Configuration configuration,
    String userPseudo,
    String userPictureDownloadPath,
    String userPictureHash,
    String userId}) {
  return Flushbar(
    messageText: Text(
      userPseudo + AppLocalizations.of(context).translate(" wants to add you as friend!"),
      style: TextStyle(color: PrimaryColorLight),
    ),
    backgroundColor: PrimaryColorDark,
    icon: Hero(
      tag: userId,
      child: ProfilePicture(downloadUrl: userPictureDownloadPath, hash: userPictureHash,
          size: 41, borderColor: PrimaryColorLight, borderSize: 1),
    ),
    borderRadius: 100,
    borderColor: PrimaryColorLight,
    borderWidth: 1,
    flushbarPosition: FlushbarPosition.TOP,
    isDismissible: true,
    dismissDirection: FlushbarDismissDirection.HORIZONTAL,
    duration: Duration(seconds: 6),
    mainButton: FlatButton(
      child: Text(AppLocalizations.of(context).translate("Accept")),
      onPressed: () async {
        Database().acceptFriendRequest(
            context, configuration.userData.userId, userId);
        Navigator.pop(context);
      },
    ),
    onTap: (flushbar) async {
      UserProfile user = await Database().getProfileData(userId, context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Profile(
                userProfile: user,
                configuration: configuration,
              )));
    },
  );
}

Flushbar messageInAppNotification(
    BuildContext context,{
    Configuration configuration,
    String senderPseudo,
    String message,
    String chatGroupId,
    String conversationPictureDownloadPath,
    String conversationPictureHash,}) {
  return Flushbar(
    messageText: Text(
      "$senderPseudo: $message",
      style: TextStyle(color: PrimaryColorLight),
    ),
    backgroundColor: PrimaryColorDark,
    icon: Hero(
      tag: chatGroupId,
      child: ProfilePicture(downloadUrl: conversationPictureDownloadPath, hash: conversationPictureHash,
          size: 41, borderColor: PrimaryColorLight, borderSize: 1, isAnUser: false),
    ),
    borderRadius: 100,
    borderColor: PrimaryColorLight,
    borderWidth: 1,
    flushbarPosition: FlushbarPosition.TOP,
    isDismissible: true,
    dismissDirection: FlushbarDismissDirection.HORIZONTAL,
    duration: Duration(seconds: 4),
    onTap: (flushbar) async {
      ChatGroup chatGroup = await Database().getGroup(context, groupId: chatGroupId);
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ChatPage(
          chatGroup: chatGroup,
          configuration: configuration,
        )
      ));
    },
  );
}

Map deleteMapNullKeys(Map map, {List<String> exceptions = const []}) {
  map.removeWhere((key, value) => value == null && !exceptions.contains(key));
  return map;
}

Color transparentColor(Color color, int alpha) {
  return Color.fromARGB(alpha, color.red, color.green, color.blue);
}

Future<bool> checkConnection(BuildContext context) async {
  bool hasConnection;

  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      hasConnection = true;
    } else {
      hasConnection = false;
    }
  } on SocketException catch (_) {
    hasConnection = false;
  }
  if (!hasConnection) {
    error(AppLocalizations.of(context).translate('Please connect to internet!'),
        context);
  }
  return hasConnection;
}

void error(String error, BuildContext context,
    {Color backgroundColor = Colors.white,
    TextAlign textAlign = TextAlign.start,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.bold,
    Color textColor = Colors.red}) {
  Vibrate.feedback(FeedbackType.warning);

  AlertDialog errorAlertDialog = new AlertDialog(
      elevation: 0,
      backgroundColor: backgroundColor,
      content: SelectableText(
        error,
        textAlign: textAlign,
        style: TextStyle(
            color: textColor, fontSize: fontSize, fontWeight: fontWeight),
      ));

  showDialog(context: context, child: errorAlertDialog);
}
