import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/gallery.dart';
import 'package:the_spot/services/library/userGrade.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/theme.dart';
import 'package:vibrate/vibrate.dart';

class CreateUpdateSpotPage extends StatefulWidget {
  CreateUpdateSpotPage( {Key key, this.userId, this.spotId, this.stateCallback}) : super(key: key);

  final String userId;
  final String spotId;
  final VoidCallback stateCallback;

  @override
  _CreateUpdateSpotPage createState() => _CreateUpdateSpotPage();
}

class _CreateUpdateSpotPage extends State<CreateUpdateSpotPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  List<String> imagesAddress = <String>[];

  int pictureId = 0;

  String spotName;
  String spotDescription;


  double spotGradeInput;
  double spotGradeBeautyInput;
  double spotGradeFloorInput;

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
              showSpotGradesWidget(),
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
        child: Gallery(imagesAddress, height: 200));
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

      String picture = await Storage().getUrlPhoto("SpotPictures/" + widget.spotId + "/" + pictureId.toString());

      this.setState(() {
        imagesAddress.add(picture);
        showPhotos();
      });
      print(imagesAddress);
    }else{
      Vibrate.feedback(FeedbackType.warning);
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
          else if (value.length > 35 && inputType == "Spot name")
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

  Widget showSpotGradesWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Container(
        decoration: BoxDecoration(
            color: SecondaryColorDark,
            borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          children: <Widget>[
            showSpotGradeWidget("Spot:    "),
            showSpotGradeWidget("Floor:   "),
            showSpotGradeWidget("Beauty:"),
          ],
        ),
      ),
    );
  }

  Widget showSpotGradeWidget(String spotGradeName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          spotGradeName,
          style:
          TextStyle(color: PrimaryColorDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
    Divider(indent: 40,),
    RatingBar(
          glow: false,
          minRating: 1,
          itemSize: 30,
          unratedColor: PrimaryColor,
          itemBuilder: (context, _) =>
              Icon(
                Icons.star,
                color: Colors.amber,
              ),
          onRatingUpdate: (newGrade) {
            switch (spotGradeName) {
              case "Spot:    ":
                spotGradeInput = newGrade;
                break;
              case "Floor:   ":
                spotGradeFloorInput = newGrade;
                break;
              case "Beauty:":
                spotGradeBeautyInput = newGrade;
                break;
            }
            print(spotGradeName + newGrade.toString());
          },
        ),
      ],
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
      if (spotGradeInput != null &&
      spotGradeBeautyInput != null &&
      spotGradeFloorInput != null) {
        print("Spot name: " + spotName);
        print("Spot description: " + spotDescription);
        UserGrades userGrades = UserGrades(
            userId: widget.userId,
            spotGrade: spotGradeInput,
            spotGradeFloor: spotGradeFloorInput,
            spotGradeBeauty: spotGradeBeautyInput);

        Database().updateASpot(context: context, spotId: widget.spotId, spotName: spotName, spotDescription: spotDescription, imagesDownloadUrls: imagesAddress, userGrade: userGrades);

        widget.stateCallback();
        Navigator.pop(context);
      }else {
        Vibrate.feedback(FeedbackType.warning);
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text("You must give a global grade, a floor grade and a beauty grade! Minimum grade is 1 star."),
          duration: Duration(milliseconds: 4000),
        ));
      }
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
