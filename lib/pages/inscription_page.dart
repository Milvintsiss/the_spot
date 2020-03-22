import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/home_page.dart';
import 'package:the_spot/main.dart';
import 'package:the_spot/pages/root_page.dart';
import 'package:the_spot/theme.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/services/database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibrate/vibrate.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  _InscriptionPage createState() => _InscriptionPage();
}

class _InscriptionPage extends State<InscriptionPage> {
  final _formKey = new GlobalKey<FormState>();

  String _userID;
  String _pseudo;
  String _profilePicturePath;
  bool _BMX = false;
  bool _Skateboard = false;
  bool _Scooter = false;
  bool _Roller = false;

  File _avatar;

  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    Vibrate.feedback(FeedbackType.warning);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: PrimaryColorDark,
        body: ListView(
          padding: EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 0.0),
          children: <Widget>[
            showAvatarWidget(),
            showPseudoInput(),
            showPracticesButtons(),
            showNextButton(),
          ],
        ));
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
                          child: Image.file(
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

  void loadAvatar() async {
    print("add an Avatar");
    _avatar = await ImagePicker.pickImage(source: ImageSource.gallery);

    _avatar = await ImageCropper.cropImage(
        sourcePath: _avatar.path,
        aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        cropStyle: CropStyle.circle,
        maxHeight: 150,
        maxWidth: 150,
        compressQuality: 75,
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Profile Picture',
          toolbarColor: PrimaryColorDark,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: PrimaryColorLight,
          lockAspectRatio: true,
        ),
        iosUiSettings: IOSUiSettings(
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ));

    final StorageReference storageReference =
        FirebaseStorage().ref().child("ProfilePictures/" + widget.userId);
    final StorageUploadTask uploadTask = storageReference.putFile(_avatar);
    await uploadTask.onComplete;

    setState(() {
      showAvatarWidget();
    });
  }

  Widget showPseudoInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
      child: new Form(
        key: _formKey,
        child: new TextFormField(
          style: TextStyle(color: Colors.white),
          maxLines: 1,
          autofocus: false,
          decoration: new InputDecoration(
            hintText: AppLocalizations.of(context).translate('Username'),
            hintStyle: TextStyle(color: Colors.blueGrey[100]),
            fillColor: PrimaryColorLight,
            filled: true,
            contentPadding: new EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
            border: new OutlineInputBorder(
              borderRadius: new BorderRadius.circular(12.0),
            ),
          ),
          validator: (String str) {
            if (str.isEmpty) {
              return AppLocalizations.of(context)
                  .translate('Pseudo can t be empty');
            } else if (str.length > 20) {
              print('Pseudo is too long');
              return AppLocalizations.of(context)
                  .translate('Your Pseudo is too long!');
            } else {
              return null;
            }
          },
          onChanged: (str) {
            validateAndSave();
          },
          onSaved: (String str) {
            _pseudo = str.trim();
          },
        ),
      ),
    );
  }

  Widget showPracticesButtons() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(20.0),
        ),
        color: PrimaryColorLight,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                  color: PrimaryColorDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        AppLocalizations.of(context)
                            .translate('Select your hobby(ies)'),
                        style: TextStyle(
                            color: PrimaryColorLight, fontSize: 17.5)),
                  )),
            ),
            Container(
              height: 90,
              child: new ListView(
                shrinkWrap: false,
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      practiceButton("assets/images/BMX.png"),
                      practiceButton("assets/images/Skateboard.png"),
                      practiceButton("assets/images/Scooter.png"),
                      practiceButton("assets/images/Roller.png")
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget practiceButton(String practice) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: () => onTapPractices(practice),
        child: Material(
          // needed
          shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(14.0),
              side: BorderSide(
                  width: 3,
                  color: practice == "assets/images/Roller.png" && _Roller ||
                          practice == "assets/images/BMX.png" && _BMX ||
                          practice == "assets/images/Skateboard.png" &&
                              _Skateboard ||
                          practice == "assets/images/Scooter.png" && _Scooter
                      ? Colors.white
                      : PrimaryColorDark)),
          color: PrimaryColor,

          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
              practice,
              width: 45,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  void onTapPractices(String practice) {
    switch (practice) {
      case "assets/images/Roller.png":
        _Roller = !_Roller;
        break;
      case "assets/images/BMX.png":
        _BMX = !_BMX;
        break;
      case "assets/images/Skateboard.png":
        _Skateboard = !_Skateboard;
        break;
      case "assets/images/Scooter.png":
        _Scooter = !_Scooter;
        break;
    }
    setState(() {
      practiceButton(practice);
    });
  }

  Widget showNextButton() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 20.0),
      child: SizedBox(
        height: 40.0,
        child: new RaisedButton(
          elevation: 5.0,
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0)),
          color: SecondaryColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Text(
                AppLocalizations.of(context).translate('Next'),
                style: new TextStyle(fontSize: 15.0, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              )
            ],
          ),
          onPressed: () {
            if (validateAndSave()) {
              final _future = Database().updateProfile(context, widget.userId, pseudo: _pseudo,
                 BMX: _BMX, Roller: _Roller, Scooter: _Scooter, Skateboard: _Skateboard, onCreate: true);
              _future.then((databaseUpdated) {
                if (databaseUpdated) {
                  print("Profile updated with success");
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => new RootPage(
                                auth: widget.auth,
                              )));
                } else {
                  Vibrate.feedback(FeedbackType.warning);
                  print("Error when updating the Profile...");
                }
              });
            }
          },
        ),
      ),
    );
  }
}
