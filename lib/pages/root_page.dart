import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/pages/inscription_page.dart';
import 'package:the_spot/pages/login_signup_page.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/pages/home_page.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/theme.dart';

enum Status {
  UPDATE_AVAILABLE,
  APP_NOT_OPERATIONAL,
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class RootPage extends StatefulWidget {
  RootPage({this.auth});

  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  Status status = Status.NOT_DETERMINED;
  String _userId = "";

  double screenWidth;
  double screenHeight;
  double textSizeFactor;

  final databaseReference = Firestore.instance;

  Configuration configuration = Configuration();

  bool _inscriptionState = true; // true if inscription no-complete

  @override
  void initState() {
    super.initState();

    //init notifications

    getConfiguration();
  }

  void getConfiguration() async {
    FirebaseUser user = await widget.auth.getCurrentUser();
    if (user != null) {
      _userId = user.uid;
    }
    configuration = await Configuration().getConfiguration(context, _userId);
    configuration.setUserProfileListenerAndGetDeviceToken(context, _userId);
    configuration.screenHeight = screenHeight;
    configuration.screenWidth = screenWidth;
    configuration.textSizeFactor = textSizeFactor;

    if (configuration.userData != null) {
      _inscriptionState = false;
      configuration.userData.userId = _userId;
      configuration.pushNotificationsManager.configuration = configuration;
    } else {
      _inscriptionState = true;
    }

    if (configuration.updateIsAvailable)
      status = Status.UPDATE_AVAILABLE;
    else if (!configuration.isApplicationOperational)
      status = Status.APP_NOT_OPERATIONAL;
    else {
      status = user == null ? Status.NOT_LOGGED_IN : Status.LOGGED_IN;
    }
    if (configuration.alertMessage != null &&
        configuration.alertMessage.length > 0) {
      error(configuration.alertMessage, context,
          backgroundColor: PrimaryColorDark,
          textColor: Colors.white,
          textAlign: TextAlign.center);
    }

    setState(() {});
  }

  void loginCallback() {
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        _userId = user.uid.toString();
      });
    });
    getConfiguration();
  }

  void logoutCallback() {
    setState(() {
      status = Status.NOT_LOGGED_IN;
      _userId = null;
    });
  }

  Widget buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget buildUpdateAvailableScreen() {
    return Scaffold(
      body: Center(
          child: Text(
        "A new version of the spot is now available! Please update to keep using TheSpot! ",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      )),
    );
  }

  Widget buildAppNotOperationalScreen() {
    return Scaffold(
      body: Center(
          child: Text(
        "TheSpot is not operational for the moment, we are working on it. Please retry later.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    textSizeFactor = MediaQuery.of(context).textScaleFactor;
    switch (status) {
      case Status.UPDATE_AVAILABLE:
        return buildUpdateAvailableScreen();
        break;
      case Status.APP_NOT_OPERATIONAL:
        return buildAppNotOperationalScreen();
        break;
      case Status.NOT_DETERMINED:
        return buildWaitingScreen();
        break;
      case Status.NOT_LOGGED_IN:
        return LoginSignupPage(
          auth: widget.auth,
          loginCallBack: loginCallback,
        );
        break;
      case Status.LOGGED_IN:
        if (_userId.length > 0 && _userId != null) {
          if (_inscriptionState) //if inscription complete go to HomePage
            return InscriptionPage(
              userId: _userId,
              auth: widget.auth,
            );
          else {
            return HomePage(
              configuration: configuration,
              auth: widget.auth,
              logoutCallback: logoutCallback,
            );
          }
        } else
          return buildWaitingScreen();
        break;
      default:
        return buildWaitingScreen();
    }
  }
}
