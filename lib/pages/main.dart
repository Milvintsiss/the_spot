import 'package:flutter/material.dart';
import 'package:the_spot/services/authentication.dart';
import 'package:the_spot/pages/root_page.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'The Spot',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: new RootPage(auth: new Auth()),
        debugShowCheckedModeBanner: false,
    );
  }
}