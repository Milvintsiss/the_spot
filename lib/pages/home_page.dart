import 'package:flutter/material.dart';
import 'package:the_spot/pages/home_page/feature_not_available.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/pages/home_page/Map/map.dart';
import 'package:the_spot/pages/home_page/profile.dart';
import 'package:the_spot/pages/chat_pages/chat_list_page.dart';
import 'package:the_spot/services/configuration.dart';

import '../theme.dart';

class HomePage extends StatefulWidget {
  HomePage(
      {Key key,
      this.initialIndex = 4,
      this.auth,
      this.configuration,
      this.logoutCallback})
      : super(key: key);

  final int initialIndex; //0 chat, 1 news, 2 home, 3 map, 4 profile
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final Configuration configuration;

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex;
  List<Widget> _children;

  @override
  void initState() {
    super.initState();
    widget.configuration.addListener(onUserDataChanged);

    _currentIndex = widget.initialIndex;
    _children = [
      ChatListPage(
        configuration: widget.configuration,
      ),
      FeatureNotAvailable(),
      FeatureNotAvailable(),
      Map(
        configuration: widget.configuration,
        context: context,
      ),
      Profile(
        auth: widget.auth,
        userProfile: widget.configuration.userData,
        configuration: widget.configuration,
        logoutCallback: widget.logoutCallback,
      )
    ];
  }

  void onUserDataChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.configuration.removeListener(onUserDataChanged);
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          backgroundColor: PrimaryColor,
          selectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble),
              title: Text("Chat"),
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
              icon: Stack(children: [
                Center(
                  child: Icon(
                    Icons.person,
                  ),
                ),
                widget.configuration.userData.pendingFriendsId.length > 0
                    ? Positioned(
                        top: 0,
                        right: 15,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.red),
                          child: Center(
                              child: Text(
                            widget
                                .configuration.userData.pendingFriendsId.length
                                .toString(),
                            style: TextStyle(color: Colors.white),
                          )),
                        ),
                      )
                    : Container()
              ]),
              title: Text("Profile"),
            )
          ]),

      body: _children[_currentIndex], //build the corresponding page
    );
  }
}
