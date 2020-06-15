import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/services/library/chatGroup.dart';

import 'package:the_spot/services/library/library.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:the_spot/services/library/userGrade.dart';

const String USERS_COLLECTION = 'users';
const String SPOTS_COLLECTION = 'spots';
const String GROUP_CHATS_COLLECTION = 'groupChats';

class Database {
  final database = Firestore.instance;

  final CloudFunctions cloudFunctions = CloudFunctions(
    region: 'us-central1',
  );

  Future<bool> updateProfile(BuildContext context, String userId,
      {bool onCreate = false,
      String username,
      String pseudo,
      bool BMX,
      bool Roller,
      bool Scooter,
      bool Skateboard,
      String description,
      String profilePictureDownloadPath,
      String profilePictureHash,
      LatLng actualLocation}) async {
    final HttpsCallable updateUserPseudoAndUsernameInAlgolia = cloudFunctions
        .getHttpsCallable(functionName: 'updateUserPseudoAndUsernameInAlgolia');

    DateTime updateDate = DateTime.now();
    DateTime creationDate;
    if (onCreate) creationDate = updateDate;

    bool usernameOrPseudoChange = false;

    Map update = Map<String, dynamic>.identity();
    if (username != null) {
      update['Username'] = username;
      usernameOrPseudoChange = true;
    }
    if (pseudo != null) {
      update['Pseudo'] = pseudo;
      usernameOrPseudoChange = true;
    }
    if (BMX != null) update['BMX'] = BMX;
    if (Roller != null) update['Roller'] = Roller;
    if (Scooter != null) update['Scooter'] = Scooter;
    if (Skateboard != null) update['Skateboard'] = Skateboard;
    if (description != null) update['Description'] = description;
    if (actualLocation != null) {
      update['ActualLocationLongitude'] = actualLocation.longitude;
      update['ActualLocationLatitude'] = actualLocation.latitude;
    }
    if (profilePictureDownloadPath != null)
      update['ProfilePictureDownloadPath'] = profilePictureDownloadPath;

    if (profilePictureHash != null)
      update['ProfilePictureHash'] = profilePictureHash;

    if (creationDate != null) update['CreationDate'] = creationDate;

    update['LastUpdate'] = updateDate;

    print(update);

    if (await checkConnection(context)) {
      try {
        if (onCreate) {
          await database
              .collection(USERS_COLLECTION)
              .document(userId)
              .setData(update)
              .catchError((err) {
            print("Database Error: " + err.toString());
            error("Database Error: " + err.toString(), context);
            return false;
          });
          await database
              .collection("usersLocation")
              .document(userId)
              .setData({}).catchError((err) {
            print("Database Error: " + err.toString());
            error("Database Error: " + err.toString(), context);
          });
        } else {
          await database
              .collection(USERS_COLLECTION)
              .document(userId)
              .updateData(update)
              .catchError((err) {
            print("Database Error: " + err.toString());
            error("Database Error: " + err.toString(), context);
            return false;
          });
          if (usernameOrPseudoChange)
            await updateUserPseudoAndUsernameInAlgolia.call(
                <String, dynamic>{'Pseudo': pseudo, 'Username': username});
        }
      } catch (e) {
        print(e);
        error(e.toString(), context);
        return false;
      }
    } else {
      return false;
    }
    return true;
  }

