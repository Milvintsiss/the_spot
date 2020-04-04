import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:vibrate/vibrate.dart';

import 'package:the_spot/services/library/userRate.dart';

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
      String description}) async {
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

  Future<Map> getProfileData(String userId, BuildContext context) async {
    final connectionState = await checkConnection(context);
    DocumentSnapshot document;
    if (connectionState) {
      try {
        document = await database
            .collection("users")
            .document(userId)
            .get()
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
      Map data = document.data;
      return data;
    }
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

  Future<String> updateASpot(
      {@required BuildContext context,
      @required String spotId,
      String creatorId,
      LatLng spotLocation,
      String spotName,
      String spotDescription,
      List<String> imagesDownloadUrls,
      UserRates userRate,
      bool onCreate = false}) async {
    final bool connectionState = await checkConnection(context);

    String state;

    if (connectionState) {
      Map _spotData =  await spotData(context, onCreate, spotId, spotLocation, creatorId, spotName,
          spotDescription, imagesDownloadUrls, userRate);

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

  Future <Map> spotData(
      BuildContext context,
      bool onCreate,
      String spotId,
      LatLng spotLocation,
      String creatorId,
      String spotName,
      String spotDescription,
      List<String> imagesDownloadUrls,
      UserRates userRate,) async {
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
    if (userRate != null) data['UsersRates'] = await createListUsersRates(context, userRate, spotId);

    if (creationDate != null) data['CreationDate'] = creationDate;
    data['LastUpdate'] = updateDate;

    return data;
  }
  
  Future<List> createListUsersRates(BuildContext context, UserRates userRate, String spotId) async {
    List<MapMarker> spots = await getSpots(context);

    MapMarker spot = spots.firstWhere((element) => element.markerId == spotId);
    spot.usersRates.add(userRate);

    List<Map> usersRates = ConvertUsersRatesToMap(spot.usersRates);

    return usersRates;
  }

  Future<List> getSpots(BuildContext context) async {
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

          //convert the List of UserRatess to a List of Map
          List<UserRates> usersRates = [];
          if (data['UsersRates'] != null){
            usersRates = ConvertMapToUsersRates(data['UsersRates'].cast<Map>());
            usersRates.forEach((element) {
              print(element.userId + " / " + element.spotRate.toString() + " / " + element.spotRateFloor.toString() + " / " + element.spotRateBeauty.toString());
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
            usersRates: usersRates,
          );
          if (data['SpotName'] != null) {
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
