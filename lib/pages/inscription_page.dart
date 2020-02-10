import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/pages/main.dart';
import 'package:the_spot/theme.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({Key key}) : super(key: key);

  @override
  _InscriptionPage createState() => _InscriptionPage();
}

class _InscriptionPage extends State<InscriptionPage> {
  String _pseudo;
  bool _BMX = false;
  bool _Skateboard = false;
  bool _Scooter = false;
  bool _Roller = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: PrimaryColorDark,
            body: ListView(
              padding: EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 0.0),
              children: <Widget>[
                showAvatarWidget(),
                showPseudoInput(),
                showPracticesButtons(),
                showNextButton(),
              ],
            )));
  }

  Widget showAvatarWidget() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
        child: GestureDetector(
          onTap: () => print("add an Avatar"),
          child: CircleAvatar(
            backgroundColor: PrimaryColorLight,
            radius: 80,
            foregroundColor: PrimaryColorDark,
            child: Stack(
              overflow: Overflow.visible,
                children: <Widget>[
              Icon(
                Icons.person,
                size: 100,
              ),
              Positioned(
                bottom: -40,
                  right: -40,
                  child: Icon(
                    Icons.add_circle,
                    size: 60,
                    color: SecondaryColor,
                  )
              ),
            ]),
          ),
        ));
  }

  Widget showPseudoInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
      child: new TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: 1,
        autofocus: false,
        decoration: new InputDecoration(
          hintText: AppLocalizations.of(context).translate('Username'),
          hintStyle: TextStyle(color: Colors.blueGrey[100]),
          fillColor: PrimaryColorLight,
          filled: true,
          contentPadding: new EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          border: new OutlineInputBorder(
            borderRadius: new BorderRadius.circular(12.0),
          ),
        ),
        validator: (value) => value.isEmpty
            ? AppLocalizations.of(context).translate('Pseudo can\'t be empty')
            : null,
        onSaved: (value) => _pseudo = value.trim(),
      ),
    );
  }

  Widget showPracticesButtons() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(20.0),
        ),
        color: PrimaryColorLight,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                  color: PrimaryColorDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        AppLocalizations.of(context)
                            .translate('Select your hobby(ies)'),
                        style: TextStyle(
                            color: PrimaryColorLight, fontSize: 17.5)),
                  )),
            ),
            Container(
              height: 90,
              child: new ListView(
                shrinkWrap: false,
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      practiceButton("assets/images/BMX.png"),
                      practiceButton("assets/images/Skateboard.png"),
                      practiceButton("assets/images/Scooter.png"),
                      practiceButton("assets/images/Roller.png")
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget practiceButton(String practice) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: () => onTapPractices(practice),
        child: Material(
          // needed
          shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(14.0),
              side: BorderSide(
                  width: 3,
                  color: practice == "assets/images/Roller.png" && _Roller ||
                          practice == "assets/images/BMX.png" && _BMX ||
                          practice == "assets/images/Skateboard.png" &&
                              _Skateboard ||
                          practice == "assets/images/Scooter.png" && _Scooter
                      ? Colors.white
                      : PrimaryColorDark)),
          color: PrimaryColor,

          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
              practice,
              width: 45,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  void onTapPractices(String practice) {
    switch (practice) {
      case "assets/images/Roller.png":
        _Roller = !_Roller;
        break;
      case "assets/images/BMX.png":
        _BMX = !_BMX;
        break;
      case "assets/images/Skateboard.png":
        _Skateboard = !_Skateboard;
        break;
      case "assets/images/Scooter.png":
        _Scooter = !_Scooter;
        break;
    }
    setState(() {
      practiceButton(practice);
    });
  }

  Widget showNextButton() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 20.0),
      child: SizedBox(
        height: 40.0,
        child: new RaisedButton(
          elevation: 5.0,
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0)),
          color: SecondaryColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Text(
                AppLocalizations.of(context).translate('Next'),
                style: new TextStyle(fontSize: 15.0, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              )
            ],
          ),
          onPressed: () => print("next"),
        ),
      ),
    );
  }
}
