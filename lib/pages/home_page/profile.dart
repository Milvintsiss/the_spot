import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/deleteUser.dart';
import 'package:the_spot/services/library/UserProfile.dart';
import 'package:the_spot/services/storage.dart';
import 'package:vibrate/vibrate.dart';

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
  String _avatar;
  String _pseudo = "loading...";

  void signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  void loadAvatarFromDatabase() async {
    final StorageReference storageReference =
        FirebaseStorage().ref().child("ProfilePictures/" + widget.userId);
    _avatar = await storageReference.getDownloadURL();
    setState(() {
      showAvatarWidget();
    });
  }

  void loadProfileDataFromDatabase() async {
    UserProfile userProfile = await Database().getProfileData(widget.userId, context);

    setState(() {
      _pseudo = userProfile.pseudo;
    });
  }

  @override
  void initState() {
    super.initState();

    loadProfileDataFromDatabase();
    loadAvatarFromDatabase();
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
      onTap: loadAvatar,
      child: Padding(
          padding: EdgeInsets.fromLTRB(0, 40, 0, 0),
          child: CircleAvatar(
            backgroundColor: PrimaryColor,
            radius: 85,
            child: CircleAvatar(
              backgroundColor: PrimaryColorLight,
              radius: 80,
              foregroundColor: PrimaryColorDark,
              child: Stack(overflow: Overflow.visible, children: <Widget>[
                _avatar == null
                    ? Icon(
                        Icons.person,
                        size: 100,
                      )
                    : Container(
                        height: 160,
                        width: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(200),
                          child: Image.network(
                            _avatar,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                _avatar == null
                    ? Positioned(
                        bottom: -40,
                        right: -40,
                        child: Icon(
                          Icons.add_circle,
                          size: 60,
                          color: SecondaryColor,
                        ))
                    : Positioned(
                        bottom: -10,
                        right: -10,
                        child: Icon(
                          Icons.add_circle,
                          size: 60,
                          color: SecondaryColor,
                        )),
              ]),
            ),
          )),
    );
  }

  Widget showProfileWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: PrimaryColorLight,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            border: Border.fromBorderSide(
                BorderSide(color: PrimaryColor, width: 3))),
        child: Column(
          children: <Widget>[
            showPseudoWidget(),
          ],
        ),
      ),
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
            TextSpan(text: _pseudo)
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

  void loadAvatar() async {
    print("add an Avatar");
    bool uploadIsSuccessful = await Storage().getPhotoFromUserStorageAndUpload(
        "ProfilePictures/" + widget.userId,
      cropStyle: CropStyle.circle,
      cropAspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      maxHeight: 150,
      maxWidth: 150,
      compressQuality: 75,
    );

    loadAvatarFromDatabase();
  }
}
