

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_spot/app_localizations.dart';

 class Database {

  final databaseReference = Firestore.instance;



  void createRecord() async {
    await databaseReference.collection("books").document("1").setData({
      'title': 'Mastering Flutter',
      'description': 'Programming Guide for Dart'
    });

    DocumentReference ref = await databaseReference.collection("books").add({
      'title': 'Flutter in Action',
      'description': 'Complete Programming Guide to learn Flutter'
    });
    print(ref.documentID);
  }

  void getData() {
    databaseReference
        .collection("books")
        .getDocuments()
        .then((QuerySnapshot snapshot) {
      snapshot.documents.forEach((f) => print('${f.data}}'));
    });
  }

  void updateData() {
    try {
      databaseReference
          .collection('books')
          .document('1')
          .updateData({'description': 'Head First Flutter'});
    } catch (e) {
      print(e.toString());
    }
  }

  void deleteData() {
    try {
      databaseReference.collection('books').document('1').delete();
    } catch (e) {
      print(e.toString());
    }
  }

  Future <bool> updateProfile(String ID, String Pseudo, bool BMX, bool Roller, bool Scooter, bool Skateboard, BuildContext context) async {
    final connectionState =  await checkConnection();

    if (!connectionState) {
      error(
          AppLocalizations.of(context).translate('Please connect to internet!'),
          context);
      return false;
    }
    else{
      try {
        await databaseReference
            .collection('users')
            .document(ID)
            .setData({
          'Pseudo': Pseudo,
          'BMX': BMX,
          'Roller': Roller,
          'Scooter': Scooter,
          'Skateboard': Skateboard
        })
            .catchError((error) {
          error(error, context);
          print(error);
          return false;
        });
      } catch (e) {
        print(e);
        error(e, context);
        return false;
      }
    }
    return true;
  }



  Future<bool> checkConnection() async {
    bool hasConnection;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasConnection = true;
      } else {
        hasConnection = false;
      }
    } on SocketException catch(_) {
      hasConnection = false;
    }
    return hasConnection;
  }



  void error(String error, BuildContext context){

    AlertDialog errorAlertDialog = new AlertDialog(
      content: Text(error, style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),)
    );

    showDialog(context: context, child: errorAlertDialog);
  }
}
