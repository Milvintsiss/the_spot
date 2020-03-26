import 'package:flutter/material.dart';
import 'package:the_spot/services/authentication.dart';

import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/theme.dart';
import 'package:vibrate/vibrate.dart';

class LoginSignupPage extends StatefulWidget {
  LoginSignupPage({this.auth, this.loginCallBack});

  final BaseAuth auth;
  final VoidCallback loginCallBack;

  @override
  State<StatefulWidget> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

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
    Vibrate.feedback(FeedbackType.warning);
    return false;
  }

  //Perform login or signup
  void validateAndSubmit() async {
    if (validateAndSave()) {
      String userId = "";
      setState(() {
        _errorMessage = "";
        _isLoading = true;
      });
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

        if (userId.length > 0 && userId != null) {
          widget.loginCallBack();
        } else {
          Vibrate.feedback(FeedbackType.warning);
          setState(() {
            _errorMessage = "Error";
          });
        }
      } catch (e) {
        print('Error: $e');
        Vibrate.feedback(FeedbackType.warning);
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
    return Scaffold(
        backgroundColor: PrimaryColorDark,
        body: Stack(
          children: <Widget>[
            showForm(),
            showCircularProgress(),
          ],
        ));
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
    return Container(
      child: Form(
        key: _formKey,
        child: ListView(
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
    return Hero(
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
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        focusNode: _emailFocus,
        onFieldSubmitted: (term) {
          _emailFocus.unfocus();
          FocusScope.of(context).requestFocus(_passwordFocus);
        },
        autofocus: false,
        decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: TextStyle(color: Colors.blueGrey[100]),
            fillColor: SecondaryColorDark,
            filled: true,
            contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            icon: Icon(
              Icons.mail,
              color: Colors.blueGrey[100],
            )),
        validator: (value) =>
        value.isEmpty
            ? AppLocalizations.of(context).translate('Email can t be empty')
            : null,
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 15.0, 16.0, 0.0),
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        focusNode: _passwordFocus,
        decoration: InputDecoration(
            hintText: AppLocalizations.of(context).translate('Password'),
            hintStyle: TextStyle(color: Colors.blueGrey[100]),
            fillColor: SecondaryColorDark,
            filled: true,
            contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            icon: Icon(
              Icons.lock,
              color: Colors.blueGrey[100],
            )),
        validator: (value) =>
        value.isEmpty
            ? AppLocalizations.of(context).translate('Password can t be empty')
            : null,
        onSaved: (value) => _password = value.trim(),
      ),
    );
  }

  Widget showPrimaryButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.0, 45.0, 16.0, 0.0),
      child: SizedBox(
        height: 40.0,
        child: RaisedButton(
          elevation: 5.0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0)),
          color: SecondaryColorDark,
          child: Text(
            _isLoginForm
                ? AppLocalizations.of(context).translate('Login')
                : AppLocalizations.of(context).translate('Create account'),
            style: TextStyle(fontSize: 20.0, color: Colors.white),
          ),
          onPressed: () => validateAndSubmit(),
        ),
      ),
    );
  }

  Widget showSecondaryButton() {
    return FlatButton(
      child: Text(
        _isLoginForm
            ? AppLocalizations.of(context).translate('Create an account')
            : AppLocalizations.of(context)
            .translate('Have an account? Sign in'),
        style: TextStyle(
            fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      onPressed: toggleFormMode,
    );
  }

  Widget showErrorMessage() {
    if (_errorMessage != null) {
      return Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return Container(
        height: 0.0,
      );
    }
  }
}
