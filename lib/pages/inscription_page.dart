import 'package:flutter/material.dart';

import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/theme.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({Key key}) : super(key: key);

  @override
  _InscriptionPage createState() => _InscriptionPage();
}

class _InscriptionPage extends State<InscriptionPage> {
  String _pseudo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: PrimaryColorDark,
            body:


          Padding(
              padding: EdgeInsets.fromLTRB(40.0, 0.0, 40.0, 0.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  showPseudoInput(),
                  showPrimaryButton(),
                ],
              ),
            )));
  }

  Widget showPseudoInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
      child: new TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: 1,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: AppLocalizations.of(context).translate('Username'),
            hintStyle: TextStyle(color: Colors.blueGrey[100]),
            fillColor: SecondaryColorDark,
            filled: true,
            contentPadding: new EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
            border: new OutlineInputBorder(
              borderRadius: new BorderRadius.circular(12.0),
            ),
            ),
        validator: (value) => value.isEmpty ? AppLocalizations.of(context).translate('Pseudo can\'t be empty') : null,
        onSaved: (value) => _pseudo = value.trim(),
      ),
    );
  }

  Widget showPrimaryButton() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
      child: SizedBox(
        height: 40.0,
        child: new RaisedButton(
          elevation: 5.0,
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0)),
          color: SecondaryColorDark,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Text(AppLocalizations.of(context).translate('Next'),
                style: new TextStyle(fontSize: 15.0, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 20,),
              )
            ],
          ),
          onPressed: () => 'next',
        ),
      ),
    );
  }
}