  Future<UserProfile> getProfileData(
      String userId, BuildContext context) async {
    UserProfile userProfile;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(USERS_COLLECTION)
            .document(userId)
            .get()
            .then((DocumentSnapshot document) {
          if (document.exists) {
            userProfile = convertMapToUserProfile(document.data);
            userProfile.userId = userId;
          }
        }).catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          return null;
        });
      } catch (err) {
        print(err);
        error(err.toString(), context);
        return null;
      }
      return userProfile;
    }
    return null;
  }

  Future<List<UserProfile>> getUsersByIds(
      BuildContext context, List<String> ids,
      {bool verifyIfFriendsOrFollowed = false, String mainUserId}) async {
    List<UserProfile> usersProfile = [];

    if (await checkConnection(context) && ids.length > 0) {
      try {
        for (int i = 0; i < ids.length; i = i + 10) {
          List<String> query = ids
              .getRange(
                  i,
                  i + 10 >
                          ids.length //if there is more than 10, do query in few times
                      ? ids.length
                      : i + 10)
              .toList();
          await database
              .collection(USERS_COLLECTION)
              .where(FieldPath.documentId, whereIn: query)
              .getDocuments()
              .then((QuerySnapshot querySnapshot) => query.forEach((id) {
                    usersProfile.add(convertMapToUserProfile(querySnapshot
                        .documents
                        .firstWhere((document) => document.documentID == id)
                        .data)); //returns documents in query order
                    usersProfile[usersProfile.length - 1].userId = id;
                  }))
              .catchError((err) {
            print("Database Error: " + err.toString());
            error("Database Error: " + err.toString(), context);
          });
        }
        if (verifyIfFriendsOrFollowed) {
          usersProfile =
              await isUsersFriendOrFollowed(context, usersProfile, mainUserId);
        }
      } catch (err) {
        print(err);
        error(err.toString(), context);
      }
    }
    return usersProfile;
  }

  Future<bool> deleteProfileData(BuildContext context, String userId) async {
    if (await checkConnection(context)) {
      try {
        await database
            .collection(USERS_COLLECTION)
            .document(userId)
            .delete()
            .catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          return false;
        });
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
        return false;
      }
    } else {
      return false;
    }
    return true;
  }

  Future<Map<String, Object>> getFollowersOf(
      BuildContext context,
      String mainUserId,
      String userToQueryId,
      Timestamp start,
      int limit) async {
    List<String> usersId = [];
    List<UserProfile> users = [];
    Timestamp lastTimestamp;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(USERS_COLLECTION)
            .document(userToQueryId)
            .collection('Followers')
            .orderBy('Date', descending: true)
            .startAfter([start])
            .limit(limit)
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
              if (querySnapshot.documents.length > 0) {
                querySnapshot.documents
                    .forEach((element) => usersId.add(element.documentID));
                lastTimestamp = querySnapshot
                    .documents[querySnapshot.documents.length - 1].data['Date'];
              }
            })
            .catchError((err) {
              print("Database Error: " + err.toString());
              error("Database Error: " + err.toString(), context);
              return false;
            });
        users = await getUsersByIds(context, usersId,
            verifyIfFriendsOrFollowed: true, mainUserId: mainUserId);
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
      }
    }
    return {'users': users, 'lastTimestamp': lastTimestamp};
  }

  Future<Map<String, Object>> getFollowingOf(
      BuildContext context,
      String mainUserId,
      String userToQueryId,
      Timestamp start,
      int limit) async {
    List<String> usersId = [];
    List<UserProfile> users = [];
    Timestamp lastTimestamp;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(USERS_COLLECTION)
            .document(userToQueryId)
            .collection('Following')
            .orderBy('Date', descending: true)
            .startAfter([start])
            .limit(limit)
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
              if (querySnapshot.documents.length > 0) {
                querySnapshot.documents
                    .forEach((element) => usersId.add(element.documentID));
                lastTimestamp = querySnapshot
                    .documents[querySnapshot.documents.length - 1].data['Date'];
              }
            })
            .catchError((err) {
              print("Database Error: " + err.toString());
              error("Database Error: " + err.toString(), context);
              return false;
            });
        users = await getUsersByIds(context, usersId,
            verifyIfFriendsOrFollowed: true, mainUserId: mainUserId);
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
      }
    }
    return {'users': users, 'lastTimestamp': lastTimestamp};
  }

  Future<bool> followUser(
      BuildContext context, String mainUserId, String userToFollowId) async {
    bool succeed;
    DateTime date = DateTime.now();
    if (await checkConnection(context)) {
      try {
        WriteBatch batch = database.batch();
        batch.setData(
            database
                .collection(USERS_COLLECTION)
                .document(mainUserId)
                .collection('Following')
                .document(userToFollowId),
            {'Date': date});
        batch.updateData(
            database.collection(USERS_COLLECTION).document(mainUserId),
            {'NumberOfFollowing': FieldValue.increment(1)});

        batch.setData(
            database
                .collection(USERS_COLLECTION)
                .document(userToFollowId)
                .collection('Followers')
                .document(mainUserId),
            {'Date': date});
        batch.updateData(
            database.collection(USERS_COLLECTION).document(userToFollowId),
            {'NumberOfFollowers': FieldValue.increment(1)});

        await batch.commit().then((value) => succeed = true).catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          succeed = false;
        });
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
        succeed = false;
      }
    }
    return succeed;
  }

  Future<bool> unFollowUser(
      BuildContext context, String mainUserId, String userToUnFollowId) async {
    bool succeed;
    if (await checkConnection(context)) {
      try {
        WriteBatch batch = database.batch();
        batch.delete(database
            .collection(USERS_COLLECTION)
            .document(mainUserId)
            .collection('Following')
            .document(userToUnFollowId));
        batch.updateData(
            database.collection(USERS_COLLECTION).document(mainUserId),
            {'NumberOfFollowing': FieldValue.increment(-1)});

        batch.delete(database
            .collection(USERS_COLLECTION)
            .document(userToUnFollowId)
            .collection('Followers')
            .document(mainUserId));
        batch.updateData(
            database.collection(USERS_COLLECTION).document(userToUnFollowId),
            {'NumberOfFollowers': FieldValue.increment(-1)});

        await batch.commit().then((value) => succeed = true).catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          succeed = false;
        });
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
        succeed = false;
      }
    }
    return succeed;
  }

  Future<bool> sendFriendRequest(BuildContext context,
      {@required UserProfile mainUser, @required UserProfile userToAdd}) async {
    final HttpsCallable sendFriendRequestNotificationTo = CloudFunctions
        .instance
        .getHttpsCallable(functionName: 'sendFriendRequestNotificationTo');

    bool success = false;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(USERS_COLLECTION)
            .document(userToAdd.userId)
            .updateData({
              'PendingFriendsId': FieldValue.arrayUnion([mainUser.userId])
            })
            .then((value) => success = true)
            .catchError((err) {
              print("Database Error: " + err.toString());
              error("Database Error: " + err.toString(), context);
              success = false;
            });
        sendFriendRequestNotificationTo.call(<String, dynamic>{
          'title': AppLocalizations.of(context).translate("New friend request"),
          'body': AppLocalizations.of(context).translate(
              "%DYNAMIC wants to add you as friend",
              dynamic: mainUser.pseudo),
          'userToAddAsFriendId': userToAdd.userId,
          'mainUserId': mainUser.userId,
          'mainUserPseudo': mainUser.pseudo,
          'mainUserProfilePictureDownloadPath':
              mainUser.profilePictureDownloadPath ?? "",
          'mainUserProfilePictureHash': mainUser.profilePictureHash ?? "",
          'userToAddTokens': userToAdd.devicesTokens
        });
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
        success = false;
      }
    }
    return success;
  }

  Future<bool> removeFriendRequest(BuildContext context, String mainUserId,
      String userToAddAsFriendId) async {
    bool success = false;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(USERS_COLLECTION)
            .document(userToAddAsFriendId)
            .updateData({
              'PendingFriendsId': FieldValue.arrayRemove([mainUserId])
            })
            .then((value) => success = true)
            .catchError((err) {
              print("Database Error: " + err.toString());
              error("Database Error: " + err.toString(), context);
              success = false;
            });
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
        success = false;
      }
    }
    return success;
  }

  Future<bool> acceptFriendRequest(
      BuildContext context, String mainUserId, String userToAddId) async {
    bool success = true;
    if (await checkConnection(context)) {
      try {
        WriteBatch batch = database.batch();
        batch.updateData(
            database.collection(USERS_COLLECTION).document(mainUserId), {
          'Friends': FieldValue.arrayUnion([userToAddId]),
          'PendingFriendsId': FieldValue.arrayRemove([userToAddId]),
          'NumberOfFriends': FieldValue.increment(1)
        });
        batch.updateData(
            database.collection(USERS_COLLECTION).document(userToAddId), {
          'Friends': FieldValue.arrayUnion([mainUserId]),
          'NumberOfFriends': FieldValue.increment(1)
        });
        await batch.commit().catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          success = false;
        });
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
        success = false;
      }
    }
    return success;
  }

  Future<bool> refuseFriendRequest(
      BuildContext context, String mainUserId, String userToAddId) async {
    bool success = true;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(USERS_COLLECTION)
            .document(mainUserId)
            .updateData({
          'PendingFriendsId': FieldValue.arrayRemove([userToAddId])
        }).catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          success = false;
        });
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
        success = false;
      }
    }
    return success;
  }

  Future<bool> removeFriend(
      BuildContext context, String mainUserId, String userToRemoveId) async {
    bool success = true;
    if (await checkConnection(context)) {
      try {
        WriteBatch batch = database.batch();
        batch.updateData(
            database.collection(USERS_COLLECTION).document(mainUserId), {
          'Friends': FieldValue.arrayRemove([userToRemoveId]),
          'NumberOfFriends': FieldValue.increment(-1)
        });
        batch.updateData(
            database.collection(USERS_COLLECTION).document(userToRemoveId), {
          'Friends': FieldValue.arrayRemove([mainUserId]),
          'NumberOfFriends': FieldValue.increment(-1)
        });
        await batch.commit().catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          success = false;
        });
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
        success = false;
      }
    }
    return success;
  }

  Future<List<UserProfile>> isUsersFriendOrFollowed(
      BuildContext context, List<UserProfile> users, String mainUserId) async {
    if (await checkConnection(context)) {
      try {
        List<String> usersId = [];
        users.forEach((user) {
          usersId.add(user.userId);
          user.isFollowed = false;
        });
        for (int i = 0; i < usersId.length; i = i + 10) {
          List<String> query = usersId
              .getRange(
                  i,
                  i + 10 >
                          usersId
                              .length //if there is more than 10, do query in few times
                      ? usersId.length
                      : i + 10)
              .toList();
          await database
              .collection(USERS_COLLECTION)
              .document(mainUserId)
              .collection('Following')
              .where(FieldPath.documentId, whereIn: query)
              .getDocuments()
              .then((QuerySnapshot snapshots) {
            query.forEach((userId) {
              int index = snapshots.documents
                  .indexWhere((document) => document.documentID == userId);
              if (index != -1) users[usersId.indexOf(userId)].isFollowed = true;
            });
          }).catchError((err) {
            print("Database Error: " + err.toString());
            error("Database Error: " + err.toString(), context);
          });
        }

        users.forEach((user) {
          if (user.friends.contains(mainUserId))
            user.isFriend = true;
          else
            user.isFriend = false;
        });

        //code if friends are stocked in a collection
//        await database
//            .collection(USERS_COLLECTION)
//            .document(mainUserId)
//            .collection('Friends')
//            .where(FieldPath.documentId, whereIn: usersId)
//            .getDocuments()
//            .then((QuerySnapshot snapshots) {
//          usersId.forEach((id) {
//            int index = snapshots.documents
//                .indexWhere((element) => element.documentID == id);
//            if (index != -1) {
//              users[usersId.indexOf(id)].isFriend = true;
//            } else
//              users[usersId.indexOf(id)].isFriend = false;
//          });
//        }).catchError((err) {
//        print("Database Error: " + err.toString());
//        error("Database Error: " + err.toString(), context);
//        });
      } catch (err) {
        print(err.toString());
        error(err.toString(), context);
      }
    }
    return users;
  }

  Future<bool> isUsernameAlreadyInUse(
      {@required BuildContext context, @required String username}) async {
    bool _isUsernameAlreadyInUse;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(USERS_COLLECTION)
            .where('Username', isEqualTo: username)
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
          if (querySnapshot.documents.length > 0)
            _isUsernameAlreadyInUse = true;
          else
            _isUsernameAlreadyInUse = false;
        }).catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
        });
      } catch (err) {
        print(err);
        error(err.toString(), context);
        return null;
      }
    } else
      return null;
    return _isUsernameAlreadyInUse;
  }

  Future<bool> addDeviceTokenToUserProfile(
      BuildContext context, String userId, List<String> tokens) async {
    bool success = false;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(USERS_COLLECTION)
            .document(userId)
            .updateData({'DevicesTokens': FieldValue.arrayUnion(tokens)})
            .then((value) => success = true)
            .catchError((err) {
              success = false;
              print("Database Error: " + err.toString());
              error("Database Error: " + err.toString(), context);
            });
      } catch (err) {
        success = false;
        print(err);
        error(err.toString(), context);
      }
    }
    return success;
  }

  void updateUserLocation(
      {@required BuildContext context,
      @required String userId,
      @required LatLng userLocation}) async {
    if (await checkConnection(context)) {
      await database.collection("usersLocation").document(userId).updateData({
        'UserLocationLongitude': userLocation.longitude,
        'UserLocationLatitude': userLocation.latitude,
        'UserId': userId,
      }).catchError((err) {
        print("Database Error: " + err.toString());
        error("Database Error: " + err.toString(), context);
      });
    }
  }

  Future<ChatGroup> createNewChatGroup(
      BuildContext context, ChatGroup newChatGroup) async {
    Timestamp date = Timestamp.now();
    newChatGroup.lastUpdate = date;
    newChatGroup.lastMessage = date;
    newChatGroup.creationDate = date;
    newChatGroup.hasArchiveMessages = false;
    newChatGroup.activeMessagesCount = 1;
    newChatGroup.totalMessagesCount = 1;

    Map data = newChatGroup.toMap();

    if (await checkConnection(context)) {
      try {
        await database
            .collection(GROUP_CHATS_COLLECTION)
            .add(data)
            .then((document) => newChatGroup.id = document.documentID)
            .catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
        });
      } catch (err) {
        print(err);
        error(err.toString(), context);
      }
    }
    return newChatGroup;
  }

  Future<bool> updateChatGroupOptions(
      BuildContext context, ChatGroup chatGroup) async {
    ChatGroup update = ChatGroup();
    bool success = false;
    Timestamp date = Timestamp.now();
    update.lastUpdate = date;
    update.name = chatGroup.name;
    update.membersIds = chatGroup.membersIds;
    update.adminsIds = chatGroup.adminsIds;
    update.pictureDownloadPath = chatGroup.pictureDownloadPath;
    update.pictureHash = chatGroup.pictureHash;
    update.onlyAdminsCanChangeChatNameOrPicture = chatGroup.onlyAdminsCanChangeChatNameOrPicture;

    Map data = deleteMapNullKeys(update.toMap());


    if (await checkConnection(context)) {
      try {
        await database
            .collection(GROUP_CHATS_COLLECTION)
            .document(chatGroup.id)
            .updateData(data)
            .then((res) => success = true)
            .catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
        });
      } catch (err) {
        print(err);
        error(err.toString(), context);
      }
    }
    return success;
  }

  Future<bool> addMembersToChatGroup(BuildContext context, String chatGroupId, List<UserProfile> newMembers) async {
    bool success = false;
    List<String> newMembersIds = [];
    newMembers.forEach((member) => newMembersIds.add(member.userId));
    if (await checkConnection(context)) {
      try {
        await database
            .collection(GROUP_CHATS_COLLECTION)
            .document(chatGroupId)
            .updateData({'MembersIds': FieldValue.arrayUnion(newMembersIds)})
            .then((res) => success = true)
            .catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
        });
      } catch (err) {
        print(err);
        error(err.toString(), context);
      }
    }
    return success;
  }

  Future<bool> sendMessageToGroup(BuildContext context, UserProfile mainUser,
      ChatGroup group, Message message, List<UserProfile> members) async {
    final HttpsCallable sendMessageNotificationTo = CloudFunctions.instance
        .getHttpsCallable(functionName: 'sendMessageNotificationTo');

    bool success = true;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(GROUP_CHATS_COLLECTION)
            .document(group.id)
            .updateData({
          'Messages': FieldValue.arrayUnion([message.toMap()]),
          'LastMessage': Timestamp.now(),
          'ActiveMessagesCount': FieldValue.increment(1),
          'TotalMessagesCount': FieldValue.increment(1),
        }).catchError((err) {
          success = false;
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
        });

        message.setMessageTypeAndTransformData();
        List<String> usersTokens = [];
        String usersIds = "";
        members.forEach((member) {
          if (member.devicesTokens != null && member.devicesTokens.length > 0) {
            usersTokens.addAll(member.devicesTokens);
            usersIds = "$usersIds/${member.userId}";
          }
        });

        sendMessageNotificationTo.call(<String, dynamic>{
          'conversationId': group.id,
          'conversationName': group.name,
          'conversationPictureDownloadPath': group.isGroup
              ? group.pictureDownloadPath ?? ""
              : mainUser.profilePictureDownloadPath ?? "",
          'conversationPictureHash': group.isGroup
              ? group.pictureHash ?? ""
              : mainUser.profilePictureHash ?? "",
          'usersTokens': usersTokens,
          'usersIds': usersIds,
          'message': message.data,
          'senderPseudo': mainUser.pseudo,
        });
      } catch (err) {
        success = false;
        print(err);
        error(err.toString(), context);
      }
    }
    return success;
  }

  Future<ChatGroup> getGroup(BuildContext context,
      {@required String groupId}) async {
    ChatGroup chatGroup;
    if (await checkConnection(context)) {
      try {
        await database
            .collection(GROUP_CHATS_COLLECTION)
            .document(groupId)
            .get()
            .then((document) {
          chatGroup = convertMapToChatGroup(document.data);
          chatGroup.id = groupId;
        }).catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
        });
      } catch (err) {
        print(err);
        error(err.toString(), context);
      }
    }
    return chatGroup;
  }

  Future<List<ChatGroup>> getGroups(BuildContext context,
      {@required String userId,
      @required Timestamp startAfter,
      int limit = 10}) async {
    List<ChatGroup> chatGroups = [];
    if (await checkConnection(context)) {
      try {
        await database
            .collection(GROUP_CHATS_COLLECTION)
            .orderBy('LastMessage', descending: true)
            .where('MembersIds', arrayContains: userId)
            .startAfter([startAfter])
            .limit(limit)
            .getDocuments()
            .then((snapshot) => snapshot.documents.forEach((document) {
                  print(document.data);
                  ChatGroup chatGroup = convertMapToChatGroup(document.data);
                  chatGroup.id = document.documentID;
                  chatGroups.add(chatGroup);
                }))
            .catchError((err) {
              print("Database Error: " + err.toString());
              error("Database Error: " + err.toString(), context);
            });
      } catch (err) {
        print(err);
        error(err.toString(), context);
      }
    }
    return chatGroups;
  }

  Future<String> updateASpot(
      {@required BuildContext context,
      @required String spotId,
      String creatorId,
      LatLng spotLocation,
      String spotName,
      String spotDescription,
      List<String> imagesDownloadUrls,
      UserGrades userGrade,
      List<UserGrades> spotGrades,
      bool onCreate = false}) async {
    String state;

    if (await checkConnection(context)) {
      Map _spotData = await spotData(
          context,
          onCreate,
          spotId,
          spotLocation,
          creatorId,
          spotName,
          spotDescription,
          imagesDownloadUrls,
          userGrade,
          spotGrades);

      if (onCreate) {
        await database
            .collection(SPOTS_COLLECTION)
            .add(_spotData)
            .then((value) => spotId = value.documentID)
            .catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          state = "error";
        });
      } else {
        await database
            .collection(SPOTS_COLLECTION)
            .document(spotId)
            .updateData(_spotData)
            .catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          state = "error";
        });
      }
    } else {
      return "error";
    }
    if (onCreate) state = spotId;
    return state;
  }

  Future<Map> spotData(
    BuildContext context,
    bool onCreate,
    String spotId,
    LatLng spotLocation,
    String creatorId,
    String spotName,
    String spotDescription,
    List<String> imagesDownloadUrls,
    UserGrades userGrade,
    List<UserGrades> spotGrades,
  ) async {
    Map data = Map<String, dynamic>.identity();

    DateTime updateDate = DateTime.now();
    DateTime creationDate;
    if (onCreate) creationDate = updateDate;

    if (spotLocation != null) {
      data['SpotLocationLatitude'] = spotLocation.latitude;
      data['SpotLocationLongitude'] = spotLocation.longitude;
    }
    if (creatorId != null) data['CreatorId'] = creatorId;
    if (spotName != null) data['SpotName'] = spotName;
    if (spotDescription != null) data['SpotDescription'] = spotDescription;
    if (imagesDownloadUrls != null)
      data['ImagesDownloadUrls'] = imagesDownloadUrls;

    if (userGrade != null) //if the user has not rated this spot
      data['UsersGrades'] = FieldValue.arrayUnion([userGrade.toMap()]);
    if (spotGrades != null) {
      //if the user has already rated this spot
      data['UsersGrades'] = ConvertUsersGradesToMap(spotGrades);
    }

    if (creationDate != null) data['CreationDate'] = creationDate;
    data['LastUpdate'] = updateDate;

    return data;
  }

  Future<List> getSpots(BuildContext context,
      {bool getAll = false, String matchName}) async {
    List<MapMarker> spots = new List();

    if (await checkConnection(context)) {
      if (matchName == null) {
        await database
            .collection(SPOTS_COLLECTION)
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
          spots = convertSpotsData(querySnapshot, getAll);
        }).catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          return null;
        });
      } else {
        await database
            .collection(SPOTS_COLLECTION)
            .where(
              'SpotName',
              isEqualTo: matchName,
            )
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
          spots = convertSpotsData(querySnapshot, getAll);
        }).catchError((err) {
          print("Database Error: " + err.toString());
          error("Database Error: " + err.toString(), context);
          return null;
        });
      }
    } else {
      return null;
    }
    return spots;
  }

  List<MapMarker> convertSpotsData(QuerySnapshot querySnapshot, bool getAll) {
    List<MapMarker> spots = [];
    querySnapshot.documents.forEach((document) {
      Map data = document.data;
      print(data);

      //convert the List<dynamic> into List<String>
      List<String> imagesDownloadUrls = [];
      if (data['ImagesDownloadUrls'] != null) {
        imagesDownloadUrls = data['ImagesDownloadUrls'].cast<String>();
        print(imagesDownloadUrls);
      }

      //convert the List of UserGrades to a List of Map
      List<UserGrades> usersGrades = [];
      if (data['UsersGrades'] != null) {
        usersGrades = ConvertMapToUsersGrades(data['UsersGrades'].cast<Map>());
        usersGrades.forEach((element) {
          print(element.userId +
              " / " +
              element.spotGrade.toString() +
              " / " +
              element.spotGradeFloor.toString() +
              " / " +
              element.spotGradeBeauty.toString());
        });
      }

      MapMarker spot = MapMarker(
          id: document.documentID,
          position: new LatLng(
              data['SpotLocationLatitude'], data['SpotLocationLongitude']),
          icon: BitmapDescriptor.defaultMarker,
          name: data['SpotName'],
          description: data['SpotDescription'],
          imagesDownloadUrls: imagesDownloadUrls,
          usersGrades: usersGrades,
          type: Type.Spot);
      if (data['SpotName'] != null || getAll) {
        //verify if spot has been updated after his creation
        spots.add(spot);
      }
    });
    return spots;
  }
}
