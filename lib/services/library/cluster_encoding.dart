import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CLusterEncoding {
  String getClusterIdForLocation(LatLng location) {
    String topLeft =
        roundPrecision(location.latitude, fractionDigits: 2).toString();
    return topLeft;
  }
}

double roundPrecision(double toRound,
    {@required int fractionDigits, bool toSuperior = true}) {
  double result;
  print(toRound.toString());
  if(toSuperior){
    result = double.parse(toRound.toString().substring(0, toRound.toString().length - fractionDigits));
  }
  return result;
}
