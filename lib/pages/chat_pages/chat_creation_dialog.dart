import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/chatGroup.dart';
import 'package:the_spot/services/library/searchBar.dart';
import 'package:the_spot/services/library/userItem.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/search_engine.dart';

import '../../app_localizations.dart';
import '../../theme.dart';

class ChatCreationDialog {
  Configuration configuration;
  StateSetter dialogStateSetter;
  BuildContext context;
  bool dialogIsLoadingUsers = false;
  List<UserProfile> dialogQueryResult = [];
  List<UserProfile> newChatGroupMembers = [];

  void showChatCreationDialog(
    Configuration _configuration,
    BuildContext _context,
  ) {
    configuration = _configuration;
    context = _context;

    AlertDialog chatCreationDialog = AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: PrimaryColorDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(configuration.screenWidth / 30)),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          dialogStateSetter = stateSetter;
          return SizedBox(
            width: configuration.screenWidth * 4 / 5,
            child: ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: configuration.screenWidth / 40,
                  vertical: configuration.screenWidth / 30),
              physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              shrinkWrap: true,
              children: [
                Text(
                  AppLocalizations.of(context).translate("With:"),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * configuration.textSizeFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(
                  height: configuration.screenWidth / 30,
                  color: Colors.white,
                  thickness: 1,
                ),
                showChatCreationDialogMembersWidget(),
                Padding(
                  padding: EdgeInsets.only(top: configuration.screenWidth / 60),
                ),
                SearchBar(chatCreationDialogSearchCallback,
                    sizeFactor: configuration.screenWidth / 12,
                    textSize: 14 * configuration.textSizeFactor),
                Padding(
                  padding: EdgeInsets.only(top: configuration.screenWidth / 60),
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
      width: configuration.screenWidth * 4 / 5,
      child: Container(
        decoration: BoxDecoration(
            color: PrimaryColorLight,
            borderRadius:
                BorderRadius.circular(configuration.screenWidth / 30)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: configuration.screenWidth / 60,
              vertical: configuration.screenWidth / 60),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(AppLocalizations.of(context).translate("Members: ")),
              Padding(
                padding:
                    EdgeInsets.only(right: configuration.screenWidth / 150),
                child: UserItem(
                    user: configuration.userData,
                    sizeReference: configuration.screenWidth,
                    textSizeReference: configuration.textSizeFactor,
                    isDeletable: false),
              ),
              for (UserProfile userProfile in newChatGroupMembers)
                Padding(
                  padding: EdgeInsets.all(configuration.screenWidth / 300),
                  child: UserItem(
                    user: userProfile,
                    sizeReference: configuration.screenWidth,
                    textSizeReference: configuration.textSizeFactor,
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
        height: configuration.screenWidth / 30,
        width: configuration.screenWidth / 30,
        child: Center(child: CircularProgressIndicator()),
      );
    else if (dialogQueryResult.length == 0 &&
        configuration.userData.numberOfFriends == 0)
      return Text(AppLocalizations.of(context).translate("No suggestions"));
    else if (dialogQueryResult.length > 0)
      return SizedBox(
        height: configuration.screenWidth / 15,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: dialogQueryResult.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding:
                    EdgeInsets.only(right: configuration.screenWidth / 150),
                child: UserItem(
                  user: dialogQueryResult[index],
                  sizeReference: configuration.screenWidth,
                  textSizeReference: configuration.textSizeFactor,
                  clickCallback: chatCreationDialogUserClickCallback,
                ),
              );
            }),
      );
    else
      chatCreationDialogSearchCallback(null);
    return SizedBox(
      height: configuration.screenWidth / 30,
      width: configuration.screenWidth / 30,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget showChatCreationDialogCreateButton() {
    return RaisedButton(
      child: Text(AppLocalizations.of(context).translate("Create")),
      onPressed: () {
        if (newChatGroupMembers.length > 0) {
          List<String> membersIds = [];
          String name = "${configuration.userData.pseudo}";
          newChatGroupMembers.forEach((element) {
            membersIds.add(element.userId);
            name = name + ", ${element.pseudo}";
          });
          membersIds.add(configuration.userData.userId);
          Database().createNewChatGroup(
              context,
              ChatGroup(
                name: name,
                membersIds: membersIds,
                adminsIds: membersIds.length == 2
                    ? membersIds
                    : [
                        configuration.userData.userId,
                      ],
                creatorId: configuration.userData.userId,
                onlyAdminsCanChangeChatNameOrPicture: membersIds.length == 2,
                messages: [
                  Message(
                      configuration.userData.userId,
                      Timestamp.now(),
                      AppLocalizations.of(context).translate(
                          "%DYNAMIC has invited you in a chat.",
                          dynamic: INFO_TYPE + configuration.userData.pseudo)),
                ],
              ));
          dialogQueryResult.clear();
          newChatGroupMembers.clear();
          Navigator.pop(context);
        } else {
          Vibrate.feedback(FeedbackType.warning);
          FlushbarHelper.createError(
                  message: AppLocalizations.of(context).translate(
                      "You should add at least one member to create a new chat!"),
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
      dialogQueryResult = await searchUsers(context, query, configuration, 0,
          verifyIfUsersAreFollowedOrFriends: false);
      print(query);
    } else if (configuration.userData.numberOfFriends > 0) {
      //return suggestions if user is not searching
      List<String> friendsListId =
          configuration.userData.friends.reversed.toList();
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
        dialogQueryResultUser.userId == configuration.userData.userId);

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
