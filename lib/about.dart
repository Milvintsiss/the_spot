

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void aboutDialog (BuildContext context){
  showAboutDialog(
    context: context,
    applicationIcon: SizedBox(
        height: 50,
        width: 50,
        child: Image.asset('assets/logos/Logo_TheSpot_blackWhite_whitoutText.png')),
    children: [
      GestureDetector(
        onTap: () => launch('http://thespot.social',),
        child: Text("http://thespot.social", style: TextStyle(color: Colors.blue),),
      )
    ],
  );
}