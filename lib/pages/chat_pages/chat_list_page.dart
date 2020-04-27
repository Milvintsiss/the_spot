import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/services/library/UserProfile.dart';
import 'package:the_spot/services/library/search_engine.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/theme.dart';

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool userIsSearching = false;
  bool isWaiting = true;

  String query;

  List<UserProfile> queryResult = [];

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
            return showResultWidget(queryResult[itemIndex]);
          },
          shrinkWrap: true,
        ),
      );
  }

  Widget showResultWidget(UserProfile userProfile) {
    return Padding(
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
            ProfilePicture(userProfile.profilePictureDownloadPath, size: 50),
            Divider(
              indent: 10,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(userProfile.pseudo),
                  Text(
                    "@" + userProfile.username,
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.white70),
                  ),
                ],
              ),
            ),
            ButtonTheme(
              minWidth: 40,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)
              ),
              buttonColor: SecondaryColor,
              disabledColor: SecondaryColorDark,
              child: Row(
                children: <Widget>[
                  RaisedButton(
                    child: Text("Follow"),
                    onPressed: (){},
                  ),
                  Divider(indent: 5,),
                  RaisedButton(
                    child: Text("Add+"),
                    onPressed: (){},
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget showChatListWidget() {
    return Text("userIsNotSearching");
  }

  Future<List> getUsers() async {
    return await searchUsers(context, query);
  }
}
