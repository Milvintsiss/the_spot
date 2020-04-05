import 'package:flutter/foundation.dart';

class UserGrades {
  UserGrades({
    @required this.userId,
    @required this.spotGrade,
    @required this.spotGradeBeauty,
    @required this.spotGradeFloor,
  });

  final String userId;
  final double spotGrade;
  final double spotGradeBeauty;
  final double spotGradeFloor;


  Map<String, dynamic> toMap() {
    return {
      'UserId': userId,
      'SpotGrade': spotGrade,
      'SpotGradeBeauty': spotGradeBeauty,
      'SpotGradeFloor': spotGradeFloor,
    };
  }
}

UserGrades mapToUserGrades(Map map){
  return UserGrades(
    userId: map['UserId'],
    spotGrade: map['SpotGrade'],
    spotGradeBeauty: map['SpotGradeBeauty'],
    spotGradeFloor: map['SpotGradeFloor']
  );
}



List<Map> ConvertUsersGradesToMap(List<UserGrades> userGrades) {
  List<Map> _userGrades = [];
  userGrades.forEach((UserGrades userGrade) {
    Map step = userGrade.toMap();
    _userGrades.add(step);
  });
  return _userGrades;
}

List<UserGrades> ConvertMapToUsersGrades(List<Map> mapsOfUsersGrades){
  List<UserGrades> usersGrades = [];
  mapsOfUsersGrades.forEach((Map mapOfUserGrades) {
    UserGrades userGrades = mapToUserGrades(mapOfUserGrades);
    usersGrades.add(userGrades);
  });
  return usersGrades;
}