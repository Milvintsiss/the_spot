import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_spot/services/library/userProfile.dart';

class ChatGroup {
  String id;
  String name;
  List<String> adminsIds;
  List<String> membersIds;
  List<Message> messages;
  bool hasArchiveMessages;
  int activeMessagesCount;
  int totalMessagesCount;

  Timestamp lastMessage;
  Timestamp lastUpdate;
  Timestamp creationDate;

  List<UserProfile> members;

  ChatGroup(
      {this.id,
      this.name,
      this.adminsIds,
      this.membersIds,
      this.messages,
      this.hasArchiveMessages,
      this.activeMessagesCount,
      this.totalMessagesCount,
      this.lastMessage,
      this.lastUpdate,
      this.creationDate,
      this.members});

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Name': name,
      'AdminsIds': adminsIds,
      'MembersIds': membersIds,
      'Messages': messages,
      'HasArchiveMessages': hasArchiveMessages,
      'ActiveMessagesCount': activeMessagesCount,
      'TotalMessagesCount': totalMessagesCount,
      'LastMessage': lastMessage,
      'LastUpdate': lastUpdate,
      'CreationDate': creationDate
    };
  }
}

ChatGroup convertMapToChatGroup(Map map) {
  return ChatGroup(
      name: map['Name'],
      adminsIds: map['AdminsIds'].cast<String>(),
      membersIds: map['MembersIds'].cast<String>(),
      messages: convertListOfMapsToListOfMessages(map['Messages'].cast<Map>()),
      hasArchiveMessages: map['HasArchiveMessages'],
      activeMessagesCount: map['ActiveMessagesCount'],
      totalMessagesCount: map['TotalMessagesCount'],
      lastMessage: map['LastMessage'],
      lastUpdate: map['LastUpdate'],
      creationDate: map['CreationDate']);
}

class Message {
  String senderId;
  Timestamp date;
  String data;

  Message(this.senderId, this.date, this.data);

  Map<String, dynamic> toMap() {
    return {
      "SenderId": senderId,
      "Date": date,
      "Data": data,
    };
  }
}

Message convertMapToMessage(Map map) {
  return Message(map['SenderId'], map['Date'], map['Data']);
}

List<Message> convertListOfMapsToListOfMessages(List<Map> maps) {
  List<Message> messages = [];
  maps.forEach((map) => messages.add(convertMapToMessage(map)));
  return messages;
}
