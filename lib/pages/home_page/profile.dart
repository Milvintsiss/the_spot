import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/deleteUser.dart';
import 'package:the_spot/services/library/UserProfile.dart';
import 'package:the_spot/services/library/configuration.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/services/library/library.dart';

import '../../theme.dart';

class Profile extends StatefulWidget {
  const Profile(
      {Key key,
      this.auth,
      this.userProfile,
      this.configuration,
      this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final UserProfile userProfile;
  final Configuration configuration;
  final VoidCallback logoutCallback;

  @override
  _Profile createState() => _Profile();
}

class _Profile extends State<Profile> {
  bool isUser;

  @override
  void initState() {
    super.initState();

    if (widget.userProfile.userId == widget.configuration.userData.userId)
      isUser = true;
    else
      isUser = false;
  }

  void signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
      appBar: showAppBar(),
      endDrawer: showDrawer(),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    showAvatarWidget(),
                    showProfileWidget(),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  AppBar showAppBar() {
    if (isUser)
      return AppBar(actions: <Widget>[
        Builder(builder: (BuildContext context) {
          return IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        }),
      ]);
    else
      return AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      );
  }

  Drawer showDrawer() {
    if (isUser)
      return Drawer(
        child: Container(
          color: PrimaryColorDark,
          child: ListView(
            children: <Widget>[
              showTopDrawer(),
              showListTileButton("Edit my Profile", Icons.edit),
              showListTileButton('Clear cache', Icons.phonelink_erase),
              showListTileButton('SignOut', Icons.power_settings_new),
              showListTileButton('Delete my account', Icons.delete_forever),
              showListTileButton('App info', Icons.info_outline),
            ],
          ),
        ),
      );
    else
      return null;
  }

  Widget showTopDrawer() {
    return Container(
      color: PrimaryColor,
      height: 55,
      child: ListTile(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: 28, color: SecondaryColorDark),
        ),
        leading: Icon(
          Icons.settings,
          size: 40,
        ),
      ),
    );
  }

  Widget showListTileButton(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
                color: PrimaryColor, width: 2, style: BorderStyle.solid),
            borderRadius: BorderRadius.all(Radius.circular(30))),
        child: ListTile(
          title: Text(
            text,
            style: TextStyle(color: PrimaryColorLight),
          ),
          leading: Icon(
            icon,
            color: PrimaryColorLight,
          ),
          onTap: () async {
            switch (text) {
              case 'Edit my Profile':
                {
                  widget.userProfile.pseudo = 'new';
                  Navigator.pop(context);
                }
                break;
              case 'Clear cache':
                {
                  await DefaultCacheManager().emptyCache();
                  Navigator.pop(context);
                }
                break;
              case 'SignOut':
                signOut();
                break;
              case 'Delete my account':
                DeleteUser(widget.auth, widget.userProfile.userId,
                        widget.logoutCallback, context)
                    .showDeleteUserDataConfirmDialog();
                break;
              case 'App info':
                Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Widget showAvatarWidget() {
    return Hero(
      tag: widget.userProfile.userId,
      child: GestureDetector(
        onTap: isUser ? uploadAvatar : null,
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Stack(overflow: Overflow.visible, children: <Widget>[
              ProfilePicture(widget.userProfile.profilePictureDownloadPath,
                  size: 180, borderColor: PrimaryColor),
              isUser
                  ? Positioned(
                      bottom: -7.5,
                      right: -7.5,
                      child: Icon(
                        Icons.add_circle,
                        size: 60,
                        color: SecondaryColor,
                      ))
                  : Container(),
            ])),
      ),
    );
  }

  Widget showProfileWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: PrimaryColorLight,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            border: Border.fromBorderSide(
                BorderSide(color: PrimaryColor, width: 3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            showPseudoWidget(),
            showUsernameWidget(),
          ],
        ),
      ),
    );
  }

  Widget showPseudoWidget() {
    return RichText(
      text: TextSpan(
          style:
              TextStyle(color: PrimaryColorDark, fontWeight: FontWeight.bold),
          children: <TextSpan>[
            TextSpan(
              text: 'Pseudo: ',
            ),
            TextSpan(
                text: widget.userProfile.pseudo,
                style: TextStyle(color: SecondaryColor))
          ]),
    );
  }

  Widget showUsernameWidget() {
    return RichText(
      text: TextSpan(
          style: TextStyle(color: PrimaryColorDark),
          children: <TextSpan>[
            TextSpan(
                text: 'Username: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                )),
            TextSpan(
                text: "@" + widget.userProfile.username,
                style: TextStyle(fontStyle: FontStyle.italic))
          ]),
    );
  }

  void uploadAvatar() async {
    print("add an Avatar");
    await Storage().getPhotoFromUserStorageAndUpload(
      storageRef: "ProfilePictures/" + widget.userProfile.userId,
      context: context,
      cropStyle: CropStyle.circle,
      cropAspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      maxHeight: 150,
      maxWidth: 150,
      compressQuality: 75,
    );

    String profilePictureDownloadPath = await Storage()
        .getUrlPhoto("ProfilePictures/" + widget.userProfile.userId);

    await Database().updateProfile(context, widget.userProfile.userId,
        profilePictureDownloadPath: profilePictureDownloadPath);

    setState(() {
      widget.userProfile.profilePictureDownloadPath =
          profilePictureDownloadPath;
    });
  }
}
