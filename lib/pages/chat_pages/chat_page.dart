import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as dateFormat;
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/chat_pages/chat_options_page.dart';
import 'package:the_spot/pages/home_page/profile.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/blurhash_encoding.dart';
import 'package:the_spot/services/library/chatGroup.dart';
import 'package:the_spot/services/library/profilePictureWidget.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/theme.dart';

class ChatPage extends StatefulWidget {
  final Configuration configuration;
  final ChatGroup chatGroup;

  const ChatPage(
      {Key key, @required this.configuration, @required this.chatGroup})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ScrollController scrollController = ScrollController();

  ChatGroup chatGroup;
  List<UserProfile> members = [];

  String newMessage = "";
  TextEditingController sendBoxController = TextEditingController();

  bool membersDataIsLoaded = false;
  bool userReachedTheBottomOfTheList = true;
  List<bool> showHour = [];

  StreamSubscription chatGroupStream;

  @override
  void initState() {
    super.initState();
    chatGroup = widget.chatGroup;
    initiateChatGroupStream();
    getChatGroupUsers();
  }

  @override
  void dispose() {
    chatGroupStream.cancel();
    super.dispose();
  }

  void initiateChatGroupStream() {
    chatGroupStream = Firestore.instance
        .collection('groupChats')
        .document(widget.chatGroup.id)
        .snapshots()
        .listen((document) async {
      if (document.exists) {
        chatGroup = convertMapToChatGroup(document.data);
        chatGroup.id = widget.chatGroup.id;
        chatGroup.messages
            .forEach((message) => message.setMessageTypeAndTransformData());
        chatGroup.messages = chatGroup.messages.reversed.toList();
        showHour.clear();
        chatGroup.messages.forEach((message) {
          showHour.add(false);
        });
        setState(() {});
        if (userReachedTheBottomOfTheList) {
//          scrollController.animateTo(
//              scrollController.position.maxScrollExtent +
//                  widget.configuration.screenHeight,
//              duration: Duration(seconds: 1),
//              curve: Curves.ease);
        }
      }
    });
  }

