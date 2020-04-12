import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserProfile {
  UserProfile({
    this.userId,
    this.pseudo,
    this.description,
    this.actualLocation,
    this.BMX,
    this.Roller,
    this.Scooter,
    this.Skateboard,
    this.lastUpdate,
    this.creationDate,
  });

  String userId;
  String pseudo;
  bool BMX;
  bool Roller;
  bool Scooter;
  bool Skateboard;
  String description;
  LatLng actualLocation;
  String lastUpdate;
  String creationDate;

  Map<String, dynamic> toMap() {
    return {
      'Pseudo': pseudo,
      'BMX': BMX,
      'Roller': Roller,
      'Scooter': Scooter,
      'Skateboard': Skateboard,
      'Description': description,
      'ActualLocationLongitude': actualLocation.longitude,
      'ActualLocationLatitude': actualLocation.latitude,
      'LastUpdate': lastUpdate,
      'CreationDate': creationDate,
    };
  }
}

UserProfile ConvertMapToUserProfile(Map userProfile) {
  UserProfile _userProfile = UserProfile();
  _userProfile.pseudo = userProfile['Pseudo'];
  _userProfile.description = userProfile['Description'];

  _userProfile.BMX = userProfile['BMX'];
  _userProfile.Roller = userProfile['Roller'];
  _userProfile.Scooter = userProfile['Scooter'];
  _userProfile.Skateboard = userProfile['Skateboard'];

  if (userProfile['ActualLocationLatitude'] != null &&
      userProfile['ActualLocationLongitude'] != null)
    _userProfile.actualLocation = LatLng(
      userProfile['ActualLocationLatitude'],
      userProfile['ActualLocationLongitude'],
    );

  _userProfile.creationDate = userProfile['CreationDate'];
  _userProfile.lastUpdate = userProfile['LastUpdate'];

  return _userProfile;
}
