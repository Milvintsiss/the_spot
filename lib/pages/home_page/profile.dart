

import 'package:flutter/material.dart';
import 'package:the_spot/services/authentication.dart';

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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          showLogoutButton(),
        ],
      ),
    );

  }

  Widget showLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
            border: Border.all(
                color: PrimaryColor, width: 2, style: BorderStyle.solid),
            borderRadius: BorderRadius.all(Radius.circular(30))),
        child: ListTile(
          title: Text("SignOut", style: TextStyle(color: PrimaryColorLight),),
          leading: Icon(
            Icons.power_settings_new,
            color: PrimaryColorLight,
          ),
          onTap: signOut,
        ),
      ),
    );
  }

}