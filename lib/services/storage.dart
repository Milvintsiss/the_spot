import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_spot/app_localizations.dart';

import '../theme.dart';

class Storage {


  Future<bool> getPhotoFromUserStorageAndUpload(
      {@required String storageRef,
      @required BuildContext context,
      bool getPhotoFromGallery = false,
      bool letUserChooseImageSource = true,
      CropAspectRatio cropAspectRatio,
      CropStyle cropStyle,
      int maxHeight = 1080,
      int maxWidth = 1080,
      int compressQuality = 75}) async {
    File _file;
    if (letUserChooseImageSource) {
      getPhotoFromGallery = null;
      AlertDialog errorAlertDialog = new AlertDialog(
        elevation: 0,
        backgroundColor: PrimaryColorDark,
        title: Text(AppLocalizations.of(context).translate("Get image from:"), style: TextStyle(color: PrimaryColor),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(
                AppLocalizations.of(context).translate("Camera"),
                style: TextStyle(color: PrimaryColorLight),
              ),
              leading: Icon(
                Icons.photo_camera,
                color: PrimaryColorLight,
              ),
              onTap: () {
                getPhotoFromGallery = false;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context).translate("Gallery"),
                style: TextStyle(color: PrimaryColorLight),
              ),
              leading: Icon(
                Icons.photo_library,
                color: PrimaryColorLight,
              ),
              onTap: () {
                getPhotoFromGallery = true;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );

      await showDialog(context: context, child: errorAlertDialog);
    }
    if (getPhotoFromGallery != null) {
      _file = await ImagePicker.pickImage(
          source:
              getPhotoFromGallery ? ImageSource.gallery : ImageSource.camera);

      if (_file != null) {
        _file = await ImageCropper.cropImage(
            sourcePath: _file.path,
            aspectRatio: cropAspectRatio,
            cropStyle: cropStyle,
            maxHeight: maxHeight,
            maxWidth: maxWidth,
            compressQuality: compressQuality,
            androidUiSettings: AndroidUiSettings(
              toolbarColor: PrimaryColorDark,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: PrimaryColorLight,
              lockAspectRatio: true,
            ),
            iosUiSettings: IOSUiSettings(
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ));

        final StorageReference storageReference =
            FirebaseStorage().ref().child(storageRef);
        final StorageUploadTask uploadTask = storageReference.putFile(_file);
        await uploadTask.onComplete;
        if (uploadTask.isSuccessful) {
          print("Image uploaded with success");
          return true;
        } else {
          print("Error when uploading image...");
          return false;
        }
      }
    }
    return false;
  }

  Future<String> getUrlPhoto(String locationOnStorage) async {
    StorageReference storageReference =
        FirebaseStorage().ref().child(locationOnStorage);
    String picture = await storageReference.getDownloadURL();
    return picture;
  }
}
