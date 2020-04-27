import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/pages/inscription_page.dart';
import 'package:the_spot/pages/login_signup_page.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/pages/home_page.dart';
import 'package:the_spot/services/database.dart';

enum AuthStatus {
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
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  String _userId = "";

  final databaseReference = Firestore.instance;


  bool _inscriptionState = true; // true if inscription no-complete

  @override
  void initState() {
    super.initState();
     verifyIfConnectedAndInscriptionFinished();
  }

  void verifyIfConnectedAndInscriptionFinished () async {
    FirebaseUser user = await widget.auth.getCurrentUser();

    if (user != null) {
      _userId = user.uid;
      var data = await databaseReference.document("users/" + _userId).get();
      if (data.exists) {
        _inscriptionState = false;
      }else {_inscriptionState = true;}
    }

    setState(() {authStatus =
    user == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;});
  }

  void loginCallback() {
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        _userId = user.uid.toString();
      });
    });
    verifyIfConnectedAndInscriptionFinished();
  }

  void logoutCallback() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
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

  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return buildWaitingScreen();
        break;
      case AuthStatus.NOT_LOGGED_IN:
        return LoginSignupPage(
          auth: widget.auth,
          loginCallBack: loginCallback,
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (_userId.length > 0 && _userId != null) {
          if (_inscriptionState) //if inscription complete go to HomePage
            return InscriptionPage(
              userId: _userId,
              auth: widget.auth,
            );
          else {
            return HomePage(
              userId: _userId,
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