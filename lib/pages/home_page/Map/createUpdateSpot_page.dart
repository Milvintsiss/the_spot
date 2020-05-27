import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/library/gallery.dart';
import 'package:the_spot/services/library/userGrade.dart';
import 'package:the_spot/services/storage.dart';
import 'package:the_spot/theme.dart';
import 'package:vibrate/vibrate.dart';

class CreateUpdateSpotPage extends StatefulWidget {
  CreateUpdateSpotPage({Key key, this.configuration, this.spotId, this.stateCallback})
      : super(key: key);

  final Configuration configuration;
  final String spotId;
  final VoidCallback stateCallback;

  @override
  _CreateUpdateSpotPage createState() => _CreateUpdateSpotPage();
}

class _CreateUpdateSpotPage extends State<CreateUpdateSpotPage> {
  static const int maxAmountOfPictures = 10;


  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  List<String> imagesAddress = [];

  int pictureId = 0;

  String spotName;
  String spotDescription;

  double spotGradeInput;
  double spotGradeBeautyInput;
  double spotGradeFloorInput;


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
              showInput("Spot name", AppLocalizations.of(context).translate("Spot name"), Icons.text_fields),
              showInput("Spot description", AppLocalizations.of(context).translate("Spot description"), Icons.textsms, maxLines: 6),
              showSpotGradesWidget(),
              showConfirmButton(),
            ],
          ),
        ));
  }

  Widget showPhotos() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
        color: SecondaryColorDark,
          child: Gallery(imagesAddress, height: 100)),
    );
  }

  Widget showAddLimitationText() {
    return Center(
      child: Text(
        AppLocalizations.of(context).translate("You can add up to %DYNAMIC photos!", dynamic: maxAmountOfPictures.toString()),
        style: TextStyle(color: PrimaryColorLight),
      ),
    );
  }

  Widget showAddButton() {
    return RaisedButton(
      elevation: 5.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      color: SecondaryColorDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            AppLocalizations.of(context).translate("Add a picture"),
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
    if (pictureId < maxAmountOfPictures) {
      pictureId++;
      await Storage().getPhotoFromUserStorageAndUpload(
          storageRef:
              "SpotPictures/" + widget.spotId + "/" + pictureId.toString(),
          context: context);

      String picture = await Storage().getUrlPhoto(
          "SpotPictures/" + widget.spotId + "/" + pictureId.toString());

      this.setState(() {
        imagesAddress.add(picture);
        showPhotos();
      });
      print(imagesAddress);
    } else {
      Vibrate.feedback(FeedbackType.warning);
      FlushbarHelper.createError(message: AppLocalizations.of(context).translate("You reached the limit amount of pictures!"), duration: Duration(milliseconds: 1500)).show(context);
    }
  }

  Widget showInput(String inputType, String hint, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 20.0, 0, 0.0),
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: maxLines,
        autofocus: false,
        decoration: InputDecoration(
            hintText: hint,
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
            return AppLocalizations.of(context).translate("You must complete this field!");
          else if (value.length > 35 && inputType == "Spot name")
            return AppLocalizations.of(context).translate("The spot name must not exceed 20 characters!");
          else if (value.length > 2000 && inputType == "Spot descritpion")
            return AppLocalizations.of(context).translate("The spot description must not exceed 2000 characters!");
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            showSpotGradeWidget("Spot:", "Spot"),
            showSpotGradeWidget(AppLocalizations.of(context).translate("Floor:"), "Floor"),
            showSpotGradeWidget(AppLocalizations.of(context).translate("Photogenic:"), "Photogenic"),
          ],
        ),
      ),
    );
  }

  Widget showSpotGradeWidget(String spotGradeName, String spotGradeType) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          spotGradeName,
          textAlign: TextAlign.end,
          style: TextStyle(
              color: PrimaryColorDark,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        Divider(
          indent: 40,
        ),
        RatingBar(
          glow: false,
          minRating: 1,
          itemSize: 30,
          unratedColor: PrimaryColor,
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (newGrade) {
            switch (spotGradeType) {
              case "Spot":
                spotGradeInput = newGrade;
                break;
              case "Floor":
                spotGradeFloorInput = newGrade;
                break;
              case "Photogenic":
                spotGradeBeautyInput = newGrade;
                break;
            }
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        color: SecondaryColorDark,
        child: Text(
          AppLocalizations.of(context).translate("Save"),
          style: TextStyle(fontSize: 20.0, color: Colors.white),
        ),
        onPressed: save,
      ),
    );
  }

  void save() async {
    if (validateAndSave()) {
      if (spotGradeInput != null &&
          spotGradeBeautyInput != null &&
          spotGradeFloorInput != null) {
        UserGrades userGrades = UserGrades(
            userId: widget.configuration.userData.userId,
            spotGrade: spotGradeInput,
            spotGradeFloor: spotGradeFloorInput,
            spotGradeBeauty: spotGradeBeautyInput);

        Database().updateASpot(
            context: context,
            creatorId: widget.configuration.userData.userId,
            spotId: widget.spotId,
            spotName: spotName,
            spotDescription: spotDescription,
            imagesDownloadUrls: imagesAddress,
            userGrade: userGrades);

        widget.stateCallback();
        Navigator.pop(context);
      } else {
        Vibrate.feedback(FeedbackType.warning);
        FlushbarHelper.createError(message: AppLocalizations.of(context).translate("You must give a global grade, a floor grade and a \"photogenic grade!\" Minimum grade is 1 star."), duration: Duration(milliseconds: 4000)).show(context);
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
