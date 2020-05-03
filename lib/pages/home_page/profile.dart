import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:the_spot/pages/inscription_page.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/deleteUser.dart';
import 'package:the_spot/services/library/UserProfile.dart';
import 'package:the_spot/services/library/configuration.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/services/library/library.dart';

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

  @override
  void initState() {
    super.initState();

    if (widget.userProfile.userId == widget.configuration.userData.userId)
      isUser = true;
    else
      isUser = false;
  }

  void signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  void uploadAvatar() async {
    print("add an Avatar");
    await Storage().getPhotoFromUserStorageAndUpload(
      storageRef: "ProfilePictures/" + widget.userProfile.userId,
      context: context,
      cropStyle: CropStyle.circle,
      cropAspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      maxHeight: 150,
      maxWidth: 150,
      compressQuality: 75,
    );

    String profilePictureDownloadPath = await Storage()
        .getUrlPhoto("ProfilePictures/" + widget.userProfile.userId);

    await Database().updateProfile(context, widget.userProfile.userId,
        profilePictureDownloadPath: profilePictureDownloadPath);

    setState(() {
      widget.userProfile.profilePictureDownloadPath =
          profilePictureDownloadPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
      appBar: showAppBar(),
      endDrawer: showDrawer(),
      body: Padding(
        padding: EdgeInsets.only(top: widget.configuration.screenWidth / 20),
        child: Column(
          children: <Widget>[
            showTopProfile(),
            showNUmberOfFriendsFollowersFollowing(),
            showSelectorButton(),
            showVideosLayout(),
          ],
        ),
      ),
    );
  }

  AppBar showAppBar() {
    if (isUser)
      return AppBar(
          backgroundColor: PrimaryColorDark,
          actions: <Widget>[
        Builder(builder: (BuildContext context) {
          return IconButton(
            icon: Hero(
                tag: 'optionButton_profilePage', child: Icon(Icons.settings)),
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
              showListTileButton("Edit my Profile", Icons.edit),
              showListTileButton('Clear cache', Icons.phonelink_erase),
              showListTileButton('SignOut', Icons.power_settings_new),
              showListTileButton('Delete my account', Icons.delete_forever),
              showListTileButton('App info', Icons.info_outline),
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

  Widget showListTileButton(String text, IconData icon) {
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
            switch (text) {
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
                signOut();
                break;
              case 'Delete my account':
                DeleteUser(widget.auth, widget.userProfile.userId,
                        widget.logoutCallback, context)
                    .showDeleteUserDataConfirmDialog();
                break;
              case 'App info':
                Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Widget showTopProfile() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PrimaryColorDark, PrimaryColor]
        )
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Container(
            padding:
                EdgeInsets.fromLTRB(widget.configuration.screenWidth / 40, 0, widget.configuration.screenWidth / 30, 0),
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
      tag: widget.userProfile.userId,
      child: GestureDetector(
        onTap: isUser ? uploadAvatar : null,
        child: Stack(overflow: Overflow.visible, children: <Widget>[
          ProfilePicture(widget.userProfile.profilePictureDownloadPath,
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
      child: Text(widget.userProfile.pseudo,
          style: TextStyle(
            color: PrimaryColorLight,
            fontSize: 30 * widget.configuration.textSizeFactor,
          )),
    );
  }

  Widget showUsernameWidget() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text('@' + widget.userProfile.username,
          style: TextStyle(color: SecondaryColorDark,
            fontSize: 16 * widget.configuration.textSizeFactor,)),
    );
  }

  Widget practiceButton(String practice) {
    bool isSelected = practice == "assets/images/Roller.png" &&
        widget.userProfile.Roller ||
        practice == "assets/images/BMX.png" && widget.userProfile.BMX ||
        practice == "assets/images/Skateboard.png" &&
            widget.userProfile.Skateboard ||
        practice == "assets/images/Scooter.png" &&
            widget.userProfile.Scooter;
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
            color: isSelected ? Colors.black : transparentColor(Colors.black, 40),
            width: widget.configuration.screenWidth / 15,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget showNUmberOfFriendsFollowersFollowing() {
    return Container(
      color: PrimaryColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, widget.configuration.screenWidth / 30, 0, widget.configuration.screenWidth / 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(
              width: widget.configuration.screenWidth / 3,
              child: Center(
                child: Text('Friends: ' + widget.userProfile.numberOfFriends.toString(),
                style: TextStyle(color: SecondaryColor, fontSize: 16 * widget.configuration.textSizeFactor),),
              ),
            ),
            Container(
              width: widget.configuration.screenWidth / 3,
              child: Center(
                child: Text('Followers: ' + widget.userProfile.numberOfFollowers.toString(),
                  style: TextStyle(color: SecondaryColor, fontSize: 16 * widget.configuration.textSizeFactor),),
              ),
            ),
            Container(
              width: widget.configuration.screenWidth / 3,
              child: Center(
                child: Text('Following: ' + widget.userProfile.numberOfFollowing.toString(),
                  style: TextStyle(color: SecondaryColor, fontSize: 16 * widget.configuration.textSizeFactor),),
              ),
            ),
          ],
        ),
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
              border: Border.all(width: 2, color: isInstaClipSelected ? PrimaryColor : PrimaryColorDark),
            ),
            padding: EdgeInsets.all(widget.configuration.screenWidth / 40),
            child: Icon(
              Icons.videocam,
              size: widget.configuration.screenWidth / 20,
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
              border: Border.all(width: 2, color: !isInstaClipSelected ? PrimaryColor : PrimaryColorDark),
            ),
            padding: EdgeInsets.all(widget.configuration.screenWidth / 40),
            child: Icon(
              Icons.phone_android,
              size: widget.configuration.screenWidth / 20,
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
        child: userHasVids ? ListView(
          children: <Widget>[],
        ) :
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Icon(
                    Icons.priority_high,
                    size: widget.configuration.screenWidth / 6,
                  ),
                ),
                Divider(height: widget.configuration.screenWidth / 20),
                Text('This user hasn\'t posted any vid for the moment', style: TextStyle(color: Colors.black, fontSize: 18 * widget.configuration.textSizeFactor),)
              ],
            )
      ),
    );
  }
}
