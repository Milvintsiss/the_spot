import 'package:flutter/material.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/home_page/profile.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/configuration.dart';

import '../../theme.dart';
import '../database.dart';
import 'library.dart';

class UsersListView extends StatefulWidget {
  final Configuration configuration;
  final List<UserProfile> query;
  final Function onBottomListReachedCallback;

  const UsersListView(
      {Key key,
      this.configuration,
      this.query,
      this.onBottomListReachedCallback})
      : super(key: key);

  @override
  _UsersListViewState createState() => _UsersListViewState();
}

class _UsersListViewState extends State<UsersListView> {
  double spaceBetweenItems;
  double itemsSize;

  ScrollController scrollController = ScrollController();

  List<bool> waitForFollowing = [];
  List<bool> friendRequestAlreadyDone = [];
  List<bool> waitForSendingAcceptFriendRequest = [];

  int initialItemsCount;

  bool scrollDisabled = false;
  bool isLoadingData = false;

  @override
  void initState() {
    super.initState();
    widget.configuration.addListener(onUserDataChanged);
    spaceBetweenItems = widget.configuration.screenWidth / 60;
    itemsSize = widget.configuration.screenWidth / 6.5;
    init();
  }

  @override
  void didUpdateWidget(UsersListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    init();
  }

  void onUserDataChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.configuration.removeListener(onUserDataChanged);
    super.dispose();
  }

  void init() {
    waitForFollowing.clear();
    widget.query.forEach((element) {
      waitForFollowing.add(false);
      waitForSendingAcceptFriendRequest.add(false);
      if (element.pendingFriendsId
              .indexOf(widget.configuration.userData.userId) !=
          -1) {
        friendRequestAlreadyDone.add(true);
      } else {
        friendRequestAlreadyDone.add(false);
      }
    });
    print(widget.query.length);
  }

  void onBottomListReached() async {
    if (!scrollDisabled) {
      setState(() {
        isLoadingData = true;
      });
      Future.delayed(Duration.zero, () {
        scrollController.animateTo(
            scrollController.position.maxScrollExtent + 10,
            duration: Duration(milliseconds: 500),
            curve: Curves.ease);
      });
      await widget.onBottomListReachedCallback();
      setState(() {
        isLoadingData = false;
      });
      await Future.delayed(Duration(milliseconds: 1200));
      scrollDisabled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            onBottomListReached();
            scrollDisabled = true;
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
                  widget.configuration.screenWidth / 20),
              itemCount: widget.query.length,
              itemBuilder: (BuildContext context, int itemIndex) {
                return showResultWidget(itemIndex);
              },
              shrinkWrap: true,
              physics: ScrollPhysics(),
            ),
            isLoadingData
                ? Center(child: CircularProgressIndicator())
                : Container()
          ],
          physics:
              AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        ),
      ),
    );
  }

  Widget showResultWidget(int index) {
    bool isUser = false;
    bool hasSendAFriendRequest = false;
    if (widget.query[index].userId == widget.configuration.userData.userId)
      isUser = true;
    if (widget.configuration.userData.pendingFriendsId
        .contains(widget.query[index].userId)) hasSendAFriendRequest = true;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Profile(
                      configuration: widget.configuration,
                      userProfile: widget.query[index],
                    )));
        setState(() {});
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, spaceBetweenItems, 0, 0),
        child: Container(
          padding: EdgeInsets.all(widget.configuration.screenWidth / 60),
          height: itemsSize,
          decoration: BoxDecoration(
            color: PrimaryColorLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Hero(
                  tag: widget.query[index].userId,
                  child: ProfilePicture(
                      widget.query[index].profilePictureDownloadPath,
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
                      widget.query[index].pseudo,
                      style: TextStyle(
                          fontSize: 15 * widget.configuration.textSizeFactor),
                    ),
                    Text(
                      "@" + widget.query[index].username,
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
                    isUser ? Container() : showFollowButton(index),
                    Divider(
                      indent: widget.configuration.screenWidth / 60,
                    ),
                    isUser
                        ? Container()
                        : hasSendAFriendRequest
                            ? showAcceptButton(index)
                            : showAddFriendButton(index),
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
      child: waitForSendingAcceptFriendRequest[index]
          ? SizedBox(
              height: widget.configuration.screenWidth / 30,
              width: widget.configuration.screenWidth / 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PrimaryColorDark),
              ),
            )
          : Text(
              AppLocalizations.of(context).translate("Accept"),
              style: TextStyle(
                  fontSize: 12 * widget.configuration.textSizeFactor,
                  color: Colors.white),
            ),
      onPressed: () async {
        setState(() {
          waitForSendingAcceptFriendRequest[index] = true;
        });
        await Database().acceptFriendRequest(context,
            widget.configuration.userData.userId, widget.query[index].userId);
        waitForSendingAcceptFriendRequest[index] = false;
        setState(() {});
      },
    );
  }

  Widget showFollowButton(int index) {
    return RaisedButton(
      color: widget.query[index].isFollowed
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
              widget.query[index].isFollowed ? AppLocalizations.of(context).translate("Unfollow") : AppLocalizations.of(context).translate("Follow"),
              style: TextStyle(
                  fontSize: 12 * widget.configuration.textSizeFactor,
                  color: !widget.query[index].isFollowed
                      ? Colors.black
                      : Colors.black54),
            ),
      onPressed: waitForFollowing[index]
          ? null
          : () async {
              setState(() {
                waitForFollowing[index] = true;
              });
              if (widget.query[index].isFollowed) {
                await Database().unFollowUser(
                    context,
                    widget.configuration.userData.userId,
                    widget.query[index].userId);
                widget.query[index].isFollowed = false;
                widget.query[index].numberOfFollowers--;
              } else {
                await Database().followUser(
                    context,
                    widget.configuration.userData.userId,
                    widget.query[index].userId);
                widget.query[index].isFollowed = true;
                widget.query[index].numberOfFollowers++;
              }
              waitForFollowing[index] = false;
              setState(() {});
            },
    );
  }

  Widget showAddFriendButton(int index) {
    if (widget.query[index].isFriend) {
      return Icon(
        Icons.check,
      );
    } else {
      return RaisedButton(
        color: friendRequestAlreadyDone[index]
            ? transparentColor(SecondaryColor, 100)
            : PrimaryColor,
        child: waitForSendingAcceptFriendRequest[index]
            ? SizedBox(
                height: widget.configuration.screenWidth / 30,
                width: widget.configuration.screenWidth / 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(PrimaryColorDark),
                ),
              )
            : Text(
                !friendRequestAlreadyDone[index] ? AppLocalizations.of(context).translate("Add+") : AppLocalizations.of(context).translate("Requested"),
                style: TextStyle(
                    fontSize: 12 * widget.configuration.textSizeFactor,
                    color: !friendRequestAlreadyDone[index]
                        ? Colors.black
                        : Colors.black54),
              ),
        onPressed: waitForSendingAcceptFriendRequest[index]
            ? null
            : () async {
                setState(() {
                  waitForSendingAcceptFriendRequest[index] = true;
                });
                if (!friendRequestAlreadyDone[index]) {
                  await Database().sendFriendRequest(
                      context,
                      mainUser: widget.configuration.userData,
                      userToAdd: widget.query[index]);
                  widget.query[index].pendingFriendsId.add(widget.configuration.userData.userId);
                } else {
                  await Database().removeFriendRequest(
                      context,
                      widget.configuration.userData.userId,
                      widget.query[index].userId);
                  widget.query[index].pendingFriendsId.remove(widget.configuration.userData.userId);
                }
                friendRequestAlreadyDone[index] =
                    !friendRequestAlreadyDone[index];
                waitForSendingAcceptFriendRequest[index] = false;
                setState(() {});
              },
      );
    }
  }
}
