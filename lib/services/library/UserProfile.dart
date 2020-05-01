import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserProfile {
  UserProfile({
    this.username,
    this.userId,
    this.pseudo,
    this.numberOfFollowers,
    this.numberOfFollowing,
    this.numberOfFriends,
    this.description,
    this.actualLocation,
    this.BMX,
    this.Roller,
    this.Scooter,
    this.Skateboard,
    this.profilePictureDownloadPath,
    this.lastUpdate,
    this.creationDate,
  });

  String username;
  String userId;
  String pseudo;
  int numberOfFollowers;
  int numberOfFollowing;
  int numberOfFriends;
  bool BMX;
  bool Roller;
  bool Scooter;
  bool Skateboard;
  String description;
  LatLng actualLocation;
  String profilePictureDownloadPath;
  final Timestamp lastUpdate;
  final Timestamp creationDate;

  Map<String, dynamic> toMap() {
    return {
      'Username': username,
      'Pseudo': pseudo,
      'NumberOfFollowers': numberOfFollowers,
      'NumberOfFollowing': numberOfFollowing,
      'NumberOfFriends': numberOfFriends,
      'BMX': BMX,
      'Roller': Roller,
      'Scooter': Scooter,
      'Skateboard': Skateboard,
      'Description': description,
      'ActualLocationLongitude': actualLocation.longitude,
      'ActualLocationLatitude': actualLocation.latitude,
      'ProfilePictureDownloadPath': profilePictureDownloadPath,
      'LastUpdate': lastUpdate,
      'CreationDate': creationDate,
    };
  }
}

UserProfile ConvertMapToUserProfile(Map userProfile) {
  return UserProfile(
    username: userProfile['Username'],
    pseudo: userProfile['Pseudo'],
    description: userProfile['Description'],
    numberOfFollowers: userProfile['NumberOfFollowers'] ?? 0,
    numberOfFollowing: userProfile['NumberOfFollowing'] ?? 0,
    numberOfFriends: userProfile['NumberOfFriends'] ?? 0,
    BMX: userProfile['BMX'],
    Roller: userProfile['Roller'],
    Scooter: userProfile['Scooter'],
    Skateboard: userProfile['Skateboard'],
    profilePictureDownloadPath: userProfile['ProfilePictureDownloadPath'],
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
