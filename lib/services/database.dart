import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:vibrate/vibrate.dart';

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

  Future<String> addASpot(
      BuildContext context, LatLng spotLocation, String creatorId,
      {String spotName, String spotDescription}) async {
    final bool connectionState = await checkConnection(context);

    String spotId;

    if (connectionState) {
      Map _spotData = spotData(true, spotLocation, creatorId, spotName, spotDescription);

      await database
          .collection("spots")
          .add(_spotData)
          .then((value) => spotId = value.documentID)
          .catchError((err) {
        print(err);
        error(err.toString(), context);
        return null;
      });
    } else {
      return null;
    }
    print(spotId);
    return spotId;
  }

  Future<bool> updateASpot(
      BuildContext context, String spotId,
      {String creatorId, LatLng spotLocation, String spotName, String spotDescription}) async {
    final bool connectionState = await checkConnection(context);

    if (connectionState) {
      Map _spotData = spotData(false, spotLocation, creatorId, spotName, spotDescription);

      await database
          .collection("spots")
          .document(spotId)
          .updateData(_spotData)
          .catchError((err) {
        print(err);
        error(err.toString(), context);
        return false;
      });
    } else {
      return false;
    }
    return true;
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
          MapMarker spot = MapMarker(
              id: document.documentID,
              position: new LatLng(data['SpotLocationLatitude'], data['SpotLocationLongitude']),
              icon: BitmapDescriptor.defaultMarker,
              description: data['Description'],
          );
          spots.add(spot);
        });
      })
          .catchError((err) {
        print(err);
        error(err.toString(), context);
        return null;
      });
    }else{
      return null;
    }
    return spots;
  }

  Map spotData(
      bool onCreate,
      LatLng spotLocation,
      String creatorId,
      String spotName,
      String spotDescription) {
    String updateDate = DateTime.now().toIso8601String();
    String creationDate;
    if (onCreate) creationDate = updateDate;

    Map data = Map<String, dynamic>.identity();

    if (spotLocation != null){
      data['SpotLocationLatitude'] = spotLocation.latitude;
      data['SpotLocationLongitude'] = spotLocation.longitude;
    }
    if (creatorId != null) data['CreatorId'] = creatorId;
    if (spotName != null) data['SpotName'] = spotName;
    if (spotDescription != null) data['SpotDescription'] = spotDescription;

    if (creationDate != null) data['CreationDate'] = creationDate;
    data['LastUpdate'] = updateDate;

    return data;
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
