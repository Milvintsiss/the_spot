import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/configuration.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/library/usersListView.dart';
import 'package:the_spot/theme.dart';

class FollowersFollowingFriendsPage extends StatefulWidget {
  final Configuration configuration;
  final UserProfile userProfile;
  final String type;

  const FollowersFollowingFriendsPage(
      {Key key, this.configuration, this.userProfile, this.type})
      : super(key: key);

  @override
  _FollowersFollowingFriendsPageState createState() =>
      _FollowersFollowingFriendsPageState();
}

class _FollowersFollowingFriendsPageState
    extends State<FollowersFollowingFriendsPage> {
  bool isWaiting = true;
  List<UserProfile> queryResult = [];
  Timestamp index = Timestamp.now();

  String noResultMessage;
  String appBarTitle;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future init() async {
    print("called");
    switch (widget.type) {
      case "Followers":
        {
          noResultMessage =
              "This user haven't been followed by anyone for the moment.";
          appBarTitle = "Users following " + widget.userProfile.pseudo;

          Map<String, Object> res = await Database().getFollowersOf(
              context,
              widget.configuration.userData.userId,
              widget.userProfile.userId,
              index,
              10);

          queryResult.addAll(res['users']);
          index = res['lastTimestamp'];
          setState(() {
            isWaiting = false;
          });
        }
        break;

      case "Following":
        {
          noResultMessage = "This user doesn't follow anyone for the moment.";
          appBarTitle = "Users followed by " + widget.userProfile.pseudo;

          Map<String, Object> res = await Database().getFollowingOf(
              context,
              widget.configuration.userData.userId,
              widget.userProfile.userId,
              index,
              4);

          index = res['lastTimestamp'];
          setState(() {
            queryResult.addAll(res['users']);
            isWaiting = false;
          });
        }
        break;
      case "Friends":
        {
          noResultMessage = "This user hasn't added friends yet.";
          appBarTitle = "Friends of " + widget.userProfile.pseudo;

          queryResult = await Database().getUsersByIds(
              context, widget.userProfile.friends,
              verifyIfFriendsOrFollowed: true,
              mainUserId: widget.userProfile.userId);
          setState(() {
            isWaiting = false;
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: isWaiting ? Padding(
          padding: EdgeInsets.only(top: widget.configuration.screenWidth / 20),
          child: Center(
            child: CircularProgressIndicator(),
          )): showQueryResultsWidget(),
    );
  }

  Widget showQueryResultsWidget() {
    if (queryResult.length == 0 || queryResult == null)
      return Padding(
        padding: EdgeInsets.only(top: widget.configuration.screenWidth / 20),
        child: Center(child: Text(noResultMessage)),
      );
    else
      return UsersListView(
        configuration: widget.configuration,
        query: queryResult,
        onBottomListReachedCallback: init,
      );
  }
}
