import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/gallery.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:the_spot/services/library/userGrade.dart';
import 'package:the_spot/theme.dart';

class SpotInfoWidget extends StatefulWidget {
  SpotInfoWidget(
      {@required this.setStateBottomSheet,
      @required this.spot,
      @required this.userId,
      @required this.screenWidth,
      @required this.screenHeight});

  final StateSetter setStateBottomSheet;
  final MapMarker spot;
  final String userId;
  final double screenWidth;
  final double screenHeight;

  @override
  _SpotInfoWidgetState createState() => _SpotInfoWidgetState();
}

class _SpotInfoWidgetState extends State<SpotInfoWidget> {
  bool userIsRatingTheSpot = false;
  bool spotHasGrades = true;
  bool userRatingNotComplete = false;
  double spotGrade;
  double spotGradeBeauty;
  double spotGradeFloor;
  double spotGradeInput;
  double spotGradeBeautyInput;
  double spotGradeFloorInput;

  @override
  Widget build(BuildContext context) {
    bool _isSpotHasImages;
    if (widget.spot.imagesDownloadUrls == null ||
        widget.spot.imagesDownloadUrls.length == 0)
      _isSpotHasImages = false;
    else
      _isSpotHasImages = true;
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(70),
        topRight: Radius.circular(70),
      ),
      child: Container(
          height: widget.screenHeight * 4 / 9,
          color: PrimaryColorDark,
          child: ListView(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
            children: <Widget>[
              _isSpotHasImages
                  ? showSpotPhotosWidget(widget.spot.imagesDownloadUrls)
                  : Container(),
              showSpotNameWidget(widget.spot.name),
              showSpotGradesWidget(
                  widget.spot.usersGrades, widget.spot.markerId),
              showSpotDescriptionWidget(widget.spot.description),
            ],
          )),
    );
  }

  Widget showSpotGradesWidget(List<UserGrades> usersGrades, String spotId) {
    spotGrade = 0;
    spotGradeFloor = 0;
    spotGradeBeauty = 0;

    if (usersGrades.length > 0) {
      List<double> listSpotGrade = [];
      List<double> listSpotGradeBeauty = [];
      List<double> listSpotGradeFloor = [];

      usersGrades.forEach((element) {
        listSpotGrade.add(element.spotGrade);
        listSpotGradeFloor.add(element.spotGradeFloor);
        listSpotGradeBeauty.add(element.spotGradeBeauty);
      });

      spotGrade = listSpotGrade.reduce((a, b) => a + b) / listSpotGrade.length;
      spotGradeFloor = listSpotGradeFloor.reduce((a, b) => a + b) /
          listSpotGradeFloor.length;
      spotGradeBeauty = listSpotGradeBeauty.reduce((a, b) => a + b) /
          listSpotGradeBeauty.length;
      print(spotGrade);
      print(spotGradeFloor);
      print(spotGradeBeauty);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
            color: PrimaryColorLight,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.all(width: 3, color: PrimaryColor)),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(
                      "This spot was rated " +
                          usersGrades.length.toString() +
                          " times!",
                      style: TextStyle(
                          color: PrimaryColorDark, fontStyle: FontStyle.italic),
                    ),
                    showSpotGradeWidget("Spot:    ", spotGrade),
                    showSpotGradeWidget("Floor:   ", spotGradeFloor),
                    showSpotGradeWidget("Beauty:", spotGradeBeauty),
                  ],
                ),
                Divider(
                  indent: 30,
                ),
                RaisedButton(
                  child:
                      Text(userIsRatingTheSpot ? "Confirm" : "Grade this spot"),
                  onPressed: () => onGradeButtonPressed(spotId),
                ),
                userIsRatingTheSpot
                    ? SizedBox(
                        width: 50,
                        child: RaisedButton(
                          child: Icon(
                            Icons.undo,
                            size: 20,
                          ),
                          onPressed: () => widget.setStateBottomSheet(() {
                            userIsRatingTheSpot = false;
                            userRatingNotComplete = false;
                            spotGradeInput = null;
                            spotGradeBeautyInput = null;
                            spotGradeFloorInput = null;
                          }),
                        ),
                      )
                    : Container()
              ],
            ),
            userRatingNotComplete
                ? Text(
                    "You must give a grade for all fields! Minimum grade is 1 star.",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  void onGradeButtonPressed(String spotId) async {
    UserGrades userGrades = UserGrades(
        userId: widget.userId,
        spotGrade: spotGradeInput,
        spotGradeFloor: spotGradeFloorInput,
        spotGradeBeauty: spotGradeBeautyInput);
    if (userIsRatingTheSpot &&
        spotGradeInput != null &&
        spotGradeBeautyInput != null &&
        spotGradeFloorInput != null) {
      await Database().updateASpot(
          context: context,
          spotId: spotId,
          userGrade: userGrades,
          creatorId: widget.userId);

      spotGradeInput = null;
      spotGradeBeautyInput = null;
      spotGradeFloorInput = null;
      userRatingNotComplete = false;

      widget.setStateBottomSheet(() {
        userIsRatingTheSpot = !userIsRatingTheSpot;
      });
    } else if (userIsRatingTheSpot) {
      widget.setStateBottomSheet(() {
        userRatingNotComplete = true;
      });
    } else {
      widget.setStateBottomSheet(() {
        userIsRatingTheSpot = !userIsRatingTheSpot;
      });
    }
  }

  Widget showSpotGradeWidget(
    String spotGradeName,
    double spotGrade,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          spotGradeName,
          style:
              TextStyle(color: PrimaryColorDark, fontWeight: FontWeight.bold),
        ),
        userIsRatingTheSpot
            ? RatingBar(
                glow: false,
                minRating: 1,
                itemSize: 20,
                unratedColor: PrimaryColor,
                itemBuilder: (context, _) => Icon(
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
              )
            : RatingBarIndicator(
                rating: spotGrade,
                itemSize: 20,
                unratedColor: PrimaryColor,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
              ),
      ],
    );
  }

  Widget showSpotNameWidget(String spotName) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Center(
          child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SecondaryColorDark,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(
                spotName,
                style: TextStyle(color: Colors.white, fontSize: 25),
              )),
        ));
  }

  Widget showSpotPhotosWidget(List<String> imagesAddress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Gallery(imagesAddress, height: 100),
    );
  }

  Widget showSpotDontHaveImagesMessageWidget() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Text("We don't have pictures of this spot for the moment..."));
  }

  Widget showSpotDescriptionWidget(String spotDescription) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Center(
        child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PrimaryColor,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: Text(
              spotDescription,
              style: TextStyle(color: Colors.white, fontSize: 15),
            )),
      ),
    );
  }
}
