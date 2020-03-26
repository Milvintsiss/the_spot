import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';

class Storage {
  File _file;

  Future<bool> getPhotoFromUserStorageAndUpload(String storageRef,
      {CropAspectRatio cropAspectRatio,
      CropStyle cropStyle,
      int maxHeight = 1080,
      int maxWidth = 1080,
      int compressQuality = 75})
  async {
    _file = await ImagePicker.pickImage(source: ImageSource.gallery);

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
    if(uploadTask.isSuccessful){
      print("Image uploaded with success");
      return true;
    }
    else{
      print("Error when uploading image...");
      return false;
    }

  }
}
