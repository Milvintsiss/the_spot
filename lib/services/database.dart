import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import 'package:the_spot/services/library/library.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:the_spot/services/library/userGrade.dart';

class Database {
  final database = Firestore.instance;

  CloudFunctions cloudFunctions = CloudFunctions(
    region: 'us-central1',
  );

  void createRecord() async {
    await database.collection("books").document("1").setData({
      'title': 'Mastering Flutter',
      'description': 'Programming Guide for Dart'
    });

    DocumentReference ref = await database.collection("books").add({
      'title': 'Flutter in Action',
      'description': 'Complete Programming Guide to learn Flutter'
    });
    print(ref.documentID);
  }

  void getData() {
    database.collection("books").getDocuments().then((QuerySnapshot snapshot) {
      snapshot.documents.forEach((f) => print('${f.data}}'));
    });
  }

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

    if (creationDate != null) update['CreationDate'] = creationDate;

    update['LastUpdate'] = updateDate;

    print(update);

    if (await checkConnection(context)) {
      try {
        if (onCreate) {
          await database
              .collection('users')
              .document(userId)
              .setData(update)
              .catchError((error) {
            error(error.toString(), context);
            print(error);
            return false;
          });
          await database
              .collection("usersLocation")
              .document(userId)
              .setData({}).catchError((err) {
            print(err);
            error(err.toString(), context);
          });
        } else {
          await database
              .collection('users')
              .document(userId)
              .updateData(update)
              .catchError((error) {
            error(error.toString(), context);
            print(error);
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
            .collection("users")
            .document(userId)
            .get()
            .then((DocumentSnapshot document) {
          if (document.exists) {
            userProfile = ConvertMapToUserProfile(document.data);
            userProfile.userId = userId;
          }
        }).catchError((err) {
          print(err);
          error(err.toString(), context);
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
        await database
            .collection('users')
            .where(FieldPath.documentId, whereIn: ids)
            .getDocuments()
            .then((QuerySnapshot querySnapshot) => ids.forEach((element) {
                  usersProfile.add(ConvertMapToUserProfile(querySnapshot
                      .documents
                      .firstWhere((document) => document.documentID == element)
                      .data)); //returns documents in query order
                  usersProfile[usersProfile.length - 1].userId = element;
                }))
            .catchError((err) {
          print(err);
          error(err.toString(), context);
        });
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
            .collection('users')
            .document(userId)
            .delete()
            .catchError((err) {
          print(err);
          error(err.toString(), context);
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
            .collection('users')
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
              print(err);
              error(err.toString(), context);
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
            .collection('users')
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
            }})
            .catchError((err) {
              print(err);
              error(err.toString(), context);
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
                .collection('users')
                .document(mainUserId)
                .collection('Following')
                .document(userToFollowId),
            {'Date': date});
        batch.updateData(database.collection('users').document(mainUserId),
            {'NumberOfFollowing': FieldValue.increment(1)});

        batch.setData(
            database
                .collection('users')
                .document(userToFollowId)
                .collection('Followers')
                .document(mainUserId),
            {'Date': date});
        batch.updateData(database.collection('users').document(userToFollowId),
            {'NumberOfFollowers': FieldValue.increment(1)});

        await batch.commit().then((value) => succeed = true).catchError((err) {
          print(err.toString());
          error(err.toString(), context);
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
            .collection('users')
            .document(mainUserId)
            .collection('Following')
            .document(userToUnFollowId));
        batch.updateData(database.collection('users').document(mainUserId),
            {'NumberOfFollowing': FieldValue.increment(-1)});

        batch.delete(database
            .collection('users')
            .document(userToUnFollowId)
            .collection('Followers')
            .document(mainUserId));
        batch.updateData(
            database.collection('users').document(userToUnFollowId),
            {'NumberOfFollowers': FieldValue.increment(-1)});

        await batch.commit().then((value) => succeed = true).catchError((err) {
          print(err.toString());
          error(err.toString(), context);
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

  Future<bool> sendFriendRequest(
      BuildContext context,
      String mainUserId,
      String userSendindRequestPseudo,
      String userSendingRequestPictureDownloadPath,
      String userToAddAsFriendId) async {
    final HttpsCallable sendFriendRequestNotificationTo = CloudFunctions
        .instance
        .getHttpsCallable(functionName: 'sendFriendRequestNotificationTo');

    bool success = false;
    if (await checkConnection(context)) {
      try {
        await database
            .collection('users')
            .document(userToAddAsFriendId)
            .updateData({
              'PendingFriendsId': FieldValue.arrayUnion([mainUserId])
            })
            .then((value) => success = true)
            .catchError((err) {
              print(err.toString());
              error(err.toString(), context);
              success = false;
            });
        sendFriendRequestNotificationTo.call(<String, dynamic>{
          'userId': userToAddAsFriendId,
          'pseudo': userSendindRequestPseudo,
          'picturePath': userSendingRequestPictureDownloadPath ?? ""
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
            .collection('users')
            .document(userToAddAsFriendId)
            .updateData({
              'PendingFriendsId': FieldValue.arrayRemove([mainUserId])
            })
            .then((value) => success = true)
            .catchError((err) {
              print(err.toString());
              error(err.toString(), context);
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
        batch.updateData(database.collection('users').document(mainUserId), {
          'Friends': FieldValue.arrayUnion([userToAddId]),
          'PendingFriendsId': FieldValue.arrayRemove([userToAddId]),
          'NumberOfFriends': FieldValue.increment(1)
        });
        batch.updateData(database.collection('users').document(userToAddId), {
          'Friends': FieldValue.arrayUnion([mainUserId]),
          'NumberOfFriends': FieldValue.increment(1)
        });
        await batch.commit().catchError((err) {
          print(err.toString());
          error(err.toString(), context);
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
        await database.collection('users').document(mainUserId).updateData({
          'PendingFriendsId': FieldValue.arrayRemove([userToAddId])
        }).catchError((err) {
          print(err.toString());
          error(err.toString(), context);
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
        });
        await database
            .collection('users')
            .document(mainUserId)
            .collection('Following')
            .where(FieldPath.documentId, whereIn: usersId)
            .getDocuments()
            .then((QuerySnapshot snapshots) {
          usersId.forEach((id) {
            int index = snapshots.documents
                .indexWhere((element) => element.documentID == id);
            if (index != -1) {
              users[usersId.indexOf(id)].isFollowed = true;
            } else
              users[usersId.indexOf(id)].isFollowed = false;
          });
        }).catchError((err) {
          print(err.toString());
          error(err.toString(), context);
        });

        users.forEach((element) {
          if (element.friends.contains(mainUserId))
            element.isFriend = true;
          else
            element.isFriend = false;
        });
//        await database
//            .collection('users')
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
//          print(err.toString());
//          error(err.toString(), context);
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
            .collection('users')
            .where('Username', isEqualTo: username)
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
          if (querySnapshot.documents.length > 0)
            _isUsernameAlreadyInUse = true;
          else
            _isUsernameAlreadyInUse = false;
        }).catchError((err) {
          print(err.toString());
          error(err.toString(), context);
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
            .collection('users')
            .document(userId)
            .updateData({'DevicesTokens': FieldValue.arrayUnion(tokens)})
            .then((value) => success = true)
            .catchError((err) {
              success = false;
              print(err.toString());
              error(err.toString(), context);
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
        print(err);
        error(err.toString(), context);
      });
    }
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
            .collection("spots")
            .add(_spotData)
            .then((value) => spotId = value.documentID)
            .catchError((err) {
          print(err);
          error(err.toString(), context);
          state = "error";
        });
      } else {
        await database
            .collection("spots")
            .document(spotId)
            .updateData(_spotData)
            .catchError((err) {
          print(err);
          error(err.toString(), context);
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
            .collection("spots")
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
          spots = convertSpotsData(querySnapshot, getAll);
        }).catchError((err) {
          print(err);
          error(err.toString(), context);
          return null;
        });
      } else {
        await database
            .collection("spots")
            .where(
              'SpotName',
              isEqualTo: matchName,
            )
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
          spots = convertSpotsData(querySnapshot, getAll);
        }).catchError((err) {
          print(err);
          error(err.toString(), context);
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

      //convert the List of UserGradess to a List of Map
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
