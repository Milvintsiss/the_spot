import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/chat_pages/chat_page.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/chatGroup.dart';
import 'package:the_spot/services/library/profilePictureWidget.dart';
import 'package:the_spot/services/library/searchBar.dart';
import 'package:the_spot/services/library/userItem.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/library/usersListView.dart';
import 'package:the_spot/services/search_engine.dart';
import 'package:the_spot/theme.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

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

  bool dialogIsLoadingUsers = false;
  List<UserProfile> dialogQueryResult = [];
  List<UserProfile> newChatGroupMembers = [];
  StateSetter dialogStateSetter;

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
        .limit(100)
        .snapshots()
        .listen((event) async {
      if (event.documents.length > 0) {
        chatGroups.clear();
        await Future.forEach(event.documents, (document) async {
          final ChatGroup chatGroup = convertMapToChatGroup(document.data);
          chatGroup.id = document.documentID;
          if (!chatGroup.isGroup) {
            String otherUserId = chatGroup.membersIds.firstWhere(
                (element) => element != widget.configuration.userData.userId);
            chatGroup.members =
                await Database().getUsersByIds(context, [otherUserId]);
          }
          print(document.data);
          chatGroup.messages
              .forEach((message) => message.setMessageTypeAndTransformData());
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
                    hintText: AppLocalizations.of(context).translate("Search..."),
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
            AppLocalizations.of(context).translate("No result found for \"%DYNAMIC\".", dynamic: query),
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
                ProfilePicture(downloadUrl: picture, hash: hash, isAnUser: false),
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
            widget.configuration.screenWidth / 20,
            widget.configuration.screenWidth / 60,
            0),
        child: RaisedButton(
          child: Text(AppLocalizations.of(context).translate("Start a new chat")),
          onPressed: () {
            showChatCreationDialog();
          },
        ));
  }

  void showChatCreationDialog() {
    AlertDialog chatCreationDialog = AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: PrimaryColorDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(widget.configuration.screenWidth / 30)),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          dialogStateSetter = stateSetter;
          return SizedBox(
            width: widget.configuration.screenWidth * 4 / 5,
            child: ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: widget.configuration.screenWidth / 40,
                  vertical: widget.configuration.screenWidth / 30),
              physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              shrinkWrap: true,
              children: [
                Text(
                  AppLocalizations.of(context).translate("With:"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * widget.configuration.textSizeFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(
                  height: widget.configuration.screenWidth / 30,
                  color: Colors.white,
                  thickness: 1,
                ),
                showChatCreationDialogMembersWidget(),
                Padding(
                  padding: EdgeInsets.only(
                      top: widget.configuration.screenWidth / 60),
                ),
                SearchBar(chatCreationDialogSearchCallback,
                    sizeFactor: widget.configuration.screenWidth / 12,
                    textSize: 14 * widget.configuration.textSizeFactor),
                Padding(
                  padding: EdgeInsets.only(
                      top: widget.configuration.screenWidth / 60),
                ),
                showChatCreationDialogSearchedUsers(),
                showChatCreationDialogCreateButton(),
              ],
            ),
          );
        },
      ),
    );
    showDialog(
      context: context,
      child: chatCreationDialog,
    );
  }

  Widget showChatCreationDialogMembersWidget() {
    return SizedBox(
      width: widget.configuration.screenWidth * 4 / 5,
      child: Container(
        decoration: BoxDecoration(
            color: PrimaryColorLight,
            borderRadius:
                BorderRadius.circular(widget.configuration.screenWidth / 30)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: widget.configuration.screenWidth / 60,
              vertical: widget.configuration.screenWidth / 60),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(AppLocalizations.of(context).translate("Members: ")),
              Padding(
                padding: EdgeInsets.only(
                    right: widget.configuration.screenWidth / 150),
                child: UserItem(
                    user: widget.configuration.userData,
                    sizeReference: widget.configuration.screenWidth,
                    textSizeReference: widget.configuration.textSizeFactor,
                    isDeletable: false),
              ),
              for (UserProfile userProfile in newChatGroupMembers)
                Padding(
                  padding:
                      EdgeInsets.all(widget.configuration.screenWidth / 300),
                  child: UserItem(
                    user: userProfile,
                    sizeReference: widget.configuration.screenWidth,
                    textSizeReference: widget.configuration.textSizeFactor,
                    isDeletable: true,
                    deleteCallback: chatCreationDialogUserDeleteCallback,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget showChatCreationDialogSearchedUsers() {
    if (dialogIsLoadingUsers)
      return SizedBox(
        height: widget.configuration.screenWidth / 30,
        width: widget.configuration.screenWidth / 30,
        child: Center(child: CircularProgressIndicator()),
      );
    else if (dialogQueryResult.length == 0 &&
        widget.configuration.userData.numberOfFriends == 0)
      return Text(AppLocalizations.of(context).translate("No suggestions"));
    else if (dialogQueryResult.length > 0)
      return SizedBox(
        height: widget.configuration.screenWidth / 15,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: dialogQueryResult.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: EdgeInsets.only(
                    right: widget.configuration.screenWidth / 150),
                child: UserItem(
                  user: dialogQueryResult[index],
                  sizeReference: widget.configuration.screenWidth,
                  textSizeReference: widget.configuration.textSizeFactor,
                  clickCallback: chatCreationDialogUserClickCallback,
                ),
              );
            }),
      );
    else
      chatCreationDialogSearchCallback(null);
    return SizedBox(
      height: widget.configuration.screenWidth / 30,
      width: widget.configuration.screenWidth / 30,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget showChatCreationDialogCreateButton() {
    return RaisedButton(
      child: Text(AppLocalizations.of(context).translate("Create")),
      onPressed: () {
        if (newChatGroupMembers.length > 0) {
          List<String> membersIds = [];
          String name = "${widget.configuration.userData.pseudo}";
          newChatGroupMembers.forEach((element) {
            membersIds.add(element.userId);
            name = name + ", ${element.pseudo}";
          });
          membersIds.add(widget.configuration.userData.userId);
          Database().createNewChatGroup(
              context,
              ChatGroup(
                name: name,
                membersIds: membersIds,
                adminsIds: membersIds.length == 2
                    ? membersIds
                    : [
                        widget.configuration.userData.userId,
                      ],
                creatorId: widget.configuration.userData.userId,
                onlyAdminsCanChangeChatNameOrPicture: membersIds.length == 2,
                messages: [
                  Message(widget.configuration.userData.userId, Timestamp.now(),
                      AppLocalizations.of(context).translate("%DYNAMIC has invited you in a chat.", dynamic: INFO_TYPE + widget.configuration.userData.pseudo)
                  ),
                ],
              ));
          dialogQueryResult.clear();
          newChatGroupMembers.clear();
          Navigator.pop(context);
        } else {
          Vibrate.feedback(FeedbackType.warning);
          FlushbarHelper.createError(
                  message:
                      AppLocalizations.of(context).translate("You should add at least one member to create a new chat!"),
                  duration: Duration(seconds: 3))
              .show(context);
        }
      },
    );
  }

  void chatCreationDialogSearchCallback(String query) async {
    dialogStateSetter(() {
      dialogIsLoadingUsers = true;
    });
    if (query != null && query.length > 0) {
      //return search query of the user
      dialogQueryResult = await searchUsers(
          context, query, widget.configuration, 0,
          verifyIfUsersAreFollowedOrFriends: false);
      print(query);
    } else if (widget.configuration.userData.numberOfFriends > 0) {
      //return suggestions if user is not searching
      List<String> friendsListId =
          widget.configuration.userData.friends.reversed.toList();
      if (friendsListId.length > 10)
        friendsListId = friendsListId.getRange(0, 9);
      dialogQueryResult = await Database().getUsersByIds(context, friendsListId,
          verifyIfFriendsOrFollowed: false);
      dialogStateSetter(() {});
    } else {
      //return nothing because user don't have any friends
      dialogStateSetter(() {
        dialogQueryResult.clear();
      });
    }

    dialogQueryResult.removeWhere((dialogQueryResultUser) =>
        newChatGroupMembers.indexWhere((newChatGroupMembersUser) =>
                newChatGroupMembersUser.userId ==
                dialogQueryResultUser.userId) !=
            -1 ||
        dialogQueryResultUser.userId == widget.configuration.userData.userId);

    dialogStateSetter(() {
      dialogIsLoadingUsers = false;
    });
  }

  void chatCreationDialogUserClickCallback(UserProfile user) {
    dialogStateSetter(() {
      dialogQueryResult.remove(user);
      newChatGroupMembers.add(user);
    });
  }

  void chatCreationDialogUserDeleteCallback(UserProfile user) {
    dialogStateSetter(() {
      newChatGroupMembers.remove(user);
    });
  }
}
