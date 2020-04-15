
import 'package:flutter/material.dart';

Color transparentColor(Color color, int alpha){
  return Color.fromARGB(alpha, color.red, color.green, color.blue);
}