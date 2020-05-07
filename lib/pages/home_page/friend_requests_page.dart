import 'package:flutter/material.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/UserProfile.dart';
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

  @override
  void initState() {
    super.initState();

    getUsersData();
  }

  void getUsersData() async {
    print(widget.configuration.userData.pendingFriendsId);
    queryResult = await Database()
        .getUsersByIds(context, widget.configuration.userData.pendingFriendsId);
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
      body: isDataLoaded
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
                      buttonColor: PrimaryColor,
                      disabledColor: PrimaryColor,
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

        if (await Database().acceptFriendRequest(context,
            widget.configuration.userData.userId, queryResult[index].userId)) {
          widget.configuration.userData.pendingFriendsId.remove(queryResult[index].userId);
          widget.configuration.userData.friends.add(queryResult[index].userId);
          widget.configuration.userData.numberOfFriends ++;
          queryResult.removeAt(index);
        }

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

        if (await Database().refuseFriendRequest(context,
            widget.configuration.userData.userId, queryResult[index].userId)) {
          widget.configuration.userData.pendingFriendsId.remove(queryResult[index].userId);
          queryResult.removeAt(index);
        }

        waiting[index] = false;
        setState(() {});
      },
    );
  }
}
