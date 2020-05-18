import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/chatGroup.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'file:///C:/Users/plest/StudioProjects/the_spot/lib/services/configuration.dart';
import 'file:///C:/Users/plest/StudioProjects/the_spot/lib/services/search_engine.dart';
import 'package:the_spot/services/library/usersListView.dart';
import 'package:the_spot/theme.dart';

class ChatListPage extends StatefulWidget {
  ChatListPage({this.configuration});

  final Configuration configuration;

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool userIsSearching = false;
  bool userIsTyping = false;
  bool isWaitingForQueryResult = true;
  bool hasChatGroupConversation = false;
  bool isLoadingChatGroups = true;

  int page;

  String query;

  List<UserProfile> queryResult = [];

  List<ChatGroup> chatGroups = [];

  StreamSubscription chatGroupsStream;

  final searchBarController = TextEditingController.fromValue(TextEditingValue.empty);

  @override
  void initState() {
    super.initState();
    startChatGroupsStream();
  }

  @override
  void dispose() {
    chatGroupsStream.cancel();
    super.dispose();
  }

  void startChatGroupsStream() {
    chatGroupsStream = Firestore.instance
        .collection('groupChats')
        .orderBy('LastMessage', descending: true)
        .where('MembersIds',
            arrayContains: widget.configuration.userData.userId)
        .limit(10)
        .snapshots()
        .listen((event) async {
      if (event.documents.length > 0) {
        chatGroups.clear();
        await Future.forEach(event.documents, (document) async {
          final ChatGroup chatGroup = convertMapToChatGroup(document.data);
          chatGroup.id = document.documentID;
          if(!chatGroup.isGroup){
            String otherUserId = chatGroup.membersIds.firstWhere((element) => element != widget.configuration.userData.userId);
            chatGroup.members = await Database().getUsersByIds(context, [otherUserId]);
          }
          print(document.data);
          chatGroups.add(chatGroup);
        });
        hasChatGroupConversation = true;
      } else {
        hasChatGroupConversation = false;
      }
      isLoadingChatGroups = false;
      setState(() {});
    });
  }

  Future getUsersCallback() async {
    if (page == -1 || page == 0) {
      queryResult =
          await searchUsers(context, query, widget.configuration, page);
    } else {
      queryResult.addAll(
          await searchUsers(context, query, widget.configuration, page));
    }
    setState(() {
      isWaitingForQueryResult = false;
    });
    await Future.delayed(Duration(seconds: 1));

    print("page: $page");
    page++;
  }

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextField(
                  controller: searchBarController,
                  onChanged: (String value) {
                      query = value.trim();
                      setState(() {
                        userIsTyping = true;
                      });
                  },
                  style: TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onEditingComplete: onSearchButtonPressed,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  userIsTyping && query.length > 0 ? IconButton(
                    icon: Icon(Icons.clear, color: PrimaryColorDark,),
                    onPressed: () => setState((){query = ""; searchBarController.clear(); userIsSearching = false; userIsTyping = false;}),
                  ): Container(),
                  IconButton(
                    icon: Icon(Icons.search, color: PrimaryColorDark,),
                    onPressed: onSearchButtonPressed,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void onSearchButtonPressed() async {
    page = 0;
    setState(() {
      isWaitingForQueryResult = true;
      if (query.length > 0) {
        userIsSearching = true;
        getUsersCallback();
      } else {
        userIsSearching = false;
      }
    });
  }

  Widget showQueryResultsWidget() {
    if (isWaitingForQueryResult) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (queryResult.length == 0 || queryResult == null)
      return Padding(
        padding: EdgeInsets.only(top: widget.configuration.screenWidth / 40),
        child: Text("No result found for \"$query\""),
      );
    else
      return UsersListView(
        configuration: widget.configuration,
        query: queryResult,
        onBottomListReachedCallback: getUsersCallback,
      );
  }

  Widget showChatListWidget() {
    if (isLoadingChatGroups)
      return Center(child: CircularProgressIndicator());
    else if (hasChatGroupConversation)
      return showChatGroupsList();
    else
      return showStartChatButton();
  }

  Widget showChatGroupsList() {
    return Expanded(
      child: ListView(
        children: [
          ListView.builder(
            padding: EdgeInsets.fromLTRB(
                widget.configuration.screenWidth / 20,
                widget.configuration.screenWidth / 40,
                widget.configuration.screenWidth / 20,
                widget.configuration.screenWidth / 20),
            itemCount: chatGroups.length,
            itemBuilder: (BuildContext context, int itemIndex) {
              return showChatGroupTile(itemIndex);
            },
            physics: ScrollPhysics(),
            shrinkWrap: true,
          ),
          showStartChatButton(),
        ],
      ),
    );
  }

  Widget showChatGroupTile(int index) {
    String picture = chatGroups[index].imageDownloadPath;
    if(picture == null && !chatGroups[index].isGroup){
      picture = chatGroups[index].members[0].profilePictureDownloadPath;
    }
    return Padding(
      padding: EdgeInsets.only(top: widget.configuration.screenWidth / 60),
      child: Container(
        padding: EdgeInsets.all(widget.configuration.screenWidth / 80),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PrimaryColorLight, PrimaryColor]),
            borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ProfilePicture(picture),
            Divider(
              indent: widget.configuration.screenWidth / 40,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatGroups[index].name,
                    style: TextStyle(
                      fontSize: 18 * widget.configuration.textSizeFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    chatGroups[index]
                        .messages[chatGroups[index].messages.length - 1]
                        .data,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(

                      color: Colors.white70,
                      fontSize: 14 * widget.configuration.textSizeFactor,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget showStartChatButton() {
    return Padding(
        padding: EdgeInsets.fromLTRB(
            widget.configuration.screenWidth / 60,
            widget.configuration.screenWidth / 20,
            widget.configuration.screenWidth / 60,
            0),
        child: RaisedButton(
          child: Text("Start a new chat"),
          onPressed: () {
            Database().createNewChatGroup(
                context,
                ChatGroup(
                  name: "Les Zozos 3",
                  membersIds: [
                    widget.configuration.userData.userId,
                    "Cv8LUSvtxqOuThY44YBe2VzjqRo1"
                  ],
                  adminsIds: [
                    widget.configuration.userData.userId,
                    "Cv8LUSvtxqOuThY44YBe2VzjqRo1"
                  ],
                  messages: [
                    Message(
                        widget.configuration.userData.userId,
                        Timestamp.now(),
                        "Coucou comment ça va l'ami c'était pour te dire que je vais aller à la plage demain est-ce que ça te dirais de venir avec moi?")
                  ],
                ));
          },
        ));
  }
}
