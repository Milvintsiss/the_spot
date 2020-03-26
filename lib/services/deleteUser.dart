import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vibrate/vibrate.dart';

import 'authentication.dart';
import 'database.dart';

class DeleteUser {
  DeleteUser(this.auth, this.userId, this.logoutCallback, this.context);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;
  final BuildContext context;

  void showDeleteUserDataConfirmDialog() {
    Vibrate.feedback(FeedbackType.warning);
    showDialog(
        context: context,
        child: AlertDialog(
          elevation: 0,
          content: Text(
            "Are you sure you want to delete your account? All your data will be erased, "
            "this action is irreversible! If you want the deleting of your data be effective you must be recently logged in,"
            " if you're not please logout and login before proceed.",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            FlatButton(
                child: Text("I'm sure I want to erase all my Data"),
                onPressed: () {
                  Navigator.pop(context);
                  deleteUserData();
                })
          ],
        ));
  }

  void deleteUserData() async {
    try {
      bool userDeleted = await Auth().deleteCurrentUser();
      if (userDeleted) {
        bool userProfileDeleted =
        await Database().deleteProfileData(context, userId);
        if (userProfileDeleted) {
          final StorageReference storageReference =
          FirebaseStorage().ref().child("ProfilePictures/" + userId);
          await storageReference.delete();
          //all deletions accomplished

          logoutCallback();
        } else {
          error("Error deleting your data, please retry", context);
        }
      } else {
        error("Error deleting your account, please retry", context);
      }
    } catch(err) {
      print(err.toString());
      logoutCallback();
    }
  }

  void error(String error, BuildContext context) {
    Vibrate.feedback(FeedbackType.warning);

    AlertDialog errorAlertDialog = AlertDialog(
        elevation: 0,
        content: SelectableText(
          error,
          style: TextStyle(
              color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
        ));

    showDialog(context: context, child: errorAlertDialog);
  }
}
