import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserProfile {
  UserProfile({
    this.userId,
    this.username,
    this.pseudo,
    this.numberOfFollowers,
    this.numberOfFollowing,
    this.numberOfFriends,
    this.friends,
    this.description,
    this.actualLocation,
    this.BMX,
    this.Roller,
    this.Scooter,
    this.Skateboard,
    this.profilePictureDownloadPath,
    this.isFriend,
    this.isFollowed,
    this.pendingFriendsId,
    this.devicesTokens,
    this.subscribedTopics,
    this.lastUpdate,
    this.creationDate,
  });

  String userId;
  String username;
  String pseudo;
  int numberOfFollowers;
  int numberOfFollowing;
  int numberOfFriends;
  List<String> friends;
  bool BMX;
  bool Roller;
  bool Scooter;
  bool Skateboard;
  String description;
  LatLng actualLocation;
  String profilePictureDownloadPath;
  bool isFollowed;
  bool isFriend;

  List<String> pendingFriendsId;

  List<String> devicesTokens;
  List<String> subscribedTopics;

  final Timestamp lastUpdate;
  final Timestamp creationDate;

  Map<String, dynamic> toMap() {
    return {
      'Username': username,
      'Pseudo': pseudo,
      'NumberOfFollowers': numberOfFollowers,
      'NumberOfFollowing': numberOfFollowing,
      'NumberOfFriends': numberOfFriends,
      'Friends': friends,
      'BMX': BMX,
      'Roller': Roller,
      'Scooter': Scooter,
      'Skateboard': Skateboard,
      'Description': description,
      'ActualLocationLongitude': actualLocation.longitude,
      'ActualLocationLatitude': actualLocation.latitude,
      'ProfilePictureDownloadPath': profilePictureDownloadPath,
      'PendingFriendsId' : pendingFriendsId,
      'DevicesTokens' : devicesTokens,
      'SubscribedTopics': subscribedTopics,
      'LastUpdate': lastUpdate,
      'CreationDate': creationDate,
    };
  }
}

UserProfile convertMapToUserProfile(Map userProfile) {
  List<String> pendingFriendsId = [];
  if (userProfile['PendingFriendsId'] != null) {
    pendingFriendsId = userProfile['PendingFriendsId'].cast<String>();
  }
  List<String> friendsId = [];
  if (userProfile['Friends'] != null) {
    friendsId = userProfile['Friends'].cast<String>();
  }
  List<String> devicesTokens = [];
  if (userProfile['DevicesTokens'] != null) {
    devicesTokens = userProfile['DevicesTokens'].cast<String>();
  }
  List<String> subscribedTopics = [];
  if (userProfile['SubscribedTopics'] != null) {
    subscribedTopics = userProfile['SubscribedTopics'].cast<String>();
  }
  return UserProfile(
    username: userProfile['Username'],
    pseudo: userProfile['Pseudo'],
    description: userProfile['Description'],
    numberOfFollowers: userProfile['NumberOfFollowers'] ?? 0,
    numberOfFollowing: userProfile['NumberOfFollowing'] ?? 0,
    numberOfFriends: userProfile['NumberOfFriends'] ?? 0,
    friends: friendsId,
    BMX: userProfile['BMX'],
    Roller: userProfile['Roller'],
    Scooter: userProfile['Scooter'],
    Skateboard: userProfile['Skateboard'],
    profilePictureDownloadPath: userProfile['ProfilePictureDownloadPath'],
    pendingFriendsId: pendingFriendsId,
    devicesTokens: devicesTokens,
    subscribedTopics: subscribedTopics,
    lastUpdate: userProfile['LastUpdate'],
    creationDate: userProfile['CreationDate'],
    actualLocation: userProfile['ActualLocationLatitude'] != null &&
            userProfile['ActualLocationLongitude'] != null
        ? LatLng(
            userProfile['ActualLocationLatitude'],
            userProfile['ActualLocationLongitude'],
          )
        : null,
  );
}
