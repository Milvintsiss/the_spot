
import 'package:flutter/material.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/searchBar.dart';
import 'package:the_spot/services/library/userItem.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/search_engine.dart';

import '../../app_localizations.dart';
import '../../theme.dart';

class ChatAddMemberDialog {
  Configuration configuration;
  StateSetter dialogStateSetter;
  BuildContext context;
  bool dialogIsLoadingUsers = false;
  List<UserProfile> currentMembers = [];
  List<UserProfile> dialogQueryResult = [];
  List<UserProfile> newChatGroupMembers = [];

  Future<List<UserProfile>> showChatAddMemberDialog(
    Configuration _configuration,
    List<UserProfile> _currentMembers,
    BuildContext _context,
  ) async {
    configuration = _configuration;
    currentMembers = _currentMembers;
    context = _context;

    AlertDialog chatAddMemberDialog = AlertDialog(
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
                showChatCreationDialogMembersWidget(),
                Padding(
                  padding: EdgeInsets.only(top: configuration.screenWidth / 60),
                ),
                SearchBar(chatAddMemberDialogSearchCallback,
                    sizeFactor: configuration.screenWidth / 12,
                    textSize: 14 * configuration.textSizeFactor),
                Padding(
                  padding: EdgeInsets.only(top: configuration.screenWidth / 60),
                ),
                showChatAddMemberDialogSearchedUsers(),
                showChatAddMemberDialogAddButton(),
              ],
            ),
          );
        },
      ),
    );
    await showDialog(
      context: context,
      child: chatAddMemberDialog,
    );
    return newChatGroupMembers;
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
              for (UserProfile userProfile in currentMembers)
                Padding(
                  padding: EdgeInsets.all(configuration.screenWidth / 300),
                  child: UserItem(
                    user: userProfile,
                    sizeReference: configuration.screenWidth,
                    textSizeReference: configuration.textSizeFactor,
                    isDeletable: false,
                  ),
                ),
              for (UserProfile userProfile in newChatGroupMembers)
                Padding(
                  padding: EdgeInsets.all(configuration.screenWidth / 300),
                  child: UserItem(
                    user: userProfile,
                    sizeReference: configuration.screenWidth,
                    textSizeReference: configuration.textSizeFactor,
                    isDeletable: true,
                    deleteCallback: chatAddMemberDialogUserDeleteCallback,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget showChatAddMemberDialogSearchedUsers() {
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
                  clickCallback: chatAddMemberDialogUserClickCallback,
                ),
              );
            }),
      );
    else
      chatAddMemberDialogSearchCallback(null);
    return SizedBox(
      height: configuration.screenWidth / 30,
      width: configuration.screenWidth / 30,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget showChatAddMemberDialogAddButton() {
    return RaisedButton(
      child: Text(AppLocalizations.of(context).translate("Add")),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  void chatAddMemberDialogSearchCallback(String query) async {
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
        currentMembers.indexWhere((currentChatGroupMembersUser) =>
                currentChatGroupMembersUser.userId ==
                dialogQueryResultUser.userId) !=
            -1 ||
        dialogQueryResultUser.userId == configuration.userData.userId);

    dialogStateSetter(() {
      dialogIsLoadingUsers = false;
    });
  }

  void chatAddMemberDialogUserClickCallback(UserProfile user) {
    dialogStateSetter(() {
      dialogQueryResult.remove(user);
      newChatGroupMembers.add(user);
    });
  }

  void chatAddMemberDialogUserDeleteCallback(UserProfile user) {
    dialogStateSetter(() {
      newChatGroupMembers.remove(user);
    });
  }
}
