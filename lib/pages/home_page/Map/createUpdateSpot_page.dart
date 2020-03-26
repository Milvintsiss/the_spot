import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/gallery.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/theme.dart';
import 'package:vibrate/vibrate.dart';

class CreateUpdateSpotPage extends StatefulWidget {
  CreateUpdateSpotPage(this.spotId, {Key key, this.stateCallback}) : super(key: key);

  final String spotId;
  final VoidCallback stateCallback;

  @override
  _CreateUpdateSpotPage createState() => _CreateUpdateSpotPage();
}

class _CreateUpdateSpotPage extends State<CreateUpdateSpotPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  List<String> imageAddress = <String>[];

  int pictureId = 0;

  String spotName;
  String spotDescription;

  final int maxAmountOfPictures = 10;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
        backgroundColor: PrimaryColorDark,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            children: <Widget>[
              showPhotos(),
              showAddLimitationText(),
              showAddButton(),
              showInput("Spot name", Icons.text_fields),
              showInput("Spot description", Icons.textsms, maxLines: 6),
              showConfirmButton(),
            ],
          ),
        ));
  }

  Widget showPhotos() {
    return Container(
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
            color: PrimaryColor,
            borderRadius: BorderRadius.all(Radius.circular(10)),),
        child: Gallery(imageAddress, height: 200));
  }
  Widget showAddLimitationText(){
    return Text(
      "You can add up to 10 photos",
      style: TextStyle(color: PrimaryColorLight),
    );
  }

  Widget showAddButton() {
    return RaisedButton(
      elevation: 5.0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0)),
      color: SecondaryColorDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            "Add a Picture",
            style: TextStyle(fontSize: 20.0, color: Colors.white),
          ),
          Divider(
            indent: 10,
          ),
          Icon(
            Icons.add_circle,
          )
        ],
      ),
      onPressed: addImage,
    );
  }

  void addImage() async {
    if(pictureId < maxAmountOfPictures) {
      pictureId++;
      await Storage().getPhotoFromUserStorageAndUpload(
          "SpotPictures/" + widget.spotId + "/" + pictureId.toString());
      StorageReference storageReference =
      FirebaseStorage().ref().child(
          "SpotPictures/" + widget.spotId + "/" + pictureId.toString());
      String picture = await storageReference.getDownloadURL();
      this.setState(() {
        imageAddress.add(picture);
        showPhotos();
      });
      print(imageAddress);
    }else{
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("You riched the limit amount of photos!"),
        duration: Duration(milliseconds: 1500),
      ));
    }
  }

  Widget showInput(String inputType, IconData icon,{int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 20.0, 0, 0.0),
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: maxLines,
        autofocus: false,
        decoration: InputDecoration(
            hintText: inputType,
            hintStyle: TextStyle(color: Colors.blueGrey[100]),
            fillColor: SecondaryColorDark,
            filled: true,
            contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            icon: Icon(
              icon,
              color: Colors.blueGrey[100],
            )),
        validator: (value) {
          if (value.isEmpty)
            return "You must complete this field!";
          else if (value.length > 20 && inputType == "Spot name")
            return "The spot name must not exceed 20 characters!";
          else if (value.length > 2000 && inputType == "Spot descritpion")
            return "The spot description must not exceed 2000 characters!";
          else
            return null;
        },
        onSaved: (value) {
          switch (inputType) {
            case "Spot name":
              spotName = value.trim();
              break;
            case "Spot description":
              spotDescription = value.trim();
              break;
          }
        },
      ),
    );
  }

  Widget showConfirmButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
      child: RaisedButton(
        elevation: 5.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0)),
        color: SecondaryColorDark,
        child: Text(
          "Save",
          style: TextStyle(fontSize: 20.0, color: Colors.white),
        ),
        onPressed: save,
      ),
    );
  }

  void save() async {
    if (validateAndSave()){
      print("Spot name: " + spotName);
      print("Spot description" + spotDescription);

      Database().updateASpot(context, widget.spotId, spotName: spotName, spotDescription: spotDescription);

      Navigator.pop(context);
    }
  }

  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    Vibrate.feedback(FeedbackType.warning);
    return false;
  }
}
