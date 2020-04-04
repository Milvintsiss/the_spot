import 'dart:async';
import 'dart:ui';

import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_spot/pages/home_page/Map/createUpdateSpot_page.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/gallery.dart';
import 'package:the_spot/services/library/map_helper.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:the_spot/services/library/userRate.dart';

import '../../../theme.dart';

class Map extends StatefulWidget {
  const Map({Key key, this.userId, this.context}) : super(key: key);

  final String userId;
  final BuildContext context;

  @override
  _Map createState() => _Map();
}

class _Map extends State<Map> {
  final Completer<GoogleMapController> _mapController = Completer();

  GoogleMapController _controller;

  double screenWidth;
  double screenHeight;

  bool userIsRatingTheSpot = false;
  bool spotHasRates = true;
  bool userRatingNotComplete = false;
  double spotRate;
  double spotRateBeauty;
  double spotRateFloor;
  double spotRateInput;
  double spotRateBeautyInput;
  double spotRateFloorInput;

  /// Set of displayed markers and cluster markers on the map
  final Set<Marker> _markers = Set();

  /// Minimum zoom at which the markers will cluster
  final int _minClusterZoom = 0;

  /// Maximum zoom at which the markers will cluster
  final int _maxClusterZoom = 19;

  /// [Fluster] instance used to manage the clusters
  Fluster<MapMarker> _clusterManager;

  ///Map type, true = normal  /  false = hybrid
  bool _mapType = true;

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
    _mapController.complete(controller);

    _controller = controller;

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

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Google Map widget
          Opacity(
            opacity: _isMapLoading ? 0 : 1,
            child: GoogleMap(
              compassEnabled: true,
              mapType: _mapType ? MapType.normal : MapType.hybrid,
              initialCameraPosition: CameraPosition(
                target: LatLng(41.143029, -8.611274),
                zoom: _currentZoom,
              ),
              markers: _markers,
              onMapCreated: (controller) => _onMapCreated(controller),
              onCameraMove: (position) => _updateMarkers(position.zoom),
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
                    Icons.place,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showSpotInfo(String markerId) async {
    spotRateInput = null;
    spotRateBeautyInput = null;
    spotRateFloorInput = null;
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
                  showSpotRatesWidget(
                      spot.usersRates, setStateBottomSheet, spot.markerId),
                  showSpotDescriptionWidget(spot.description),
                ],
              ),
            );
          });
        });
  }

  Widget showSpotRatesWidget(List<UserRates> usersRates,
      StateSetter setStateBottomSheet, String spotId) {
    spotRate = 0;
    spotRateFloor = 0;
    spotRateBeauty = 0;

    if(usersRates.length > 0) {
      List<double> listSpotRate = [];
      List<double> listSpotRateBeauty = [];
      List<double> listSpotRateFloor = [];

      usersRates.forEach((element) {
        listSpotRate.add(element.spotRate);
        listSpotRateFloor.add(element.spotRateFloor);
        listSpotRateBeauty.add(element.spotRateBeauty);
      });

      spotRate = listSpotRate.reduce((a, b) => a + b) / listSpotRate.length;
      spotRateFloor =
          listSpotRateFloor.reduce((a, b) => a + b) / listSpotRateFloor.length;
      spotRateBeauty = listSpotRateBeauty.reduce((a, b) => a + b) /
          listSpotRateBeauty.length;
      print(spotRate);
      print(spotRateFloor);
      print(spotRateBeauty);
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
                    showSpotRateWidget("Spot:    ", spotRate),
                    showSpotRateWidget("Floor:   ", spotRateBeauty),
                    showSpotRateWidget("Beauty:", spotRateFloor),
                  ],
                ),
                Divider(
                  indent: 30,
                ),
                RaisedButton(
                  child:
                      Text(userIsRatingTheSpot ? "Confirm" : "Rate this spot"),
                  onPressed: () =>
                      onRateButtonPressed(setStateBottomSheet, spotId),
                )
              ],
            ),
            userRatingNotComplete
                ? Text(
                    "You must give a rate for all field! Minimum rate is 1 star.")
                : Container(),
          ],
        ),
      ),
    );
  }

  void onRateButtonPressed(
      StateSetter setStateBottomSheet, String spotId) async {
    UserRates userRates = UserRates(
        userId: widget.userId,
        spotRate: spotRateInput,
        spotRateFloor: spotRateFloorInput,
        spotRateBeauty: spotRateBeautyInput);
    if (userIsRatingTheSpot &&
        spotRateInput != null &&
        spotRateBeautyInput != null &&
        spotRateFloorInput != null) {
      await Database()
          .updateASpot(context: context, spotId: spotId, userRate: userRates);

      spotRateInput = null;
      spotRateBeautyInput = null;
      spotRateFloorInput = null;
      userRatingNotComplete = false;

      setStateBottomSheet(() {
        spots.firstWhere((element) => element.markerId == spotId).usersRates.add(userRates);
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

  Widget showSpotRateWidget(
    String spotRateName,
    double spotRate,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          spotRateName,
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
                onRatingUpdate: (newRate) {
                  switch (spotRateName) {
                    case "Spot:    ":
                      spotRateInput = newRate;
                      break;
                    case "Floor:   ":
                      spotRateFloorInput = newRate;
                      break;
                    case "Beauty:":
                      spotRateBeautyInput = newRate;
                      break;
                  }
                  print(spotRateName + newRate.toString());
                },
              )
            : RatingBarIndicator(
                rating: spotRate,
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

  void showDialogSpotLocation() {
    showDialog(
        context: context,
        child: AlertDialog(
          content: Text(
              "Please show us the location of your spot by a long click on it on the map"),
          actions: <Widget>[
            FlatButton(
              child: Text("Ok"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ));
  }

  void showDialogConfirmCreateSpot(LatLng spotLocation) {
    _controller
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
            builder: (context) => CreateUpdateSpotPage(
                  spotId,
                  stateCallback: createSpotCallBack,
                )));

//    if (spotId != null) {
//      markers.add(MapMarker(
//        id: spotId,
//        position: tapPosition,
//        icon: BitmapDescriptor.defaultMarker,
//      ));
//
//      _clusterManager = await MapHelper.initClusterManager(
//        markers,
//        _minClusterZoom,
//        _maxClusterZoom,
//      );
//      print("add a spot");
//
//
//      _updateMarkers();
//    }
  }
}
