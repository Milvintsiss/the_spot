import 'package:flutter/cupertino.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/mapmarker.dart';

Future<List<MapMarker>> searchSpots(BuildContext context, {String matchName}) async {
  List<MapMarker> spots = [];
  if(matchName != null && matchName != ""){
    spots = await Database().getSpots(context, matchName: matchName);
  }else{
    spots = await Database().getSpots(context);
  }

  return spots;
}