  void getChatGroupUsers() async {
    List<String> usersId = chatGroup.membersIds;
    usersId.removeWhere((id) => id == widget.configuration.userData.userId);
    members = await Database().getUsersByIds(context, usersId,
        verifyIfFriendsOrFollowed: true,
        mainUserId: widget.configuration.userData.userId);
    setState(() {
      membersDataIsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimaryColorDark,
      appBar: showAppBar(),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          showMessagesList(),
          showBottomTools(),
        ],
      ),
    );
  }

  AppBar showAppBar() {
    return AppBar(
      title: GestureDetector(
        onTap: !widget.chatGroup.isGroup && membersDataIsLoaded
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Profile(
                          configuration: widget.configuration,
                          userProfile: members[0],
                        )))
            : null,
        child: Row(
          children: [
            widget.chatGroup.isGroup
                ? ProfilePicture(
                    downloadUrl: chatGroup.pictureDownloadPath,
                    hash: chatGroup.pictureHash,
                    background: PrimaryColorDark,
                    isAnUser: false,
                  )
                : ProfilePicture(
                    downloadUrl:
                        widget.chatGroup.members[0].profilePictureDownloadPath,
                    hash: widget.chatGroup.members[0].profilePictureHash,
                    background: PrimaryColorDark,
                  ),
            Divider(
              indent: widget.configuration.screenWidth / 20,
            ),
            Expanded(
              child: Text(widget.chatGroup.isGroup
                  ? chatGroup.name
                  : widget.chatGroup.members[0].pseudo),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: membersDataIsLoaded
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChatOptionsPage(
                            configuration: widget.configuration,
                            chatGroup: chatGroup,
                            members: members,
                          )))
              : null,
        ),
      ],
    );
  }

  Widget showMessagesList() {
    return Expanded(
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: onListNotification,
            child: ListView.builder(
                reverse: true,
                controller: scrollController,
                padding: EdgeInsets.symmetric(
                    horizontal: widget.configuration.screenWidth / 40,
                    vertical: widget.configuration.screenWidth / 20),
                itemCount: chatGroup.messages.length,
                itemBuilder: (context, index) {
                  if (index != chatGroup.messages.length - 1 &&
                      chatGroup.messages[index].date.toDate().day >
                          chatGroup.messages[index + 1].date.toDate().day) {
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: widget.configuration.screenWidth / 60),
                          child: Text(
                            dateFormat.DateFormat(
                                    'MMMMEEEEd',
                                    AppLocalizations.of(context)
                                        .locale
                                        .toString())
                                .format(chatGroup.messages[index].date.toDate()),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        showMessage(index),
                      ],
                    );
                  } else
                    return showMessage(index);
                }),
          ),
          userReachedTheBottomOfTheList ? Container() : showNewMessagesButton()
        ],
      ),
    );
  }

  bool onListNotification(ScrollNotification scrollNotification) {
    if (scrollNotification.metrics.pixels <
        (scrollNotification.metrics.minScrollExtent +
            widget.configuration.screenHeight)) {
      setState(() {
        userReachedTheBottomOfTheList = true;
      });
    } else {
      setState(() {
        userReachedTheBottomOfTheList = false;
      });
    }
    return true;
  }

  Widget showMessage(int index) {
    UserProfile sender;
    bool isUserMessage = chatGroup.messages[index].senderId ==
        widget.configuration.userData.userId;
    if (!isUserMessage && membersDataIsLoaded)
      sender = members.firstWhere(
          (member) => member.userId == chatGroup.messages[index].senderId);

    if (chatGroup.messages[index].messageType == MessageType.INFO)
      return Padding(
        padding: EdgeInsets.only(
          bottom: widget.configuration.screenWidth / 40,
        ),
        child: Center(
          child: Text(chatGroup.messages[index].data2,
              style: TextStyle(
                  fontSize: 14 * widget.configuration.textSizeFactor)),
        ),
      );
    else {
      return Padding(
        padding: EdgeInsets.only(
          bottom: widget.configuration.screenWidth / 40,
          right: isUserMessage ? 0 : widget.configuration.screenWidth / 5,
          left: isUserMessage ? widget.configuration.screenWidth / 5 : 0,
        ),
        child: Column(
          crossAxisAlignment:
              isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => showHour[index] = !showHour[index]),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      end: isUserMessage
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      colors: [PrimaryColor, PrimaryColorLight],
                      stops: [0, 0.5]),
                  borderRadius: BorderRadius.circular(
                      widget.configuration.screenWidth / 10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isUserMessage
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  textDirection:
                      isUserMessage ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    GestureDetector(
                      onTap: membersDataIsLoaded
                          ? isUserMessage
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Profile(
                                            configuration: widget.configuration,
                                            userProfile: members.firstWhere(
                                                (member) =>
                                                    member.userId ==
                                                    chatGroup.messages[index]
                                                        .senderId),
                                          )))
                          : null,
                      child: ProfilePicture(
                        downloadUrl: isUserMessage
                            ? widget.configuration.userData
                                .profilePictureDownloadPath
                            : membersDataIsLoaded
                                ? sender.profilePictureDownloadPath
                                : null,
                        hash: isUserMessage
                            ? widget.configuration.userData.profilePictureHash
                            : membersDataIsLoaded
                                ? sender.profilePictureHash
                                : null,
                      ),
                    ),
                    chatGroup.messages[index].messageType == MessageType.TEXT
                        ? Flexible(
                            fit: FlexFit.loose,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                  isUserMessage
                                      ? widget.configuration.screenWidth / 15
                                      : widget.configuration.screenWidth / 30,
                                  widget.configuration.screenWidth / 80,
                                  isUserMessage
                                      ? widget.configuration.screenWidth / 30
                                      : widget.configuration.screenWidth / 15,
                                  widget.configuration.screenWidth / 80),
                              child: Text(
                                chatGroup.messages[index].data,
                                style: TextStyle(
                                    fontSize: 14 *
                                        widget.configuration.textSizeFactor),
                              ),
                            ),
                          )
                        : chatGroup.messages[index].messageType ==
                                MessageType.PICTURE
                            ? Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.horizontal(
                                      left: isUserMessage
                                          ? Radius.circular(
                                              widget.configuration.screenWidth /
                                                  10)
                                          : Radius.zero,
                                      right: isUserMessage
                                          ? Radius.zero
                                          : Radius.circular(
                                              widget.configuration.screenWidth /
                                                  10)),
                                  child: chatGroup.messages[index].hash != null
                                      ? SizedBlurHash(
                                          pictureDownloadUrl:
                                              chatGroup.messages[index].data2,
                                          hashWithSize:
                                              chatGroup.messages[index].hash,
                                          width:
                                              widget.configuration.screenWidth *
                                                  3 /
                                                  5,
                                        )
                                      : Image.network(
                                          chatGroup.messages[index].data2,
                                        ),
                                ),
                              )
                            : Container(),
                  ],
                ),
              ),
            ),
            showHour[index]
                ? Text(
                    "${chatGroup.messages[index].date.toDate().toLocal().toIso8601String().substring(11, 16)}")
                : Container(),
          ],
        ),
      );
    }
  }

  Widget showNewMessagesButton() {
    return Positioned(
      bottom: widget.configuration.screenWidth / 60,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          child: Container(
            padding: EdgeInsets.all(widget.configuration.screenWidth / 50),
            decoration: BoxDecoration(
                color: PrimaryColor,
                border: Border.all(
                    color: SecondaryColorLight,
                    width: widget.configuration.screenWidth / 300),
                borderRadius:
                    BorderRadius.circular(widget.configuration.screenWidth)),
            child: Text(
                AppLocalizations.of(context).translate("show new messages")),
          ),
          onTap: () {
            scrollController.animateTo(
                scrollController.position.minScrollExtent,
                duration: Duration(seconds: 1),
                curve: Curves.ease);
          },
        ),
      ),
    );
  }

  Widget showBottomTools() {
    return Container(
      height: widget.configuration.screenHeight / 11,
      color: PrimaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          showSendPictureFromCameraButton(),
          showSendPictureFromStorageButton(),
          showSendVoiceRecordButton(),
          showSendMessageEditor(),
          showSendButton(),
        ],
      ),
    );
  }

  Widget showSendPictureFromCameraButton() {
    return IconButton(
      icon: Icon(Icons.photo_camera),
      onPressed: () => sendPicture(false),
    );
  }

  Widget showSendPictureFromStorageButton() {
    return IconButton(
      icon: Icon(Icons.image),
      onPressed: () => sendPicture(true),
    );
  }

  Widget showSendVoiceRecordButton() {
    return IconButton(
      icon: Icon(Icons.keyboard_voice),
      onPressed: () {},
    );
  }

  void sendPicture(bool getPhotoFromGallery) async {
    if (membersDataIsLoaded) {
      String storageRef =
          "ChatGroupsStorage/${widget.chatGroup.id}/${Timestamp.now().millisecondsSinceEpoch}${math.Random().nextInt(999999)}";
      print(storageRef);
      String hash = await Storage().getPhotoFromUserStorageAndUpload(
        storageRef: storageRef,
        context: context,
        getPhotoFromGallery: getPhotoFromGallery,
        letUserChooseImageSource: false,
        getBlurHash: true,
      );
      if (hash != "error") {
        String url = await Storage().getUrlPhoto(storageRef);
        String message = PICTURE_TYPE +
            AppLocalizations.of(context).translate("%DYNAMIC sent a picture",
                dynamic: widget.configuration.userData.pseudo) +
            PICTURE_TYPE +
            url +
            PICTURE_TYPE +
            hash;
        Database().sendMessageToGroup(
            context,
            widget.configuration.userData,
            widget.chatGroup,
            Message(
                widget.configuration.userData.userId, Timestamp.now(), message),
            members);
      }
    }
  }

  Widget showSendMessageEditor() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(widget.configuration.screenHeight / 100),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: PrimaryColorLight,
              border: Border.all(
                  color: PrimaryColorDark,
                  width: widget.configuration.screenWidth / 300),
              borderRadius:
                  BorderRadius.circular(widget.configuration.screenWidth)),
          child: membersDataIsLoaded
              ? TextField(
                  minLines: 1,
                  maxLines: 10,
                  maxLength: 1000,
                  textAlignVertical: TextAlignVertical.center,
                  controller: sendBoxController,
                  onChanged: (value) => newMessage = value.trim(),
                  onSubmitted: (value) => sendMessage(),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12 * widget.configuration.textSizeFactor),
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    counterText: "",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.configuration.screenWidth / 25,
                      vertical: widget.configuration.screenHeight / 50,
                    ),
                    hintText: AppLocalizations.of(context)
                        .translate("Send a message..."),
                    hintMaxLines: 1,
                    hintStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 12 * widget.configuration.textSizeFactor),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                )
              : Padding(
                  padding:
                      EdgeInsets.all(widget.configuration.screenHeight / 50),
                  child: CircularProgressIndicator(),
                ),
        ),
      ),
    );
  }

  Widget showSendButton() {
    return IconButton(
      icon: Icon(Icons.send),
      onPressed: sendMessage,
    );
  }

  void sendMessage() async {
    if (newMessage != "" && newMessage != null && membersDataIsLoaded) {
      Database().sendMessageToGroup(
          context,
          widget.configuration.userData,
          widget.chatGroup,
          Message(widget.configuration.userData.userId, Timestamp.now(),
              newMessage),
          members);
      sendBoxController.clear();
      newMessage = "";
    }
  }
}
