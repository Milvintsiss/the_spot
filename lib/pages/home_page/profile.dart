import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/home_page/followers_following_friends_page.dart';
import 'package:the_spot/pages/home_page/friend_requests_page.dart';
import 'package:the_spot/pages/inscription_page.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/deleteUser.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/services/library/library.dart';

import '../../about.dart';
import '../../theme.dart';

class Profile extends StatefulWidget {
  const Profile(
      {Key key,
      this.auth,
      this.userProfile,
      this.configuration,
      this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final UserProfile userProfile;
  final Configuration configuration;
  final VoidCallback logoutCallback;

  @override
  _Profile createState() => _Profile();
}

class _Profile extends State<Profile> {
  bool isUser;
  bool isInstaClipSelected = false;
  bool waitingForAcceptOrRefuse = false;
  bool waitForFollowing = false;
  bool requested = false;
  bool waitForSendingFriendRequest = false;

  UserProfile _userProfile;

  @override
  void initState() {
    super.initState();
    //listen to changes on user profile
    widget.configuration.addListener(onUserDataChanged);

    if (widget.userProfile.userId == widget.configuration.userData.userId) {
      isUser = true;
      _userProfile = widget.configuration.userData;
    } else {
      isUser = false;
      _userProfile = widget.userProfile;
    }
  }

  void onUserDataChanged() {
    if (isUser) _userProfile = widget.configuration.userData;
    setState(() {});
  }

  @override
  void dispose() {
    widget.configuration.removeListener(onUserDataChanged);
    super.dispose();
  }

  void uploadAvatar() async {
    print("add an Avatar");
    await Storage().getPhotoFromUserStorageAndUpload(
      storageRef: "ProfilePictures/" + _userProfile.userId,
      context: context,
      cropStyle: CropStyle.circle,
      cropAspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      maxHeight: 300,
      maxWidth: 300,
      compressQuality: 75,
    );

    String profilePictureDownloadPath =
        await Storage().getUrlPhoto("ProfilePictures/" + _userProfile.userId);

    await Database().updateProfile(context, _userProfile.userId,
        profilePictureDownloadPath: profilePictureDownloadPath);

    setState(() {
      _userProfile.profilePictureDownloadPath = profilePictureDownloadPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColor,
      appBar: showAppBar(),
      endDrawer: showDrawer(),
      body: Column(
        children: <Widget>[
          showTopProfile(),
          showNumberOfFriendsFollowersFollowing(),
          showFollowRequestRemoveFriendButtons(),
          showAcceptRefuseButtons(),
          showSelectorButton(),
          showVideosLayout(),
        ],
      ),
    );
  }

  AppBar showAppBar() {
    if (isUser)
      return AppBar(backgroundColor: PrimaryColorDark, actions: <Widget>[
        Stack(children: [
          Center(
            child: IconButton(
              icon: Icon(
                Icons.person_add,
                color: _userProfile.pendingFriendsId.length > 0
                    ? Colors.white
                    : Colors.black54,
              ),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        FriendRequestsPage(widget.configuration)));
                setState(() {});
              },
            ),
          ),
          _userProfile.pendingFriendsId.length > 0
              ? Positioned(
                  top: widget.configuration.screenWidth / 50,
                  right: 0,
                  child: Container(
                    width: widget.configuration.screenWidth / 20,
                    height: widget.configuration.screenWidth / 20,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.red),
                    child: Center(
                        child: Text(
                      widget.configuration.userData.pendingFriendsId.length
                          .toString(),
                      style: TextStyle(color: Colors.white),
                    )),
                  ),
                )
              : Container()
        ]),
        Builder(builder: (BuildContext context) {
          return IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        }),
      ]);
    else
      return AppBar(
        backgroundColor: PrimaryColorDark,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      );
  }

  Drawer showDrawer() {
    if (isUser)
      return Drawer(
        child: Container(
          color: PrimaryColorDark,
          child: ListView(
            children: <Widget>[
              showTopDrawer(),
              showListTileButton(AppLocalizations.of(context).translate("Edit my Profile"), 'Edit my Profile', Icons.edit),
              showListTileButton(AppLocalizations.of(context).translate("Clear cache"), 'Clear cache', Icons.phonelink_erase),
              showListTileButton(AppLocalizations.of(context).translate("SignOut"), 'SignOut', Icons.power_settings_new),
              showListTileButton(AppLocalizations.of(context).translate("Delete my account"), 'Delete my account', Icons.delete_forever),
              showListTileButton(AppLocalizations.of(context).translate("App info"), 'App info', Icons.info_outline),
            ],
          ),
        ),
      );
    else
      return null;
  }

  Widget showTopDrawer() {
    return Container(
      color: PrimaryColor,
      height: 55,
      child: ListTile(
        leading: Icon(
          Icons.settings,
          size: 40,
        ),
      ),
    );
  }

  Widget showListTileButton(String text, String type, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
                color: PrimaryColor, width: 2, style: BorderStyle.solid),
            borderRadius: BorderRadius.all(Radius.circular(30))),
        child: ListTile(
          title: Text(
            text,
            style: TextStyle(color: PrimaryColorLight),
          ),
          leading: Icon(
            icon,
            color: PrimaryColorLight,
          ),
          onTap: () async {
            switch (type) {
              case 'Edit my Profile':
                {
                  Navigator.pop(context);
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InscriptionPage(
                                configuration: widget.configuration,
                              )));
                  setState(() {});
                }
                break;
              case 'Clear cache':
                {
                  await DefaultCacheManager().emptyCache();
                  Navigator.pop(context);
                }
                break;
              case 'SignOut':
                {
                  Navigator.pop(context);
                  widget.configuration.logoutCallback();
                }
                break;
              case 'Delete my account':
                {
                  Navigator.pop(context);
                  DeleteUser(widget.configuration, context)
                      .showDeleteUserDataConfirmDialog();
                }
                break;
              case 'App info':
                {
                  Navigator.pop(context);
                  aboutDialog(context);
                }
                break;
            }
          },
        ),
      ),
    );
  }

  Widget showTopProfile() {
    return Container(
      padding: EdgeInsets.only(top: widget.configuration.screenWidth / 20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PrimaryColorDark, PrimaryColor])),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(widget.configuration.screenWidth / 40,
                0, widget.configuration.screenWidth / 30, 0),
            width: widget.configuration.screenWidth / 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                showPseudoWidget(),
                showUsernameWidget(),
              ],
            ),
          ),
          showAvatarWidget(),
          Container(
            width: widget.configuration.screenWidth / 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    practiceButton("assets/images/BMX.png"),
                    practiceButton("assets/images/Skateboard.png"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    practiceButton("assets/images/Scooter.png"),
                    practiceButton("assets/images/Roller.png"),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget showAvatarWidget() {
    return Hero(
      tag: _userProfile.userId,
      child: GestureDetector(
        onTap: isUser ? uploadAvatar : null,
        child: Stack(overflow: Overflow.visible, children: <Widget>[
          ProfilePicture(_userProfile.profilePictureDownloadPath,
              size: widget.configuration.screenWidth / 3,
              borderColor: PrimaryColor),
          isUser
              ? Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(
                    Icons.add_circle,
                    size: 40,
                    color: SecondaryColor,
                  ))
              : Container(),
        ]),
      ),
    );
  }

  Widget showPseudoWidget() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(_userProfile.pseudo,
          style: TextStyle(
            color: PrimaryColorLight,
            fontSize: 30 * widget.configuration.textSizeFactor,
          )),
    );
  }

  Widget showUsernameWidget() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text('@' + _userProfile.username,
          style: TextStyle(
            color: SecondaryColorDark,
            fontSize: 16 * widget.configuration.textSizeFactor,
          )),
    );
  }

  Widget practiceButton(String practice) {
    bool isSelected = practice == "assets/images/Roller.png" &&
            _userProfile.Roller ||
        practice == "assets/images/BMX.png" && _userProfile.BMX ||
        practice == "assets/images/Skateboard.png" && _userProfile.Skateboard ||
        practice == "assets/images/Scooter.png" && _userProfile.Scooter;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
        color: isSelected
            ? PrimaryColorLight
            : transparentColor(PrimaryColorLight, 40),
        child: Padding(
          padding: EdgeInsets.all(widget.configuration.screenWidth / 45),
          child: Image.asset(
            practice,
            color:
                isSelected ? Colors.black : transparentColor(Colors.black, 40),
            width: widget.configuration.screenWidth / 15,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget showNumberOfFriendsFollowersFollowing() {
    return Container(
      color: PrimaryColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, widget.configuration.screenWidth / 30,
            0, widget.configuration.screenWidth / 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _showNumberOfFriendsFollowersFollowing(
                _userProfile.numberOfFriends, AppLocalizations.of(context).translate("Friends"), 'Friends'),
            _showNumberOfFriendsFollowersFollowing(
                _userProfile.numberOfFollowers, AppLocalizations.of(context).translate("Followers"), 'Followers'),
            _showNumberOfFriendsFollowersFollowing(
                _userProfile.numberOfFollowing, AppLocalizations.of(context).translate("Following"), 'Following'),
          ],
        ),
      ),
    );
  }

  Widget _showNumberOfFriendsFollowersFollowing(int value, String text, String type) {
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FollowersFollowingFriendsPage(
                  configuration: widget.configuration,
                  userProfile: _userProfile,
                  type: type,
                )));
        setState(() {});
      },
      child: Container(
        width: widget.configuration.screenWidth / 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                  color: SecondaryColor,
                  fontSize: 21 * widget.configuration.textSizeFactor),
            ),
            Text(
              text,
              style: TextStyle(
                  color: SecondaryColor,
                  fontSize: 13 * widget.configuration.textSizeFactor),
            ),
          ],
        ),
      ),
    );
  }

  Widget showFollowRequestRemoveFriendButtons() {
    if (isUser ||
        widget.configuration.userData.pendingFriendsId
            .contains(_userProfile.userId))
      return Container();
    else
      return ButtonTheme(
        minWidth: 0,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(widget.configuration.screenWidth / 10)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: widget.configuration.screenWidth / 50),
          child: Row(
            children: <Widget>[
              showFollowButton(),
              Divider(
                indent: widget.configuration.screenWidth / 50,
              ),
              showAddRemoveFriendButton(),
            ],
          ),
        ),
      );
  }

  Widget showFollowButton() {
    return Expanded(
      child: RaisedButton(
        color: _userProfile.isFollowed
            ? PrimaryColor
            : transparentColor(SecondaryColor, 100),
        child: waitForFollowing
            ? SizedBox(
                height: widget.configuration.screenWidth / 30,
                width: widget.configuration.screenWidth / 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(PrimaryColorLight),
                ),
              )
            : Text(
                _userProfile.isFollowed ? AppLocalizations.of(context).translate("Unfollow") : AppLocalizations.of(context).translate("Follow"),
                style: TextStyle(
                    fontSize: 12 * widget.configuration.textSizeFactor,
                    color: !_userProfile.isFollowed
                        ? Colors.black
                        : Colors.black54),
              ),
        onPressed: waitForFollowing
            ? null
            : () async {
                setState(() {
                  waitForFollowing = true;
                });
                if (_userProfile.isFollowed) {
                  await Database().unFollowUser(
                      context,
                      widget.configuration.userData.userId,
                      _userProfile.userId);
                  widget.userProfile.isFollowed = false;
                  widget.userProfile.numberOfFollowers--;
                } else {
                  await Database().followUser(
                      context,
                      widget.configuration.userData.userId,
                      _userProfile.userId);
                  widget.userProfile.isFollowed = true;
                  widget.userProfile.numberOfFollowers++;
                }
                waitForFollowing = false;
                setState(() {});
              },
      ),
    );
  }

  Widget showAddRemoveFriendButton() {
    if (_userProfile.pendingFriendsId
        .contains(widget.configuration.userData.userId)) requested = true;
    if (_userProfile.isFriend) {
      return Expanded(
        child: RaisedButton(
          color: PrimaryColor,
          child: waitForSendingFriendRequest
              ? SizedBox(
                  height: widget.configuration.screenWidth / 30,
                  width: widget.configuration.screenWidth / 30,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(PrimaryColorLight),
                  ),
                )
              : Text(
                  AppLocalizations.of(context).translate("Remove"),
                  style: TextStyle(
                      fontSize: 12 * widget.configuration.textSizeFactor,
                      color: Colors.black54),
                ),
          onPressed: waitForSendingFriendRequest
              ? null
              : () async {
                  setState(() {
                    waitForSendingFriendRequest = true;
                  });
                  await Database().removeFriend(
                      context,
                      widget.configuration.userData.userId,
                      _userProfile.userId);
                  widget.userProfile.isFriend = false;
                  setState(() {
                    waitForSendingFriendRequest = false;
                    _userProfile.isFriend = false;
                  });
                },
        ),
      );
    } else {
      return Expanded(
        child: RaisedButton(
          color:
              requested ? PrimaryColor : transparentColor(SecondaryColor, 100),
          child: waitForSendingFriendRequest
              ? SizedBox(
                  height: widget.configuration.screenWidth / 30,
                  width: widget.configuration.screenWidth / 30,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(PrimaryColorLight),
                  ),
                )
              : Text(
                  !requested ? AppLocalizations.of(context).translate("Add+") : AppLocalizations.of(context).translate("Requested"),
                  style: TextStyle(
                      fontSize: 12 * widget.configuration.textSizeFactor,
                      color: !requested ? Colors.black : Colors.black54),
                ),
          onPressed: waitForSendingFriendRequest
              ? null
              : () async {
                  setState(() {
                    waitForSendingFriendRequest = true;
                  });
                  if (!requested) {
                    await Database().sendFriendRequest(
                        context,
                        mainUser: widget.configuration.userData,
                        userToAdd: _userProfile);
                    requested = true;
                  } else {
                    await Database().removeFriendRequest(
                        context,
                        widget.configuration.userData.userId,
                        _userProfile.userId);
                    requested = false;
                  }
                  waitForSendingFriendRequest = false;
                  setState(() {});
                },
        ),
      );
    }
  }

  Widget showAcceptRefuseButtons() {
    if (!isUser &&
        widget.configuration.userData.pendingFriendsId
            .contains(_userProfile.userId)) if (waitingForAcceptOrRefuse)
      return SizedBox(
        height: widget.configuration.screenWidth / 20,
        width: widget.configuration.screenWidth / 20,
        child: CircularProgressIndicator(),
      );
    else
      return ButtonTheme(
        minWidth: 0,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(widget.configuration.screenWidth / 10)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: widget.configuration.screenWidth / 50),
          child: Row(
            children: <Widget>[
              showRefuseButton(),
              Divider(
                indent: widget.configuration.screenWidth / 50,
              ),
              showAcceptButton(),
            ],
          ),
        ),
      );
    else
      return Container();
  }

  Widget showAcceptButton() {
    return Expanded(
      child: RaisedButton(
        color: Colors.green,
        child: Text(
          AppLocalizations.of(context).translate("Accept"),
          style: TextStyle(
              fontSize: 12 * widget.configuration.textSizeFactor,
              color: Colors.white),
        ),
        onPressed: () async {
          setState(() {
            waitingForAcceptOrRefuse = true;
          });
          await Database().acceptFriendRequest(context,
              widget.configuration.userData.userId, _userProfile.userId);
          _userProfile.isFriend = true;
          waitingForAcceptOrRefuse = false;
          setState(() {});
        },
      ),
    );
  }

  Widget showRefuseButton() {
    return Expanded(
      child: RaisedButton(
        color: Colors.red,
        child: Text(
          AppLocalizations.of(context).translate("Refuse"),
          style: TextStyle(
              fontSize: 12 * widget.configuration.textSizeFactor,
              color: Colors.white),
        ),
        onPressed: () async {
          setState(() {
            waitingForAcceptOrRefuse = true;
          });

          await Database().refuseFriendRequest(context,
              widget.configuration.userData.userId, _userProfile.userId);

          waitingForAcceptOrRefuse = false;
          setState(() {});
        },
      ),
    );
  }

  Widget showSelectorButton() {
    return Row(
      children: <Widget>[
        InkWell(
          onTap: () => setState(() {
            isInstaClipSelected = false;
          }),
          child: Container(
            width: widget.configuration.screenWidth / 2,
            decoration: BoxDecoration(
              color: isInstaClipSelected ? PrimaryColor : PrimaryColorLight,
              border: Border.all(
                  width: 2,
                  color: isInstaClipSelected ? PrimaryColor : PrimaryColorDark),
            ),
            padding: EdgeInsets.all(widget.configuration.screenWidth / 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.videocam,
                  size: widget.configuration.screenWidth / 20,
                  color: isInstaClipSelected ? Colors.black : Colors.white70,
                ),
                Text('Edits',
                    style: TextStyle(
                        color:
                            isInstaClipSelected ? Colors.black : Colors.white70,
                        fontSize: 12 * widget.configuration.textSizeFactor))
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => setState(() {
            isInstaClipSelected = true;
          }),
          child: Container(
            width: widget.configuration.screenWidth / 2,
            decoration: BoxDecoration(
              color: !isInstaClipSelected ? PrimaryColor : PrimaryColorLight,
              border: Border.all(
                  width: 2,
                  color:
                      !isInstaClipSelected ? PrimaryColor : PrimaryColorDark),
            ),
            padding: EdgeInsets.all(widget.configuration.screenWidth / 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.phone_android,
                  size: widget.configuration.screenWidth / 20,
                  color: isInstaClipSelected ? Colors.white70 : Colors.black,
                ),
                Center(
                  child: Text(
                    'InstaClips',
                    style: TextStyle(
                        color:
                            isInstaClipSelected ? Colors.white70 : Colors.black,
                        fontSize: 12 * widget.configuration.textSizeFactor),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget showVideosLayout() {
    bool userHasVids = false;
    return Expanded(
      child: Container(
          color: PrimaryColorLight,
          child: userHasVids
              ? ListView(
                  children: <Widget>[],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: Icon(
                        Icons.priority_high,
                        size: widget.configuration.screenWidth / 6,
                      ),
                    ),
                    Divider(height: widget.configuration.screenWidth / 20),
                    Text(
                      AppLocalizations.of(context).translate("This user hasn't posted any vid for the moment"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18 * widget.configuration.textSizeFactor),
                    )
                  ],
                )),
    );
  }
}
