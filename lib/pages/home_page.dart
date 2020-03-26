import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_spot/pages/home_page/feature_not_available.dart';
import 'package:the_spot/services/authentication.dart';
import 'dart:async';
import 'file:///C:/Users/plest/StudioProjects/the_spot/lib/pages/home_page/Map/map.dart';
import 'package:the_spot/pages/home_page/profile.dart';

import '../theme.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 3;
  List<Widget> _children;

  @override
  void initState() {
    super.initState();
    _children = [
      FeatureNotAvailable(),
      FeatureNotAvailable(),
      FeatureNotAvailable(),
      Map(userId: widget.userId, context: context,),
      Profile(auth: widget.auth, userId: widget.userId, logoutCallback: widget.logoutCallback,)
    ];
  }

  void signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget showListTile(String title, IconData icon, String function) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
            border: Border.all(
                color: PrimaryColor, width: 2, style: BorderStyle.solid),
            borderRadius: BorderRadius.all(Radius.circular(30))),
        child: ListTile(
          title: Text(title),
          leading: Icon(
            icon,
            color: PrimaryColorLight,
          ),
          onTap: () {
            switch (function) {
              case "logout":
                signOut();
                break;
              case "updateCotes":
                break;
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: PrimaryColorDark,
          padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
          child: ListView(
            children: <Widget>[
              showListTile("Deconnexion", Icons.power_settings_new, "logout"),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          backgroundColor: PrimaryColor,
          selectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              title: Text("Messages"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.short_text),
              title: Text("News"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text("Home"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              title: Text("Map"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              title: Text("Profile")
            )
          ]),

      body: _children[_currentIndex],//build the corresponding page
    );
  }
}
