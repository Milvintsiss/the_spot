import 'package:flutter/material.dart';
import 'package:the_spot/app_localizations.dart';

class FeatureNotAvailable extends StatefulWidget {
  @override
  _FeatureNotAvailableState createState() => _FeatureNotAvailableState();
}

class _FeatureNotAvailableState extends State<FeatureNotAvailable>
    with SingleTickerProviderStateMixin {
  Animation iconAnimation;
  AnimationController animationController;
  bool mReverse = false;

  @override
  void initState() {
    super.initState();
    animationController =
        new AnimationController(vsync: this, duration: Duration(seconds: 1));
    iconAnimation =
        Tween<double>(begin: 0, end: 0.4).animate(animationController);
    animationController.repeat(reverse: true,);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red[400],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedIcon(
            icon: AnimatedIcons.event_add,
            progress: iconAnimation,
            size: 150,
          ),
          Text(
            AppLocalizations.of(context).translate("This feature isn't available yet, please wait for the next update"),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 30, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
