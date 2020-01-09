import 'package:flutter/material.dart';
import 'package:the_spot/services/authentication.dart';

import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/theme.dart';


class LoginSignupPage extends StatefulWidget {
  LoginSignupPage({this.auth, this.loginCallBack});

  final BaseAuth auth;
  final VoidCallback loginCallBack;

  @override
  State<StatefulWidget> createState() => new _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = new GlobalKey<FormState>();

  bool _isLoading;
  bool _isLoginForm;

  String _email;
  String _password;
  String _errorMessage;

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  //Perform login or signup
  void validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      String userId = "";
      try {
        if (_isLoginForm) {
          userId = await widget.auth.signIn(_email, _password);
          print('Signed in: $userId');
        } else {
          userId = await widget.auth.signUp(_email, _password);
          //widget.auth.sendEmailVerification();
          //_showVerifyEmailSentDialog();
          print('Signed up user: $userId');
        }
        setState(() {
          _isLoading = false;
        });

        if (userId.length > 0 && userId != null && _isLoginForm) {
          widget.loginCallBack();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          _formKey.currentState.reset();
        });
      }
    }
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    _isLoginForm = true;
    super.initState();
  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  void toggleFormMode() {
    //resetForm();
    setState(() {
      _isLoginForm = !_isLoginForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: PrimaryColorDark,
        body: Stack(
          children: <Widget>[
            showForm(),
            showCircularProgress(),
          ],
        )));
  }

  Widget showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget showForm() {
    return new Container(
      child: new Form(
        key: _formKey,
        child: new ListView(
          shrinkWrap: false,
          children: <Widget>[
            showLogo(),
            showEmailInput(),
            showPasswordInput(),
            showPrimaryButton(),
            showSecondaryButton(),
            showErrorMessage(),
          ],
        ),
      ),
    );
  }

  Widget showLogo() {
    return new Hero(
        tag: 'hero',
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 36.0, 16.0, 20.0),
          child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 100.0,
              child: Image.asset(
                  'assets/logos/Logo_TheSpot_blackWhite_whitoutText.png')),
        ));
  }

  Widget showEmailInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
      child: new TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            hintStyle: TextStyle(color: Colors.blueGrey[100]),
            fillColor: SecondaryColorDark,
            filled: true,
            contentPadding: new EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
            border: new OutlineInputBorder(
              borderRadius: new BorderRadius.circular(12.0),
            ),
            icon: new Icon(
              Icons.mail,
              color: Colors.blueGrey[100],
            )),
        validator: (value) => value.isEmpty ? AppLocalizations.of(context).translate('Email can\'t be empty') : null,
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 15.0, 16.0, 0.0),
      child: new TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: AppLocalizations.of(context).translate('Password'),
            hintStyle: TextStyle(color: Colors.blueGrey[100]),
            fillColor: SecondaryColorDark,
            filled: true,
            contentPadding: new EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
            border: new OutlineInputBorder(
              borderRadius: new BorderRadius.circular(12.0),
            ),
            icon: new Icon(
              Icons.lock,
              color: Colors.blueGrey[100],
            )),
        validator: (value) => value.isEmpty ? AppLocalizations.of(context).translate('Password can\'t be empty') : null,
        onSaved: (value) => _password = value.trim(),
      ),
    );
  }

  Widget showPrimaryButton() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(16.0, 45.0, 16.0, 0.0),
      child: SizedBox(
        height: 40.0,
        child: new RaisedButton(
          elevation: 5.0,
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0)),
          color: SecondaryColorDark,
          child: new Text(
            _isLoginForm ? AppLocalizations.of(context).translate('Login') : AppLocalizations.of(context).translate('Create account'),
            style: new TextStyle(fontSize: 20.0, color: Colors.white),
          ),
          onPressed: () => validateAndSubmit(),
        ),
      ),
    );
  }

  Widget showSecondaryButton() {
    return new FlatButton(
      child: new Text(
        _isLoginForm ? AppLocalizations.of(context).translate('Create an account') : AppLocalizations.of(context).translate('Have an account? Sign in'),
        style: new TextStyle(
            fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      onPressed: toggleFormMode,
    );
  }

  Widget showErrorMessage() {
    if (_errorMessage != null) {
      return new Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }
}
