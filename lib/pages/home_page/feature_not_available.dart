import 'package:flutter/material.dart';

class FeatureNotAvailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Center(
        child: Text("This feature isn't available for the moment, please wait for the next update"),
      ),
    );
  }
}