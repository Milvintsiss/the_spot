import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/deleteUser.dart';
import 'package:the_spot/services/library/UserProfile.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/services/library/library.dart';

import '../../theme.dart';

class Profile extends StatefulWidget {
  Profile({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  _Profile createState() => _Profile();
}

class _Profile extends State<Profile> {
  UserProfile userProfile = UserProfile();

  void signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  void loadProfileDataFromDatabase() async {
    userProfile = await Database().getProfileData(widget.userId, context);

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    loadProfileDataFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
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
                showLogoutButton(),
                showDeleteMyDataButton(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget showAvatarWidget() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: uploadAvatar,
      child: Padding(
          padding: EdgeInsets.fromLTRB(0, 40, 0, 0),
          child: Stack(overflow: Overflow.visible, children: <Widget>[
            ProfilePicture(userProfile.profilePictureDownloadPath, size: 180, borderColor: PrimaryColor),
            Positioned(
                bottom: -7.5,
                right: -7.5,
                child: Icon(
                  Icons.add_circle,
                  size: 60,
                  color: SecondaryColor,
                ))
          ])),
    );
  }

  Widget showProfileWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: PrimaryColorLight,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            border: Border.fromBorderSide(
                BorderSide(color: PrimaryColor, width: 3))),
        child: Column(
          children: <Widget>[
            showUsernameWidget(),
            showPseudoWidget(),
          ],
        ),
      ),
    );
  }

  Widget showUsernameWidget() {
    return RichText(
      text: TextSpan(
          style: TextStyle(color: PrimaryColorDark),
          children: <TextSpan>[
            TextSpan(
                text: 'Username: ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: userProfile.username != null
                    ? userProfile.username
                    : "loading...")
          ]),
    );
  }

  Widget showPseudoWidget() {
    return RichText(
      text: TextSpan(
          style: TextStyle(color: PrimaryColorDark),
          children: <TextSpan>[
            TextSpan(
                text: 'Pseudo: ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: userProfile.pseudo != null
                    ? userProfile.pseudo
                    : "loading...")
          ]),
    );
  }

  Widget showLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
            border: Border.all(
                color: PrimaryColor, width: 2, style: BorderStyle.solid),
            borderRadius: BorderRadius.all(Radius.circular(30))),
        child: ListTile(
          title: Text(
            "SignOut",
            style: TextStyle(color: PrimaryColorLight),
          ),
          leading: Icon(
            Icons.power_settings_new,
            color: PrimaryColorLight,
          ),
          onTap: signOut,
        ),
      ),
    );
  }

  Widget showDeleteMyDataButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
            border: Border.all(
                color: PrimaryColor, width: 2, style: BorderStyle.solid),
            borderRadius: BorderRadius.all(Radius.circular(30))),
        child: ListTile(
          title: Text(
            "Delete my account",
            style: TextStyle(color: PrimaryColorLight),
          ),
          leading: Icon(
            Icons.delete_forever,
            color: PrimaryColorLight,
          ),
          onTap: () => DeleteUser(
                  widget.auth, widget.userId, widget.logoutCallback, context)
              .showDeleteUserDataConfirmDialog(),
        ),
      ),
    );
  }

  void uploadAvatar() async {
    print("add an Avatar");
    await Storage().getPhotoFromUserStorageAndUpload(
      storageRef: "ProfilePictures/" + widget.userId,
      context: context,
      cropStyle: CropStyle.circle,
      cropAspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      maxHeight: 150,
      maxWidth: 150,
      compressQuality: 75,
    );

    String profilePictureDownloadPath =
        await Storage().getUrlPhoto("ProfilePictures/" + widget.userId);

    await Database().updateProfile(context, widget.userId,
        profilePictureDownloadPath: profilePictureDownloadPath);

    setState(() {
      userProfile.profilePictureDownloadPath = profilePictureDownloadPath;
    });
  }
}
