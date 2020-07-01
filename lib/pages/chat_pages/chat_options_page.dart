import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/chatGroup.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/services/library/profilePictureWidget.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/theme.dart';

import 'chat_add_member_dialog.dart';

class ChatOptionsPage extends StatefulWidget {
  ChatOptionsPage({Key key, this.configuration, this.chatGroup, this.members})
      : super(key: key);

  final Configuration configuration;
  final ChatGroup chatGroup;
  final List<UserProfile> members;

  @override
  _ChatOptionsPageState createState() => _ChatOptionsPageState();
}

class _ChatOptionsPageState extends State<ChatOptionsPage> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
      appBar: showAppBar(),
      body: showBody(),
    );
  }

  AppBar showAppBar() {
    return AppBar();
  }

  Widget showBody() {
    return Stack(
      children: [
        isLoading ? Center(child: CircularProgressIndicator()) : Container(),
        ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
              widget.configuration.screenWidth / 20,
              widget.configuration.screenWidth / 20,
              widget.configuration.screenWidth / 20,
              0),
          children: [
            showAddMembersButtonWidget(),
            showChangeChatGroupPictureWidget(),
            showChatGroupNameFormWidget(),
            showSaveButtonWidget(),
            showQuitGroupButtonWidget(),
          ],
        ),
      ],
    );
  }

  Widget showAddMembersButtonWidget() {
    return Padding(
      padding: EdgeInsets.only(top: widget.configuration.screenWidth / 30),
      child: RaisedButton(
        onPressed: addMembers,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(AppLocalizations.of(context).translate("Add members")),
          Divider(
            indent: widget.configuration.screenWidth / 60,
          ),
          Icon(Icons.add_circle),
        ]),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(widget.configuration.screenWidth)),
      ),
    );
  }

  void addMembers() async {
    setState(() {
      isLoading = true;
    });
    List<UserProfile> newMembers = await ChatAddMemberDialog()
        .showChatAddMemberDialog(widget.configuration, widget.members, context);
    if (newMembers.length > 0) {
      if (await Database()
          .addMembersToChatGroup(context, widget.chatGroup.id, newMembers)) {
        String message =
            INFO_TYPE + widget.configuration.userData.pseudo + " added";
        newMembers.forEach((member) {
          message = "$message ${member.pseudo},";
          widget.chatGroup.membersIds.add(member.userId);
        });
        message =
            message.substring(0, message.length - 1); //delete the last ","
        message = "$message to the group.";
        widget.members.addAll(newMembers);

        Database().sendMessageToGroup(
            context,
            widget.configuration.userData,
            widget.chatGroup,
            Message(
                widget.configuration.userData.userId, Timestamp.now(), message),
            widget.members);
      }
    }
    isLoading = false;
    setState(() {});
  }

  Widget showChangeChatGroupPictureWidget() {
    return Padding(
      padding: EdgeInsets.only(top: widget.configuration.screenWidth / 60),
      child: Container(
        padding: EdgeInsets.all(widget.configuration.screenWidth / 60),
        decoration: BoxDecoration(
            color: PrimaryColor,
            borderRadius:
                BorderRadius.circular(widget.configuration.screenWidth / 10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ProfilePicture(
              downloadUrl: widget.chatGroup.pictureDownloadPath,
              hash: widget.chatGroup.pictureHash,
              isAnUser: false,
              size: widget.configuration.screenWidth / 5,
            ),
            RaisedButton(
              onPressed: changeChatGroupPicture,
              child: Text(
                AppLocalizations.of(context)
                    .translate("Change chat group picture"),
                style: TextStyle(fontSize: 12),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(widget.configuration.screenWidth)),
            ),
          ],
        ),
      ),
    );
  }

  void changeChatGroupPicture() async {
    setState(() {
      isLoading = true;
    });
    String storageRef = "ChatGroupsPicture/${widget.chatGroup.id}";
    print(storageRef);
    String hash = await Storage().getPhotoFromUserStorageAndUpload(
        storageRef: storageRef,
        context: context,
        letUserChooseImageSource: true,
        getBlurHash: true,
        compressQuality: 75,
        cropAspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        cropStyle: CropStyle.circle,
        maxHeight: 300,
        maxWidth: 300);
    if (hash != "error") {
      String url = await Storage().getUrlPhoto(storageRef);
      setState(() {
        widget.chatGroup.pictureDownloadPath = url;
        widget.chatGroup.pictureHash = hash;
        isLoading = false;
      });
      await Database().updateChatGroupOptions(context, widget.chatGroup);
    }
  }

  Widget showChatGroupNameFormWidget() {
    return Padding(
      padding: EdgeInsets.only(top: widget.configuration.screenWidth / 40),
      child: Container(
        padding: EdgeInsets.all(widget.configuration.screenWidth / 60),
        decoration: BoxDecoration(
            color: PrimaryColor,
            borderRadius:
                BorderRadius.circular(widget.configuration.screenWidth / 10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate("Chat group name:"),
              textAlign: TextAlign.center,
            ),
            Divider(
              height: widget.configuration.screenWidth / 30,
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: widget.configuration.screenWidth / 20),
              decoration: BoxDecoration(
                  border: Border.all(color: PrimaryColor),
                  borderRadius: BorderRadius.circular(
                      widget.configuration.screenWidth / 13),
                  color: transparentColor(PrimaryColorDark, 100)),
              child: TextFormField(
                initialValue: widget.chatGroup.name,
                onChanged: (value) => widget.chatGroup.name = value,
                maxLines: 1,
                maxLength: 30,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget showSaveButtonWidget() {
    return Padding(
      padding: EdgeInsets.only(top: widget.configuration.screenWidth / 60),
      child: RaisedButton(
        onPressed: saveChanges,
        child: Text(AppLocalizations.of(context).translate("Save")),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(widget.configuration.screenWidth)),
      ),
    );
  }

  void saveChanges() async {
    setState(() {
      isLoading = true;
    });
    if (widget.chatGroup.name.length >= 3 &&
        widget.chatGroup.name.length <= 30) {
      await Database().updateChatGroupOptions(context, widget.chatGroup);
      Navigator.pop(context);
    } else if (widget.chatGroup.name.length < 3 ||
        widget.chatGroup.name.length > 30) {
      FlushbarHelper.createError(
              message:
                  "Chat group name must be at least 3 characters and must not exceed 30 characters!")
          .show(context);
    }
    setState(() {
      isLoading = false;
    });
  }

  Widget showQuitGroupButtonWidget() {
    return Padding(
      padding: EdgeInsets.only(top: widget.configuration.screenWidth / 60),
      child: RaisedButton(
        onPressed: quitGroup,
        child: Text(AppLocalizations.of(context).translate("Leave the group")),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(widget.configuration.screenWidth)),
        color: Colors.red[900],
      ),
    );
  }

  void quitGroup() async {
    setState(() {
      isLoading = true;
    });
    if (await Database().leaveChatGroup(
        context, widget.configuration.userData.userId, widget.chatGroup.id)) {
      int count = 0;
      Navigator.of(context).popUntil((_) => count++ >= 2);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
}
