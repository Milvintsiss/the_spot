import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/chat_pages/chat_creation_dialog.dart';
import 'package:the_spot/pages/chat_pages/chat_page.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/chatGroup.dart';
import 'package:the_spot/services/library/profilePictureWidget.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/library/usersListView.dart';
import 'package:the_spot/services/search_engine.dart';
import 'package:the_spot/theme.dart';

class ChatListPage extends StatefulWidget {
  ChatListPage({this.configuration});

  final Configuration configuration;

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {

  ScrollController scrollController = ScrollController();

  bool userIsSearching = false;
  bool userIsTyping = false;
  bool isWaitingForQueryResult = true;
  bool hasChatGroupConversation = false;
  bool isLoadingChatGroups = true;
  bool firstLoad = true;
  bool isLoadingMoreChatGroups = false;

  int page;

  String query;

  List<UserProfile> queryResult = [];

  List<ChatGroup> chatGroups = [];

  StreamSubscription chatGroupsStream;

  final searchBarController =
      TextEditingController.fromValue(TextEditingValue.empty);

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
      if (event.documentChanges.length > 0) {
        List<DocumentChange> documentChanges = event.documentChanges;
        if (firstLoad) {
          documentChanges = documentChanges.reversed.toList();
          firstLoad = false;
        }
        await Future.forEach(documentChanges, (DocumentChange change) async {
          final ChatGroup chatGroup =
              convertMapToChatGroup(change.document.data);
          chatGroup.id = change.document.documentID;
          chatGroups.removeWhere(
              (modifiedChatGroup) => modifiedChatGroup.id == chatGroup.id);
          if (!chatGroup.isGroup) {
            String otherUserId = chatGroup.membersIds.firstWhere(
                (element) => element != widget.configuration.userData.userId);
            chatGroup.members =
                await Database().getUsersByIds(context, [otherUserId]);
          }
          print(change.document.data);
          chatGroup.messages
              .forEach((message) => message.setMessageTypeAndTransformData());
          chatGroups.insert(0, chatGroup);
        });
        hasChatGroupConversation = true;
      } else {
        hasChatGroupConversation = false;
      }
      isLoadingChatGroups = false;
      setState(() {});
    });
  }

  void loadMoreChatGroups() async {
    if(!isLoadingMoreChatGroups) {
      setState(() {
        isLoadingMoreChatGroups = true;
      });
      List<ChatGroup> loadedChatGroups = await Database().getGroups(context,
          userId: widget.configuration.userData.userId,
          startAfter: chatGroups[chatGroups.length - 1].lastMessage,
          limit: 10);
      await Future.forEach(loadedChatGroups, (chatGroup) async {
        if (!chatGroup.isGroup) {
          String otherUserId = chatGroup.membersIds.firstWhere(
                  (element) => element != widget.configuration.userData.userId);
          chatGroup.members =
              await Database().getUsersByIds(context, [otherUserId]);
        }
        chatGroup.messages
            .forEach((message) => message.setMessageTypeAndTransformData());
        chatGroups.add(chatGroup);
      });
      setState(() {
        isLoadingMoreChatGroups = false;
      });
    }
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
                      if (query.length > 0) {
                        userIsTyping = true;
                      } else {
                        userIsTyping = false;
                        userIsSearching = false;
                      }
                    });
                  },
                  style: TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onEditingComplete: onSearchButtonPressed,
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context).translate("Search..."),
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
                  userIsTyping && query.length > 0
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: PrimaryColorDark,
                          ),
                          onPressed: () => setState(() {
                            query = "";
                            searchBarController.clear();
                            userIsSearching = false;
                            userIsTyping = false;
                          }),
                        )
                      : Container(),
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: PrimaryColorDark,
                    ),
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
        child: Text(
          AppLocalizations.of(context)
              .translate("No result found for \"%DYNAMIC\".", dynamic: query),
        ),
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
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            loadMoreChatGroups();
          }
          return true;
        },
        child: ListView(
          controller: scrollController,
          children: [
            ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  widget.configuration.screenWidth / 20,
                  widget.configuration.screenWidth / 40,
                  widget.configuration.screenWidth / 20,
                  widget.configuration.screenWidth / 60),
              itemCount: chatGroups.length,
              itemBuilder: (BuildContext context, int itemIndex) {
                return showChatGroupTile(itemIndex);
              },
              physics: ScrollPhysics(),
              shrinkWrap: true,
            ),
            isLoadingMoreChatGroups ? Center(child: CircularProgressIndicator()) : Container(),
            showStartChatButton(),
          ],
          physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        ),
      ),
    );
  }

  Widget showChatGroupTile(int index) {
    String picture = chatGroups[index].pictureDownloadPath;
    String hash = chatGroups[index].pictureHash;
    if (picture == null && !chatGroups[index].isGroup) {
      picture = chatGroups[index].members[0].profilePictureDownloadPath;
      hash = chatGroups[index].members[0].profilePictureHash;
    }
    return GestureDetector(
        child: Padding(
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
                ProfilePicture(
                    downloadUrl: picture,
                    hash: hash,
                    isAnUser: !chatGroups[index].isGroup),
                Divider(
                  indent: widget.configuration.screenWidth / 40,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chatGroups[index].isGroup
                            ? chatGroups[index].name
                            : chatGroups[index].members[0].pseudo,
                        style: TextStyle(
                          fontSize: 18 * widget.configuration.textSizeFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        chatGroups[index].messages.length > 0 ?
                        chatGroups[index]
                            .messages[chatGroups[index].messages.length - 1]
                            .data
                        : AppLocalizations.of(context).translate("empty"),
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
        ),
        onTap: () {
          Feedback.wrapForTap(() async {
            chatGroupsStream.pause();
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatPage(
                          configuration: widget.configuration,
                          chatGroup: chatGroups[index],
                        )));
            chatGroupsStream.resume();
          }, context)
              .call();
        });
  }

  Widget showStartChatButton() {
    return Padding(
        padding: EdgeInsets.fromLTRB(
            widget.configuration.screenWidth / 60,
            0,
            widget.configuration.screenWidth / 60,
            0),
        child: RaisedButton(
          child:
              Text(AppLocalizations.of(context).translate("Start a new chat")),
          onPressed: () {
            showChatCreationDialog();
          },
        ));
  }

  void showChatCreationDialog() {
    ChatCreationDialog().showChatCreationDialog(widget.configuration, context);
  }
}
