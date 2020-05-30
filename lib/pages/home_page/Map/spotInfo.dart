import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/library/gallery.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:the_spot/services/library/userGrade.dart';
import 'package:the_spot/theme.dart';

class SpotInfoWidget extends StatefulWidget {
  SpotInfoWidget(
      {@required this.configuration,
      @required this.setStateBottomSheet,
      @required this.spot,
      @required this.userId,
      @required this.screenWidth,
      @required this.screenHeight});

  final Configuration configuration;
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
  int indexOfUserRate; //-1 if the user has not rated the spot
  double spotGrade;
  double spotGradeBeauty;
  double spotGradeFloor;
  double spotGradeInput;
  double spotGradeBeautyInput;
  double spotGradeFloorInput;

  @override
  void initState() {
    super.initState();
    indexOfUserRate = widget.spot.usersGrades
        .indexWhere((userGrade) => userGrade.userId == widget.userId);
  }

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
              _isSpotHasImages ? showSpotPhotosWidget() : Container(),
              showSpotNameWidget(),
              showSpotGradesWidget(),
              showSpotDescriptionWidget(widget.spot.description),
            ],
          )),
    );
  }

  Widget showSpotGradesWidget() {
    spotGrade = 0;
    spotGradeFloor = 0;
    spotGradeBeauty = 0;

    if (widget.spot.usersGrades.length > 0) {
      List<double> listSpotGrade = [];
      List<double> listSpotGradeBeauty = [];
      List<double> listSpotGradeFloor = [];

      widget.spot.usersGrades.forEach((element) {
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      right: 0,
                      child: Text(
                        AppLocalizations.of(context).translate(
                            "This spot was rated %DYNAMIC times!",
                            dynamic: widget.spot.usersGrades.length.toString()),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: PrimaryColorDark,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                    showSpotGradeWidget("Spot:", "Spot", spotGrade),
                    showSpotGradeWidget(
                        AppLocalizations.of(context).translate("Floor:"),
                        "Floor",
                        spotGradeFloor),
                    showSpotGradeWidget(
                        AppLocalizations.of(context).translate("Photogenic:"),
                        "Photogenic",
                        spotGradeBeauty),
                  ],
                ),
                Divider(
                  indent: widget.configuration.screenWidth / 50,
                ),
                Expanded(
                  child: Wrap(
                    children: [
                      RaisedButton(
                        child: Text(
                          userIsRatingTheSpot
                              ? AppLocalizations.of(context).translate("Confirm")
                              : indexOfUserRate != -1
                                  ? AppLocalizations.of(context)
                                      .translate("Change my rating")
                                  : AppLocalizations.of(context)
                                      .translate("Rate this spot"),
                        ),
                        onPressed: () => onGradeButtonPressed(),
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
                          : Container(),
                    ],
                  ),
                )
              ],
            ),
            userRatingNotComplete
                ? Text(
                    AppLocalizations.of(context).translate(
                        "You must give a global grade, a floor grade and a \"photogenic grade!\" Minimum grade is 1 star."),
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  void onGradeButtonPressed() async {
    UserGrades userGrades = UserGrades(
        userId: widget.userId,
        spotGrade: spotGradeInput,
        spotGradeFloor: spotGradeFloorInput,
        spotGradeBeauty: spotGradeBeautyInput);
    if (userIsRatingTheSpot &&
        spotGradeInput != null &&
        spotGradeBeautyInput != null &&
        spotGradeFloorInput != null) {
      if (indexOfUserRate != -1) {
        widget.spot.usersGrades[indexOfUserRate] = userGrades;
        await Database().updateASpot(
            context: context,
            spotId: widget.spot.markerId,
            spotGrades: widget.spot.usersGrades,
            creatorId: widget.userId);
      } else {
        widget.spot.usersGrades.add(userGrades);
        indexOfUserRate = widget.spot.usersGrades.length - 1;
        await Database().updateASpot(
            context: context,
            spotId: widget.spot.markerId,
            userGrade: userGrades,
            creatorId: widget.userId);
      }
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
      String spotGradeName, String spotGradeType, double spotGrade) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          spotGradeName,
          textAlign: TextAlign.end,
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

  Widget showSpotNameWidget() {
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
                widget.spot.name,
                style: TextStyle(color: Colors.white, fontSize: 25),
              )),
        ));
  }

  Widget showSpotPhotosWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Gallery(widget.spot.imagesDownloadUrls, height: 100),
    );
  }

  Widget showSpotDontHaveImagesMessageWidget() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Text(AppLocalizations.of(context)
            .translate("We don't have pictures of this spot yet...")));
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
