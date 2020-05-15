import 'package:flutter/material.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/library/configuration.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/theme.dart';

import 'profile.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage(this.configuration);

  final Configuration configuration;

  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  bool isDataLoaded = false;

  List<UserProfile> queryResult = [];

  List<bool> waiting = [];

  bool noResult = false;

  @override
  void initState() {
    super.initState();
    widget.configuration.addListener(onUserDataChanged);

    getUsersData();
  }

  void onUserDataChanged() async {
    await getUsersData();
    setState(() {});
  }

  @override
  void dispose() {
    widget.configuration.removeListener(onUserDataChanged);
    super.dispose();
  }

  Future getUsersData() async {
    noResult = false;
    print(widget.configuration.userData.pendingFriendsId);
    List<String> pendingFriends = widget.configuration.userData.friends.reversed.toList();
    queryResult.clear();
    if (pendingFriends.length == 0) {
      setState(() {
        noResult = true;
      });
    } else {
      for (int i = 0;
          i < pendingFriends.length;
          i = i + 10) {
        List<String> query = pendingFriends
            .getRange(
                i,
                i + 10 > pendingFriends.length
                    ? pendingFriends.length
                    : i + 10)
            .toList();
        queryResult.addAll(await Database().getUsersByIds(context, query));
      }
    }
    queryResult.forEach((element) {
      waiting.add(false);
    });
    setState(() {
      isDataLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
      appBar: AppBar(),
      body: noResult
          ? Center(child: Text("You don't have any friends request yet.", style: TextStyle(fontSize: widget.configuration.textSizeFactor * 20),))
          : isDataLoaded
              ? ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                      widget.configuration.screenWidth / 20,
                      widget.configuration.screenWidth / 40,
                      widget.configuration.screenWidth / 20,
                      widget.configuration.screenWidth / 40),
                  itemCount: queryResult.length,
                  itemBuilder: (BuildContext context, int itemIndex) {
                    return showResultWidget(itemIndex);
                  },
                  shrinkWrap: true,
                  physics: AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                )
              : Center(child: CircularProgressIndicator()),
    );
  }

  Widget showResultWidget(int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Profile(
                    configuration: widget.configuration,
                    userProfile: queryResult[index],
                  ))),
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(0, widget.configuration.screenWidth / 60, 0, 0),
        child: Container(
          padding: EdgeInsets.all(widget.configuration.screenWidth / 60),
          height: widget.configuration.screenWidth / 6.5,
          decoration: BoxDecoration(
            color: PrimaryColorLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Hero(
                  tag: queryResult[index].userId,
                  child: ProfilePicture(
                      queryResult[index].profilePictureDownloadPath,
                      size: widget.configuration.screenWidth / 8)),
              Divider(
                indent: widget.configuration.screenWidth / 50,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      queryResult[index].pseudo,
                      style: TextStyle(
                          fontSize: 15 * widget.configuration.textSizeFactor),
                    ),
                    Text(
                      "@" + queryResult[index].username,
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.white54,
                          fontSize: 13 * widget.configuration.textSizeFactor),
                    ),
                  ],
                ),
              ),
              waiting[index]
                  ? CircularProgressIndicator()
                  : ButtonTheme(
                      minWidth: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              widget.configuration.screenWidth / 25)),
                      child: Row(
                        children: <Widget>[
                          showRefuseButton(index),
                          Divider(
                            indent: widget.configuration.screenWidth / 60,
                          ),
                          showAcceptButton(index),
                        ],
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }

  Widget showAcceptButton(int index) {
    return RaisedButton(
      color: Colors.green,
      child: Text(
        'Accept',
        style: TextStyle(
            fontSize: 12 * widget.configuration.textSizeFactor,
            color: Colors.white),
      ),
      onPressed: () async {
        setState(() {
          waiting[index] = true;
        });
        await Database().acceptFriendRequest(context,
            widget.configuration.userData.userId, queryResult[index].userId);
        waiting[index] = false;
        setState(() {});
      },
    );
  }

  Widget showRefuseButton(int index) {
    return RaisedButton(
      color: Colors.red,
      child: Text(
        'Refuse',
        style: TextStyle(
            fontSize: 12 * widget.configuration.textSizeFactor,
            color: Colors.white),
      ),
      onPressed: () async {
        setState(() {
          waiting[index] = true;
        });

        await Database().refuseFriendRequest(context,
            widget.configuration.userData.userId, queryResult[index].userId);

        waiting[index] = false;
        setState(() {});
      },
    );
  }
}
