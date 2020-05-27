import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:vibrate/vibrate.dart';

import 'configuration.dart';

class DeleteUser {
  DeleteUser(this.configuration, this.context);

  final Configuration configuration;
  final BuildContext context;

  void showDeleteUserDataConfirmDialog() {
    Vibrate.feedback(FeedbackType.warning);
    showDialog(
        context: context,
        child: AlertDialog(
          elevation: 0,
          content: Text(
            AppLocalizations.of(context).translate(
                "Are you sure you want to delete your account? All your data will be erased including messages, profile picture, and profile info. This action is irreversible."),
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(AppLocalizations.of(context).translate("Cancel")),
              onPressed: () => Navigator.pop(context),
            ),
            FlatButton(
                child: Text(AppLocalizations.of(context).translate("I want to erase all my data")),
                onPressed: () {
                  Navigator.pop(context);
                  deleteUserData();
                })
          ],
        ));
  }

  void deleteUserData() async {
    final CloudFunctions cloudFunctions = CloudFunctions(
      region: 'us-central1',
    );
    final HttpsCallable deleteUserFunction =
        cloudFunctions.getHttpsCallable(functionName: 'deleteUser');
    deleteUserFunction.call();
    configuration.logoutCallback();

//    try {
//      bool userDeleted = await Auth().deleteCurrentUser();
//      if (userDeleted) {
//        bool userProfileDeleted =
//        await Database().deleteProfileData(context, userId);
//        if (userProfileDeleted) {
//          final StorageReference storageReference =
//          FirebaseStorage().ref().child("ProfilePictures/" + userId);
//          await storageReference.delete();
//          //all deletions accomplished
//
//          logoutCallback();
//        } else {
//          error("Error deleting your data, please retry", context);
//        }
//      } else {
//        error("Error deleting your account, please retry", context);
//      }
//    } catch(err) {
//      print(err.toString());
//      logoutCallback();
//    }
  }
}
