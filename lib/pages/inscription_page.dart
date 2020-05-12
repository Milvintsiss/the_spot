import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/root_page.dart';
import 'package:the_spot/services/library/configuration.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/theme.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/services/database.dart';
import 'package:vibrate/vibrate.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({Key key, this.auth, this.userId, this.configuration})
      : super(key: key);

  final BaseAuth auth;
  final String userId;

  final Configuration configuration;

  @override
  _InscriptionPage createState() => _InscriptionPage();
}

class _InscriptionPage extends State<InscriptionPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  String _username;
  String _pseudo;
  bool _BMX = false;
  bool _Skateboard = false;
  bool _Scooter = false;
  bool _Roller = false;

  bool updateProfile;

  @override
  void initState() {
    super.initState();
    if (widget.configuration != null) {
      updateProfile = true;
      _username = widget.configuration.userData.username;
      _pseudo = widget.configuration.userData.pseudo;
      _BMX = widget.configuration.userData.BMX;
      _Skateboard = widget.configuration.userData.Skateboard;
      _Scooter = widget.configuration.userData.Scooter;
      _Roller = widget.configuration.userData.Roller;
    } else
      updateProfile = false;
  }

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
        key: _scaffoldKey,
        appBar: showAppBar(),
        backgroundColor: PrimaryColorDark,
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(30.0, 60.0, 30.0, 0.0),
            children: <Widget>[
              showUsernameInput(),
              showPseudoInput(),
              showPracticesButtons(),
              showNextButton(),
            ],
          ),
        ));
  }

  AppBar showAppBar() {
    if (updateProfile)
      return AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      );
    else
      return null;
  }

  Widget showUsernameInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: 1,
        autofocus: false,
        initialValue:
            updateProfile ? widget.configuration.userData.username : null,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).translate('Username'),
          hintStyle: TextStyle(color: Colors.blueGrey[100]),
          fillColor: PrimaryColorLight,
          filled: true,
          contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        validator: (String str) {
          if (str.isEmpty) {
            return AppLocalizations.of(context)
                .translate('Username can t be empty');
          } else if (str.length > 20) {
            return AppLocalizations.of(context)
                .translate('Your username must not exceed 20 characters!');
          } else {
            return null;
          }
        },
        onSaved: (String str) {
          _username = str.trim();
        },
      ),
    );
  }

  Widget showPseudoInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: 1,
        autofocus: false,
        initialValue:
            updateProfile ? widget.configuration.userData.pseudo : null,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).translate('Pseudo'),
          hintStyle: TextStyle(color: Colors.blueGrey[100]),
          fillColor: PrimaryColorLight,
          filled: true,
          contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        validator: (String str) {
          if (str.isEmpty) {
            return AppLocalizations.of(context)
                .translate('Pseudo can t be empty');
          } else if (str.length > 20) {
            return AppLocalizations.of(context)
                .translate('Your Pseudo must not exceed 20 characters!');
          } else {
            return null;
          }
        },
        onSaved: (String str) {
          _pseudo = str.trim();
        },
      ),
    );
  }

  Widget showPracticesButtons() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
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
              child: ListView(
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
              borderRadius: BorderRadius.circular(14.0),
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
    return Hero(
      tag: 'nextButton',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 20.0),
        child: SizedBox(
          height: 40.0,
          child: RaisedButton(
              elevation: 5.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              color: SecondaryColor,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    updateProfile
                        ? AppLocalizations.of(context).translate('Update')
                        : AppLocalizations.of(context).translate('Next'),
                    style: TextStyle(fontSize: 15.0, color: Colors.white),
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
              onPressed: () async {
                if (validateAndSave()) {
                  bool isUserUsername = false;
                  if(updateProfile){
                    isUserUsername = _username == widget.configuration.userData.username;
                  }
                  if (await Database().isUsernameAlreadyInUse(
                          context: context, username: _username) &&
                      !isUserUsername) {
                    Vibrate.feedback(FeedbackType.warning);
                    FlushbarHelper.createError(
                        message: AppLocalizations.of(context)
                            .translate('Sorry, username \"$_username\" is already used.'),
                        duration: Duration(milliseconds: 4000)).show(context);
                  } else {
                    bool databaseUpdated = await Database().updateProfile(
                        context,
                        updateProfile
                            ? widget.configuration.userData.userId
                            : widget.userId,
                        username: _username,
                        pseudo: _pseudo,
                        BMX: _BMX,
                        Roller: _Roller,
                        Scooter: _Scooter,
                        Skateboard: _Skateboard,
                        onCreate: !updateProfile);
                    if (databaseUpdated) {
                      print("Profile updated with success");
                      if (updateProfile) {
                        widget.configuration.userData.username = _username;
                        widget.configuration.userData.pseudo = _pseudo;
                        widget.configuration.userData.BMX = _BMX;
                        widget.configuration.userData.Skateboard = _Skateboard;
                        widget.configuration.userData.Scooter = _Scooter;
                        widget.configuration.userData.Roller = _Roller;
                        Navigator.pop(context);
                      } else
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    InscriptionPage_AddProfilePicture(
                                      auth: widget.auth,
                                      userId: widget.userId,
                                    )));
                    } else {
                      Vibrate.feedback(FeedbackType.warning);
                      print("Error when updating the Profile...");
                    }
                  }
                }
              }),
        ),
      ),
    );
  }
}

class InscriptionPage_AddProfilePicture extends StatefulWidget {
  const InscriptionPage_AddProfilePicture({Key key, this.auth, this.userId})
      : super(key: key);

  final BaseAuth auth;
  final String userId;

  @override
  _InscriptionPage_AddProfilePicture createState() =>
      _InscriptionPage_AddProfilePicture();
}

class _InscriptionPage_AddProfilePicture
    extends State<InscriptionPage_AddProfilePicture> {
  String _profilePictureDownloadPath;

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
      _profilePictureDownloadPath = profilePictureDownloadPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            children: <Widget>[
              showProfilePictureWidget(),
              showTextAddAPictureWidget(),
            ],
          ),
          showNextButtonWidget(),
        ],
      ),
    );
  }

  Widget showProfilePictureWidget() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: uploadAvatar,
      child: Padding(
          padding: EdgeInsets.fromLTRB(0, 60, 0, 0),
          child: Stack(overflow: Overflow.visible, children: <Widget>[
            ProfilePicture(_profilePictureDownloadPath,
                size: 250, borderColor: PrimaryColor),
            Positioned(
                bottom: -15,
                right: -15,
                child: Icon(
                  Icons.add_circle,
                  size: 100,
                  color: SecondaryColor,
                ))
          ])),
    );
  }

  Widget showTextAddAPictureWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Text(
          "Adding a photo makes you more recognizable!",
          style: TextStyle(
            fontSize: 24,
            color: PrimaryColorLight,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget showNextButtonWidget() {
    return Hero(
      tag: 'nextButton',
      child: Padding(
        padding: EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 20.0),
        child: SizedBox(
          height: 40.0,
          child: RaisedButton(
              elevation: 5.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              color: SecondaryColor,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).translate('Next'),
                    style: TextStyle(fontSize: 15.0, color: Colors.white),
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
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RootPage(
                            auth: widget.auth,
                          )))),
        ),
      ),
    );
  }
}
