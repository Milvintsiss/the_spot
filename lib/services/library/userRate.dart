import 'package:flutter/foundation.dart';

class UserRates {
  UserRates({
    @required this.userId,
    @required this.spotRate,
    @required this.spotRateBeauty,
    @required this.spotRateFloor,
  });

  final String userId;
  final double spotRate;
  final double spotRateBeauty;
  final double spotRateFloor;


  Map<String, dynamic> toMap() {
    return {
      'UserId': userId,
      'SpotRate': spotRate,
      'SpotRateBeauty': spotRateBeauty,
      'SpotRateFloor': spotRateFloor,
    };
  }
}

UserRates mapToUserRates(Map map){
  return UserRates(
    userId: map['UserId'],
    spotRate: map['SpotRate'],
    spotRateBeauty: map['SpotRateBeauty'],
    spotRateFloor: map['SpotRateFloor']
  );
}



List<Map> ConvertUsersRatesToMap(List<UserRates> userRates) {
  List<Map> _userRates = [];
  userRates.forEach((UserRates userRate) {
    Map step = userRate.toMap();
    _userRates.add(step);
  });
  return _userRates;
}

List<UserRates> ConvertMapToUsersRates(List<Map> mapsOfUsersRates){
  List<UserRates> usersRates = [];
  mapsOfUsersRates.forEach((Map mapOfUserRates) {
    UserRates userRates = mapToUserRates(mapOfUserRates);
    usersRates.add(userRates);
  });
  return usersRates;
}