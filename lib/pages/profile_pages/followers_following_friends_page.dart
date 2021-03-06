import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/library/usersListView.dart';
import 'package:the_spot/theme.dart';
import 'package:after_layout/after_layout.dart';

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
    extends State<FollowersFollowingFriendsPage>
    with AfterLayoutMixin<FollowersFollowingFriendsPage> {
  bool isWaiting = true;
  List<UserProfile> queryResult = [];
  Timestamp index = Timestamp.now();
  int friendsIndex = 0;
  int querySize = 10;

  String noResultMessage = "";
  String appBarTitle = "";

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    switch (widget.type) {
      case "Followers":
        {
          print("ok");
          noResultMessage = AppLocalizations.of(context)
              .translate("This user haven't been followed by anyone yet.");
          appBarTitle =
              AppLocalizations.of(context).translate("Users following ") +
                  widget.userProfile.pseudo;
          setState(() {});
        }
        break;

      case "Following":
        {
          noResultMessage = AppLocalizations.of(context)
              .translate("This user doesn't follow anyone yet.");
          appBarTitle =
              AppLocalizations.of(context).translate("Users followed by ") +
                  widget.userProfile.pseudo;
          setState(() {});
        }
        break;
      case "Friends":
        {
          noResultMessage = AppLocalizations.of(context)
              .translate("This user hasn't added friends yet.");
          appBarTitle = AppLocalizations.of(context).translate("Friends of ") +
              widget.userProfile.pseudo;
          setState(() {});
        }
        break;
    }
  }

  Future init() async {
    switch (widget.type) {
      case "Followers":
        {
          Map<String, Object> res = await Database().getFollowersOf(
              context,
              widget.configuration.userData.userId,
              widget.userProfile.userId,
              index,
              querySize);

          queryResult.addAll(res['users']);
          index = res['lastTimestamp'];
          setState(() {
            isWaiting = false;
          });
        }
        break;

      case "Following":
        {
          Map<String, Object> res = await Database().getFollowingOf(
              context,
              widget.configuration.userData.userId,
              widget.userProfile.userId,
              index,
              querySize);

          index = res['lastTimestamp'];
          setState(() {
            queryResult.addAll(res['users']);
            isWaiting = false;
          });
        }
        break;
      case "Friends":
        {
          List<String> friends = widget.userProfile.friends.reversed.toList();

          if (friendsIndex < friends.length) {
            int range = friendsIndex + querySize > friends.length
                ? friends.length
                : friendsIndex + querySize;

            List<String> query = friends.getRange(friendsIndex, range).toList();

            List<UserProfile> res = await Database().getUsersByIds(
                context, query,
                verifyIfFriendsOrFollowed: true,
                mainUserId: widget.configuration.userData.userId);
            friendsIndex = friendsIndex + querySize;
            setState(() {
              queryResult.addAll(res);
            });
          }
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
      body: showQueryResultsWidget(),
    );
  }

  Widget showQueryResultsWidget() {
    if (isWaiting) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (queryResult.length == 0 || queryResult == null)
      return Padding(
        padding: EdgeInsets.only(top: widget.configuration.screenWidth / 20),
        child: Center(
            child: Text(
          noResultMessage,
          textAlign: TextAlign.center,
        )),
      );
    else
      return Column(
        children: <Widget>[
          UsersListView(
            configuration: widget.configuration,
            query: queryResult,
            onBottomListReachedCallback: init,
          ),
        ],
      );
  }
}
