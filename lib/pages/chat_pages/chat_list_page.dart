import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/pages/home_page/profile.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/UserProfile.dart';
import 'package:the_spot/services/library/configuration.dart';
import 'package:the_spot/services/library/search_engine.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/theme.dart';

class ChatListPage extends StatefulWidget {
  ChatListPage({this.configuration});

  final Configuration configuration;

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool userIsSearching = false;
  bool isWaiting = true;

  String query;

  List<UserProfile> queryResult = [];
  List<bool> waitForFollowing = [];
  List<bool> friendRequestAlreadyDone = [];
  List<bool> waitForSendingFriendRequest = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
      body: Column(
        children: <Widget>[
          showSearchBarWidget(),
          userIsSearching ? showQueryResultsWidget() : showChatListWidget(),
        ],
      ),
    );
  }

  Widget showSearchBarWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          widget.configuration.screenWidth / 26,
          widget.configuration.screenWidth / 10,
          widget.configuration.screenWidth / 26,
          0),
      child: Container(
        height: widget.configuration.screenWidth / 10,
        decoration: BoxDecoration(
            color: PrimaryColor,
            borderRadius: BorderRadius.all(Radius.circular(100))),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 10, 0),
          child: TextField(
            onChanged: (String value) async {
              setState(() {
                isWaiting = true;
                if (value.trim().length > 0) {
                  query = value.trim();
                  userIsSearching = true;
                } else {
                  userIsSearching = false;
                }
              });
              queryResult = await getUsers();
              waitForFollowing.clear();
              queryResult.forEach((element) {
                waitForFollowing.add(false);
                waitForSendingFriendRequest.add(false);
                if (element.pendingFriendsId
                        .indexOf(widget.configuration.userData.userId) !=
                    -1) {
                  friendRequestAlreadyDone.add(true);
                } else {
                  friendRequestAlreadyDone.add(false);
                }
              });
              setState(() {
                isWaiting = false;
              });
            },
            style: TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: "Search...",
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget showQueryResultsWidget() {
    if (isWaiting)
      return Padding(
          padding: EdgeInsets.only(top: widget.configuration.screenWidth / 20),
          child: Center(
            child: CircularProgressIndicator(),
          ));
    else if (queryResult.length == 0 || queryResult == null)
      return Padding(
        padding: EdgeInsets.only(top: widget.configuration.screenWidth / 40),
        child: Text("No result found for \"$query\""),
      );
    else
      return Expanded(
        child: ListView.builder(
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
        ),
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
              ButtonTheme(
                minWidth: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        widget.configuration.screenWidth / 25)),
                buttonColor: PrimaryColor,
                disabledColor: PrimaryColor,
                child: Row(
                  children: <Widget>[
                    showFollowButton(index),
                    Divider(
                      indent: widget.configuration.screenWidth / 60,
                    ),
                    showAddFriendButton(index),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget showFollowButton(int index) {
    return RaisedButton(
      color: queryResult[index].isFollowed
          ? transparentColor(SecondaryColor, 100)
          : PrimaryColor,
      child: waitForFollowing[index]
          ? SizedBox(
              height: widget.configuration.screenWidth / 30,
              width: widget.configuration.screenWidth / 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PrimaryColorDark),
              ),
            )
          : Text(
              queryResult[index].isFollowed ? 'Unfollow' : 'Follow',
              style: TextStyle(
                  fontSize: 12 * widget.configuration.textSizeFactor,
                  color: !queryResult[index].isFollowed
                      ? Colors.black
                      : Colors.black54),
            ),
      onPressed: waitForFollowing[index]
          ? null
          : () async {
              setState(() {
                waitForFollowing[index] = true;
              });
              if (queryResult[index].isFollowed) {
                await Database().unFollowUser(
                    context,
                    widget.configuration.userData.userId,
                    queryResult[index].userId);
                queryResult[index].isFollowed = false;
                queryResult[index].numberOfFollowers--;
                widget.configuration.userData.numberOfFollowing--;
              } else {
                await Database().followUser(
                    context,
                    widget.configuration.userData.userId,
                    queryResult[index].userId);
                queryResult[index].isFollowed = true;
                queryResult[index].numberOfFollowers++;
                widget.configuration.userData.numberOfFollowing++;
              }
              waitForFollowing[index] = false;
              setState(() {});
            },
    );
  }

  Widget showAddFriendButton(int index) {
    if (queryResult[index].isFriend) {
      return Icon(
        Icons.check,
      );
    } else {
      return RaisedButton(
        color: friendRequestAlreadyDone[index]
            ? transparentColor(SecondaryColor, 100)
            : PrimaryColor,
        child: waitForSendingFriendRequest[index]
            ? SizedBox(
          height: widget.configuration.screenWidth / 30,
          width: widget.configuration.screenWidth / 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(PrimaryColorDark),
                ),
              )
            : Text(
                !friendRequestAlreadyDone[index] ? 'Add+' : 'Requested',
                style: TextStyle(
                    fontSize: 12 * widget.configuration.textSizeFactor,
                    color: !friendRequestAlreadyDone[index]
                        ? Colors.black
                        : Colors.black54),
              ),
        onPressed: waitForSendingFriendRequest[index]
            ? null
            : () async {
                setState(() {
                  waitForSendingFriendRequest[index] = true;
                });
                if (!friendRequestAlreadyDone[index]) {
                  await Database().sendFriendRequest(
                      context,
                      widget.configuration.userData.userId,
                      widget.configuration.userData.pseudo,
                      widget.configuration.userData.profilePictureDownloadPath,
                      queryResult[index].userId);
                } else {
                  await Database().removeFriendRequest(
                      context,
                      widget.configuration.userData.userId,
                      queryResult[index].userId);
                }
                friendRequestAlreadyDone[index] =
                    !friendRequestAlreadyDone[index];
                waitForSendingFriendRequest[index] = false;
                setState(() {});
              },
      );
    }
  }

  Widget showChatListWidget() {
    return Text("userIsNotSearching");
  }

  Future<List> getUsers() async {
    return await searchUsers(context, query, widget.configuration);
  }
}
