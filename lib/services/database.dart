import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/services/library/UserProfile.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:vibrate/vibrate.dart';

import 'package:the_spot/services/library/userGrade.dart';

class Database {
  final database = Firestore.instance;

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
      String pseudo,
      bool BMX,
      bool Roller,
      bool Scooter,
      bool Skateboard,
      String description,
      LatLng actualLocation}) async {
    final connectionState = await checkConnection(context);

    String updateDate = DateTime.now().toIso8601String();
    String creationDate;
    if (onCreate) creationDate = updateDate;

    Map update = Map<String, dynamic>.identity();
    if (pseudo != null) update['Pseudo'] = pseudo;
    if (BMX != null) update['BMX'] = BMX;
    if (Roller != null) update['Roller'] = Roller;
    if (Scooter != null) update['Scooter'] = Scooter;
    if (Skateboard != null) update['Skateboard'] = Skateboard;
    if (description != null) update['Description'] = description;
    if (actualLocation != null) {
      update['ActualLocationLongitude'] = actualLocation.longitude;
      update['ActualLocationLatitude'] = actualLocation.latitude;
    }

    if (creationDate != null) update['CreationDate'] = creationDate;

    update['LastUpdate'] = updateDate;

    print(update);

    if (connectionState) {
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
              .setData({})
              .catchError((err) {
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

  Future<UserProfile> getProfileData(String userId, BuildContext context) async {
    final connectionState = await checkConnection(context);
    UserProfile userProfile;
    if (connectionState) {
      try {
        await database
            .collection("users")
            .document(userId)
            .get()
        .then((DocumentSnapshot document) {
          userProfile = ConvertMapToUserProfile(document.data);

        })
            .catchError((err) {
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

  Future<bool> deleteProfileData(BuildContext context, String userId) async {
    final bool connectionState = await checkConnection(context);

    if (connectionState) {
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
        print(err);
        error(err.toString(), context);
        return false;
      }
    } else {
      return false;
    }
    return true;
  }

  void updateUserLocation({@required BuildContext context, @required String userId, @required LatLng userLocation}) async {
    final bool connectionState = await checkConnection(context);

    if (connectionState){
      await database
          .collection("usersLocation")
          .document(userId)
          .updateData({
      'UserLocationLongitude': userLocation.longitude,
        'UserLocationLatitude': userLocation.latitude,
        'UserId': userId,
          })
          .catchError((err) {
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
      bool onCreate = false}) async {
    final bool connectionState = await checkConnection(context);

    String state;

    if (connectionState) {
      Map _spotData = await spotData(context, onCreate, spotId, spotLocation,
          creatorId, spotName, spotDescription, imagesDownloadUrls, userGrade);

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
  ) async {
    Map data = Map<String, dynamic>.identity();

    String updateDate = DateTime.now().toIso8601String();
    String creationDate;
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
    if (userGrade != null)
      data['UsersGrades'] =
          await createListUsersGrades(context, userGrade, spotId, creatorId);

    if (creationDate != null) data['CreationDate'] = creationDate;
    data['LastUpdate'] = updateDate;

    return data;
  }

  Future<List> createListUsersGrades(BuildContext context, UserGrades userGrade,
      String spotId, String userId) async {
    List<MapMarker> spots = await getSpots(context, getAll: true);
    MapMarker spot = spots.firstWhere((element) => element.markerId == spotId);

    //verify if the user don't have already rated this spot, if yes update his grade
    int index =
        spot.usersGrades.indexWhere((element) => element.userId == userId);

    if (index == -1) {
      spot.usersGrades.add(userGrade);
    } else {
      print("update");
      spot.usersGrades[index] = userGrade;
    }

    List<Map> usersGrades = ConvertUsersGradesToMap(spot.usersGrades);

    return usersGrades;
  }

  Future<List> getSpots(BuildContext context, {bool getAll = false}) async {
    final bool connectionState = await checkConnection(context);

    List<MapMarker> spots = new List();

    if (connectionState) {
      await database
          .collection("spots")
          .getDocuments()
          .then((QuerySnapshot snapshot) {
        snapshot.documents.forEach((document) {
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
            usersGrades =
                ConvertMapToUsersGrades(data['UsersGrades'].cast<Map>());
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
          );
          if (data['SpotName'] != null || getAll) {
            //verify if spot has been updated after his creation
            spots.add(spot);
          }
        });
      }).catchError((err) {
        print(err);
        error(err.toString(), context);
        return null;
      });
    } else {
      return null;
    }
    return spots;
  }

  Future<bool> checkConnection(BuildContext context) async {
    bool hasConnection;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasConnection = true;
      } else {
        hasConnection = false;
      }
    } on SocketException catch (_) {
      hasConnection = false;
    }
    if (!hasConnection) {
      error(
          AppLocalizations.of(context).translate('Please connect to internet!'),
          context);
    }
    return hasConnection;
  }

  void error(String error, BuildContext context) {
    Vibrate.feedback(FeedbackType.warning);

    AlertDialog errorAlertDialog = new AlertDialog(
        elevation: 0,
        content: SelectableText(
          error,
          style: TextStyle(
              color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
        ));

    showDialog(context: context, child: errorAlertDialog);
  }
}
