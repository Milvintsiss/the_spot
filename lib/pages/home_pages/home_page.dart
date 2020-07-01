import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/pages/home_pages/post_widget.dart';
import 'package:the_spot/services/configuration.dart';
import 'package:the_spot/services/library/postdata.dart';
import 'package:the_spot/theme.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, @required this.configuration}) : super(key: key);
  final Configuration configuration;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar(),
      backgroundColor: PrimaryColorDark,
      body: PostWidget(
        configuration: widget.configuration,
        postData: PostData(postId: "1"),),
    );
  }

  AppBar showAppBar() {
    return AppBar(
      actions: [
        IconButton(
          icon: Icon(Icons.add_to_photos),
          tooltip: "Post",
          onPressed: () => print('publish'),
        )
      ],
    );
  }
}