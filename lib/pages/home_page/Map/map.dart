import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:the_spot/pages/home_page/Map/createUpdateSpot_page.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/gallery.dart';
import 'package:the_spot/services/library/map_helper.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:the_spot/services/library/userGrade.dart';

import '../../../theme.dart';

class Map extends StatefulWidget {
  const Map({Key key, this.userId, this.context}) : super(key: key);

  final String userId;
  final BuildContext context;

  @override
  _Map createState() => _Map();
}

class _Map extends State<Map> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();

  GoogleMapController _mapController;

  Location location = Location();
  LocationData _locationData;
  LatLng userLocation;
  List<LatLng> usersLocations = [];

  bool waitUserShowLocation = false;

  double screenWidth;
  double screenHeight;

  bool userIsRatingTheSpot = false;
  bool spotHasGrades = true;
  bool userRatingNotComplete = false;
  double spotGrade;
  double spotGradeBeauty;
  double spotGradeFloor;
  double spotGradeInput;
  double spotGradeBeautyInput;
  double spotGradeFloorInput;

  /// Set of displayed markers and cluster markers on the map
  final Set<Marker> _markers = Set();

  /// Minimum zoom at which the markers will cluster
  final int _minClusterZoom = 0;

  /// Maximum zoom at which the markers will cluster
  final int _maxClusterZoom = 19;

  /// [Fluster] instance used to manage the clusters
  Fluster<MapMarker> _clusterManager;

  ///Map type, true = normal  /  false = hybrid
  bool _mapType = false;

  /// Current map zoom. Initial zoom will be 15, street level
  double _currentZoom = 15;

  /// Map loading flag
  bool _isMapLoading = true;

  /// Markers loading flag
  bool _areMarkersLoading = true;

  /// Url image used on normal markers
  final String _markerImageUrl =
      'https://img.icons8.com/office/80/000000/marker.png';

  /// Color of the cluster circle
  final Color _clusterColor = Colors.blue;

  /// Color of the cluster text
  final Color _clusterTextColor = Colors.white;

  List<MapMarker> spots = List();

  final List<MapMarker> markers = [];

  /// Called when the Google Map widget is created. Updates the map loading state
  /// and inits the markers.
  void _onMapCreated(GoogleMapController controller) {
    _mapControllerCompleter.complete(controller);

    _mapController = controller;

    setState(() {
      _isMapLoading = false;
    });

    _initMarkers();
  }

  /// Inits [Fluster] and all the markers with network images and updates the loading state.
  void _initMarkers() async {
    spots = await Database().getSpots(context);

    markers.clear();

    if (spots != null) {
      spots.forEach((spot) {
        markers.add(spot);
      });
    }

    _clusterManager = await MapHelper.initClusterManager(
      markers,
      _minClusterZoom,
      _maxClusterZoom,
    );

    await _updateMarkers();
  }

  /// Gets the markers and clusters to be displayed on the map for the current zoom level and
  /// updates state.
  Future<void> _updateMarkers([double updatedZoom]) async {
    if (_clusterManager == null || updatedZoom == _currentZoom) return;

    if (updatedZoom != null) {
      _currentZoom = updatedZoom;
    }

    setState(() {
      _areMarkersLoading = true;
    });

    final updatedMarkers = await MapHelper.getClusterMarkers(
      _clusterManager,
      _currentZoom,
      _clusterColor,
      _clusterTextColor,
      80,
    );

    List<Marker> __markers = List();
    __markers.addAll(updatedMarkers);
    _markers.clear();

    __markers.forEach((marker) {
      _markers.add(Marker(
          markerId: marker.markerId,
          position: marker.position,
          icon: marker.icon,
          onTap: () => showSpotInfo(marker.markerId.value)));
    });

    setState(() {
      _areMarkersLoading = false;
    });
  }

  void getUserLocationAndUpdate({bool animateCameraToLocation = false}) async {
    _locationData = await location.getLocation();
    userLocation = LatLng(_locationData.latitude, _locationData.longitude);
    if (animateCameraToLocation == true) {
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 18));
    }

    final StorageReference storageReference =
    FirebaseStorage().ref().child("ProfilePictures/" + widget.userId);
    String avatarDownloadPath = await storageReference.getDownloadURL();
    final File _avatar = await DefaultCacheManager().getSingleFile(avatarDownloadPath);
    Uint8List __avatar = await _avatar.readAsBytes();
    BitmapDescriptor avatar = BitmapDescriptor.fromBytes(__avatar);

    setState(() {
      _markers.add(Marker(markerId: MarkerId("UserPosition"), position: userLocation, icon: avatar ));
    });

    Database().updateUserLocation(context: context, userId: widget.userId, userLocation: userLocation);

  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Google Map widget
          Opacity(
            opacity: _isMapLoading ? 0 : 1,
            child: GoogleMap(
              compassEnabled: true,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapType: _mapType ? MapType.normal : MapType.hybrid,
              indoorViewEnabled: false,
              initialCameraPosition: CameraPosition(
                target: LatLng(41.143029, -8.611274),
                zoom: _currentZoom,
              ),
              markers: _markers,
              onMapCreated: (controller) => _onMapCreated(controller),
              onCameraMove: (position) => _updateMarkers(position.zoom),
              onTap: (tapLocation){if(waitUserShowLocation) showDialogConfirmCreateSpot(tapLocation);},
              onLongPress: showDialogConfirmCreateSpot,
            ),
          ),

          // Map loading indicator
          Opacity(
            opacity: _isMapLoading ? 1 : 0,
            child: Center(child: CircularProgressIndicator()),
          ),

          // Map markers loading indicator
          _areMarkersLoading
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Card(
                elevation: 2,
                color: PrimaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          )
              : Padding(
            padding: EdgeInsets.all(0.0),
          ),
          Positioned(
            top: 25,
            right: 0,
            child: Column(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 30,
                    color: SecondaryColorDark,
                  ),
                  onPressed: _initMarkers,
                ),
                IconButton(
                  icon: Icon(
                    Icons.place,
                    size: 30,
                    color: SecondaryColorDark,
                  ),
                  onPressed: () => print("place button pressed"),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: SecondaryColorDark,
                  ),
                  onPressed: showDialogSpotLocation,
                ),
                IconButton(
                  icon: Icon(
                    Icons.map,
                    color: SecondaryColorDark,
                  ),
                  onPressed: () {
                    setState(() {
                      _mapType = !_mapType;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.my_location,
                    size: 30,
                    color: SecondaryColorDark,
                  ),
                  onPressed: () => getUserLocationAndUpdate(animateCameraToLocation: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showSpotInfo(String markerId) async {
    spotGradeInput = null;
    spotGradeBeautyInput = null;
    spotGradeFloorInput = null;
    userIsRatingTheSpot = false;
    userRatingNotComplete = false;

    MapMarker spot =
    spots.firstWhere((element) => element.markerId == markerId);
    print("SpotId: " + markerId);
    print("SpotName: " + spot.name);
    print(spot.imagesDownloadUrls);

    bool _isSpotHasImages;
    if (spot.imagesDownloadUrls == null || spot.imagesDownloadUrls.length == 0)
      _isSpotHasImages = false;
    else
      _isSpotHasImages = true;

    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            )),
        backgroundColor: PrimaryColorDark,
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateBottomSheet) {
                return Container(
                  height: screenHeight * 4 / 9,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    children: <Widget>[
                      _isSpotHasImages
                          ? showSpotPhotosWidget(spot.imagesDownloadUrls)
                          : Container(),
                      showSpotNameWidget(spot.name),
                      showSpotGradesWidget(
                          spot.usersGrades, setStateBottomSheet, spot.markerId),
                      showSpotDescriptionWidget(spot.description),
                    ],
                  ),
                );
              });
        });
  }

  Widget showSpotGradesWidget(List<UserGrades> usersGrades,
      StateSetter setStateBottomSheet, String spotId) {
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
      spotGradeFloor =
          listSpotGradeFloor.reduce((a, b) => a + b) / listSpotGradeFloor.length;
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
                    Text("This spot was rated " + usersGrades.length.toString() + " times!",
                    style: TextStyle(color: PrimaryColorDark, fontStyle: FontStyle.italic),),
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
                  onPressed: () =>
                      onGradeButtonPressed(setStateBottomSheet, spotId),
                ),
                userIsRatingTheSpot
                    ? SizedBox(
                  width: 50,
                  child: RaisedButton(
                    child: Icon(
                      Icons.undo,
                      size: 20,
                    ),
                    onPressed: () =>
                        setStateBottomSheet(() {
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

  void onGradeButtonPressed(StateSetter setStateBottomSheet,
      String spotId) async {
    UserGrades userGrades = UserGrades(
        userId: widget.userId,
        spotGrade: spotGradeInput,
        spotGradeFloor: spotGradeFloorInput,
        spotGradeBeauty: spotGradeBeautyInput);
    if (userIsRatingTheSpot &&
        spotGradeInput != null &&
        spotGradeBeautyInput != null &&
        spotGradeFloorInput != null) {
      await Database()
          .updateASpot(context: context,
          spotId: spotId,
          userGrade: userGrades,
          creatorId: widget.userId);

      spotGradeInput = null;
      spotGradeBeautyInput = null;
      spotGradeFloorInput = null;
      userRatingNotComplete = false;

      setStateBottomSheet(() {
        spots
            .firstWhere((element) => element.markerId == spotId)
            .usersGrades
            .add(userGrades);
        userIsRatingTheSpot = !userIsRatingTheSpot;
      });
    } else if (userIsRatingTheSpot) {
      setStateBottomSheet(() {
        userRatingNotComplete = true;
      });
    } else {
      setStateBottomSheet(() {
        userIsRatingTheSpot = !userIsRatingTheSpot;
      });
    }
  }

  Widget showSpotGradeWidget(String spotGradeName,
      double spotGrade,) {
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
        )
            : RatingBarIndicator(
          rating: spotGrade,
          itemSize: 20,
          unratedColor: PrimaryColor,
          itemBuilder: (context, _) =>
              Icon(
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

  void showDialogSpotLocation() {
    showDialog(
        context: context,
        child: AlertDialog(
          content: Text(
              "Please show us the location of your spot by a click on it on the map"),
          actions: <Widget>[
            FlatButton(
              child: Text("Ok"),
              onPressed: () {
                Navigator.pop(context);
                waitUserShowLocation = true;
              },
            )
          ],
        ));
  }

  void showDialogConfirmCreateSpot(LatLng spotLocation) {
    waitUserShowLocation = false;
    _mapController
        .animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(spotLocation.latitude - 0.0001, spotLocation.longitude), 20))
        .whenComplete(() {
      Future.delayed(Duration(seconds: 2)).whenComplete(() {
        setState(() {
          _markers.add(Marker(
              markerId: MarkerId(spotLocation.toString()),
              position: spotLocation));
          _mapType = false;
        });
      });
    });

    showDialog(
        context: context,
        child: AlertDialog(
          content: Text("Create a spot at this place?"),
          actions: <Widget>[
            FlatButton(
              child: Text("Yes"),
              onPressed: () {
                setState(() {
                  _markers.remove(Marker(
                      markerId: MarkerId(spotLocation.toString()),
                      position: spotLocation));
                });
                Navigator.pop(context);
                createSpot(spotLocation);
              },
            ),
            FlatButton(
                child: Text("No"),
                onPressed: () {
                  setState(() {
                    _markers.remove(Marker(
                        markerId: MarkerId(spotLocation.toString()),
                        position: spotLocation));
                  });
                  Navigator.pop(context);
                })
          ],
        ));
  }

  void createSpotCallBack() {
    _initMarkers();
  }

  void createSpot(LatLng tapPosition) async {
    String spotId = await Database().updateASpot(
        context: context,
        spotId: null,
        spotLocation: tapPosition,
        creatorId: widget.userId,
        onCreate: true);

    Navigator.push(
        widget.context,
        MaterialPageRoute(
            builder: (context) =>
                CreateUpdateSpotPage(
                  userId: widget.userId,
                  spotId: spotId,
                  stateCallback: createSpotCallBack,
                )));
  }
}
