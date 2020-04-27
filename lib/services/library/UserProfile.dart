import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserProfile {
  UserProfile({
    this.username,
    this.userId,
    this.pseudo,
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
  bool BMX;
  bool Roller;
  bool Scooter;
  bool Skateboard;
  String description;
  LatLng actualLocation;
  String profilePictureDownloadPath;
  final String lastUpdate;
  final String creationDate;

  Map<String, dynamic> toMap() {
    return {
      'Username': username,
      'Pseudo': pseudo,
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
