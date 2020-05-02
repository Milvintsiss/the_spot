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

  bool waitForFollowing = false;

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
      padding: EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
            color: PrimaryColor,
            borderRadius: BorderRadius.all(Radius.circular(30))),
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
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: CircularProgressIndicator(),
          ));
    else if (queryResult.length == 0 || queryResult == null)
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text("No result found for \"$query\""),
      );
    else
      return Expanded(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          itemCount: queryResult.length,
          itemBuilder: (BuildContext context, int itemIndex) {
            return showResultWidget(itemIndex);
          },
          shrinkWrap: true,
        ),
      );
  }

  Widget showResultWidget(int index) {
    bool waitForSendingFriendRequest = false;
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Profile(
                    configuration: widget.configuration,
                    userProfile: queryResult[index],
                  ))),
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
        child: Container(
          padding: EdgeInsets.all(8),
          height: 70,
          decoration: BoxDecoration(
            color: PrimaryColorLight,
            borderRadius: BorderRadius.circular(70),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Hero(
                  tag: queryResult[index].userId,
                  child: ProfilePicture(
                      queryResult[index].profilePictureDownloadPath,
                      size: 50)),
              Divider(
                indent: 10,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(queryResult[index].pseudo),
                    Text(
                      "@" + queryResult[index].username,
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ButtonTheme(
                minWidth: 40,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                buttonColor: PrimaryColor,
                disabledColor: PrimaryColor,
                child: Row(
                  children: <Widget>[
                    showFollowButton(index),
                    Divider(
                      indent: 5,
                    ),
                    RaisedButton(
                      child: Text("Add+"),
                      onPressed: () {},
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget showFollowButton(int index){
    return RaisedButton(
      color: queryResult[index].followed ? transparentColor(SecondaryColor, 100) : PrimaryColor,
      child: waitForFollowing
          ? SizedBox(
        height: 10,
        width: 10,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              PrimaryColorDark),
        ),
      )
          : Text(queryResult[index].followed ? 'Unfollow' : 'Follow'),
      onPressed: waitForFollowing ? null : () async {
        setState(() {
          waitForFollowing = true;
        });
        if (queryResult[index].followed) {
          await Database().unFollowUser(
              context, widget.configuration, queryResult[index]);
          queryResult[index].followed = false;
        }else {
          await Database().followUser(
              context, widget.configuration, queryResult[index]);
          queryResult[index].followed = true;
        }
        waitForFollowing = false;
        setState(() {
        });
      },
    );
  }

  Widget showChatListWidget() {
    return Text("userIsNotSearching");
  }

  Future<List> getUsers() async {
    return await searchUsers(context, query, widget.configuration);
  }
}
