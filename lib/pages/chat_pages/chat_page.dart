import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/chatGroup.dart';
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
  ChatGroup chatGroup;

  StreamSubscription chatGroupStream;

  @override
  void initState() {
    super.initState();
    chatGroup = widget.chatGroup;
    initiateChatGroupStream();
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
        .listen((document) {
      if (document.exists) {
        setState(() {
          chatGroup = convertMapToChatGroup(document.data);
        });
      }
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
      title: Text(chatGroup.name),
    );
  }

  Widget showMessagesList() {
    return Expanded(
      child: ListView.builder(
          padding: EdgeInsets.symmetric(
              horizontal: widget.configuration.screenWidth / 40,
              vertical: widget.configuration.screenWidth / 20),
          itemCount: chatGroup.messages.length,
          itemBuilder: (context, index) => showMessage(index)),
    );
  }

  Widget showMessage(int index) {
    bool isUserMessage = chatGroup.messages[index].senderId ==
        widget.configuration.userData.userId;

    return Padding(
      padding: EdgeInsets.only(
          bottom: widget.configuration.screenWidth / 20,
          left: isUserMessage ? widget.configuration.screenWidth / 8 : 0,
          right: isUserMessage ? 0 : widget.configuration.screenWidth / 8
      ),
      child: Container(
        decoration: BoxDecoration(
          color: PrimaryColorLight,
          borderRadius:
          BorderRadius.circular(widget.configuration.screenWidth / 40),
        ),
        child: Text(chatGroup.messages[index].data),
      ),
    );
  }

  Widget showBottomTools() {
    return GestureDetector(
      onTap: sendMessage,
      child: Container(
        height: 50,
        color: PrimaryColor,
      ),
    );
  }

  void sendMessage() async {
    Database().sendMessageToGroup(
      context, widget.configuration.userData.userId, widget.chatGroup.id,
    Message(
      "Q2FcKkjG3qUclIoaQSjGn8C0I7E3",
      Timestamp.now(),
      "Bonjour"
    ));
  }
}
