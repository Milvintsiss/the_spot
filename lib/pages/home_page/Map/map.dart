import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:the_spot/pages/home_page/Map/createUpdateSpot_page.dart';
import 'package:the_spot/pages/home_page/Map/spotInfo.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/services/library/map_helper.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:the_spot/services/library/search_engine.dart';

import '../../../theme.dart';

class Map extends StatefulWidget {
  const Map({Key key, this.userId, this.context}) : super(key: key);

  final String userId;
  final BuildContext context;

  @override
  _Map createState() => _Map();
}

class _Map extends State<Map> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final Completer<GoogleMapController> _mapControllerCompleter = Completer();

  GoogleMapController _mapController;

  Location location = Location();
  LocationData _locationData;
  LatLng userLocation;
  List<LatLng> usersLocations = [];

  bool waitUserShowLocation = false;

  double screenWidth;
  double screenHeight;

  String matchName;

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

  /// Color of the cluster circle
  final Color _clusterColor = Colors.blue;

  /// Color of the cluster text
  final Color _clusterTextColor = Colors.white;

  List<MapMarker> spots = List();

  final List<MapMarker> markers = [];

  /// Called when the Google Map widget is created. Updates the map loading state
  /// and inits the markers.
  void _onMapCreated(GoogleMapController controller) async {
    _mapControllerCompleter.complete(controller);

    _mapController = controller;

    setState(() {
      _isMapLoading = false;
    });

    _initMarkers();
  }

  /// Inits [Fluster] and all the markers with network images and updates the loading state.
  void _initMarkers() async {

    spots = await searchSpots(context, matchName: matchName);

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
      _mapController
          .animateCamera(CameraUpdate.newLatLngZoom(userLocation, 18));
    }

    final StorageReference storageReference =
        FirebaseStorage().ref().child("ProfilePictures/" + widget.userId);
    String avatarDownloadPath = await storageReference.getDownloadURL();
    final File _avatar =
        await DefaultCacheManager().getSingleFile(avatarDownloadPath);
    Uint8List __avatar = await _avatar.readAsBytes();
    BitmapDescriptor avatar = BitmapDescriptor.fromBytes(__avatar);

    setState(() {
      _markers.add(Marker(
          markerId: MarkerId("UserPosition"),
          position: userLocation,
          icon: avatar));
    });

    Database().updateUserLocation(
        context: context, userId: widget.userId, userLocation: userLocation);
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      key: _scaffoldKey,
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
              onTap: (tapLocation) {
                if (waitUserShowLocation)
                  showDialogConfirmCreateSpot(tapLocation);
              },
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
          onTopMapUI(),
        ],
      ),
    );
  }

  Widget onTopMapUI() {
    return Positioned(
      top: 30,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          searchBarWidget(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                  color: transparentColor(PrimaryColorLight, 220),
                  borderRadius: BorderRadius.all(Radius.circular(30))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 30,
                      color: PrimaryColorDark,
                    ),
                    onPressed: _initMarkers,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.place,
                      size: 30,
                      color: PrimaryColorDark,
                    ),
                    onPressed: () => print("place button pressed"),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: PrimaryColorDark,
                    ),
                    onPressed: showDialogSpotLocation,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.map,
                      color: PrimaryColorDark,
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
                      color: PrimaryColorDark,
                    ),
                    onPressed: () => getUserLocationAndUpdate(animateCameraToLocation: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget searchBarWidget() {
    return Container(
      width: screenWidth,
      child: Center(
        child: Container(
          height: 40,
          width: screenWidth - 20,
          decoration: BoxDecoration(
              color: transparentColor(PrimaryColor, 240),
              borderRadius: BorderRadius.all(Radius.circular(30))),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () => print("filter"),
              ),
              Container(
                width: screenWidth - 160,
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (value) => matchName = value,
                  onSubmitted: (value) => _initMarkers(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () => _initMarkers(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSpotInfo(String markerId) async {
    MapMarker spot =
        spots.firstWhere((element) => element.markerId == markerId);

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
            return SpotInfoWidget(
              setStateBottomSheet: setStateBottomSheet,
              userId: widget.userId,
              screenHeight: screenHeight,
              screenWidth: screenWidth,
              spot: spot,
            );
          });
        });
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
            builder: (context) => CreateUpdateSpotPage(
                  userId: widget.userId,
                  spotId: spotId,
                  stateCallback: createSpotCallBack,
                )));
  }
}
