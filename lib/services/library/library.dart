import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/home_page/profile.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/theme.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:the_spot/services/library/chatGroup.dart';
import 'package:the_spot/pages/chat_pages/chat_page.dart';

import '../database.dart';

Future<BitmapDescriptor> convertImageFileToBitmapDescriptor(File imageFile,
    {int size = 150,
    bool addBorder = false,
    Color borderColor = Colors.white,
    double borderSize = 10,
    String title,
    Color titleColor = Colors.white,
    Color titleBackgroundColor = Colors.black}) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()..color;
  final TextPainter textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  final double radius = size / 2;

  //make canvas clip path to prevent image drawing over the circle
  final Path clipPath = Path();
  clipPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Radius.circular(1000)));
  clipPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size * 8 / 10, size.toDouble(), size * 2 / 10),
      Radius.circular(100)));
  canvas.clipPath(clipPath);

  if (imageFile == null) {
    //paint Icon background
    paint..color = PrimaryColorLight;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    //paint Person Icon
    final icon = Icons.person;
    TextPainter textPainter = TextPainter(textDirection: TextDirection.rtl);
    textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
            fontSize: size * 4 / 5,
            fontFamily: icon.fontFamily,
            color: PrimaryColorDark));
    textPainter.layout();
    textPainter.paint(canvas, Offset(size * 1 / 10, size * 1 / 10));
  } else {
    //paint Profile Picture
    final Uint8List imageUint8List = await imageFile.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(imageUint8List,
        targetHeight: size, targetWidth: size);
    final ui.FrameInfo imageFI = await codec.getNextFrame();
    paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        image: imageFI.image);
  }
  if (addBorder) {
    //draw Border
    paint..color = borderColor;
    paint..style = PaintingStyle.stroke;
    paint..strokeWidth = borderSize;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
  }

  if (title != null) {
    if (title.length > 9) {
      title = title.substring(0, 9);
    }
    //draw Title background
    paint..color = titleBackgroundColor;
    paint..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, size * 8 / 10, size.toDouble(), size * 2 / 10),
            Radius.circular(100)),
        paint);

    //draw Title
    textPainter.text = TextSpan(
        text: title,
        style: TextStyle(
          fontSize: radius / 2.5,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ));
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(radius - textPainter.width / 2,
            size * 9 / 10 - textPainter.height / 2));
  }

  //convert canvas as PNG bytes
  final _image = await pictureRecorder.endRecording().toImage(size, size);
  final data = await _image.toByteData(format: ui.ImageByteFormat.png);

  //convert PNG bytes as BitmapDescriptor
  return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
}

Widget ProfilePicture(String downloadPath,
    {double size = 50,
    Color borderColor = PrimaryColorDark,
    double borderSize = 2,
    bool isAnUser = true}) {
  if (downloadPath != null && downloadPath != "")
    return SizedBox(
      height: size,
      width: size,
      child: Container(
        padding: EdgeInsets.all(borderSize),
        decoration: BoxDecoration(
          color: borderColor,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
            child: Image.network(
          downloadPath,
          fit: BoxFit.fill,
        )),
      ),
    );
  else
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: PrimaryColor, shape: BoxShape.circle),
      child: Icon(
        isAnUser ? Icons.person : Icons.people,
        size: size / 2,
      ),
    );
}

Widget userItem(
    UserProfile user, double sizeReference, double textSizeReference,
    {bool isDeletable = false,
    VoidCallback deleteCallback,
    Color background = SecondaryColorDark,
    Color pseudoColor = Colors.white70,
    FontWeight pseudoFontWeight = FontWeight.bold,
    double borderSize,
    Color borderColor = SecondaryColorLight}) {
  if (borderSize == null) borderSize = sizeReference / 300;
  return Container(
    padding: EdgeInsets.all(sizeReference / 120),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(sizeReference / 20),
      border: Border.all(width: borderSize, color: borderColor),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfilePicture(user.profilePictureDownloadPath,
            size: sizeReference / 20, borderSize: 0.5),
        Divider(
          indent: sizeReference / 120,
        ),
        Text(
          user.pseudo,
          style: TextStyle(
              color: pseudoColor,
              fontWeight: pseudoFontWeight,
              fontSize: 14 * textSizeReference),
        ),
        isDeletable
            ? SizedBox(
                height: sizeReference / 25,
                width: sizeReference / 25,
                child: IconButton(
                  icon: Icon(
                    Icons.cancel,
                    color: borderColor,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: sizeReference / 25,
                  onPressed: deleteCallback,
                ),
              )
            : Container(),
      ],
    ),
  );
}

Flushbar friendRequestInAppNotification(
    BuildContext context,
{Configuration configuration,
    String userPseudo,
    String userPictureDownloadPath,
    String userId}) {
  return Flushbar(
    messageText: Text(
      userPseudo + AppLocalizations.of(context).translate(" wants to add you as friend!"),
      style: TextStyle(color: PrimaryColorLight),
    ),
    backgroundColor: PrimaryColorDark,
    icon: Hero(
      tag: userId,
      child: ProfilePicture(userPictureDownloadPath,
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
    String conversationPictureDownloadPath,}) {
  return Flushbar(
    messageText: Text(
      "$senderPseudo: $message",
      style: TextStyle(color: PrimaryColorLight),
    ),
    backgroundColor: PrimaryColorDark,
    icon: Hero(
      tag: chatGroupId,
      child: ProfilePicture(conversationPictureDownloadPath,
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
