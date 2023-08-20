// ignore_for_file: use_build_context_synchronously

import 'package:diarme/src/ui/loading.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth.dart';
import '../providers/shared_prefs.dart';
import '../ui/app_title.dart';
import '../ui/pen_icon_text.dart';
import 'home.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailFieldController = TextEditingController();
  final _passwordFieldController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  String validationError = "";
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(15.0, 25.0, 0.0, 0.0),
                    child: const AppTitle(),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(200.0, 130.0, 0.0, 0.0),
                    child: const PenIconText(),
                  ),
                ],
              ),
              Container(
                  padding:
                      const EdgeInsets.only(top: 15.0, left: 20.0, right: 20.0),
                  child: Column(
                    children: <Widget>[
                      _emailField(context),
                      const SizedBox(height: 20.0),
                      _passwordField(),
                      const SizedBox(height: 40.0),
                      SizedBox(
                        height: 40.0,
                        child: InkWell(
                          onTap: login,
                          child: Material(
                            borderRadius: BorderRadius.circular(20.0),
                            shadowColor: Colors.white70,
                            color: Theme.of(context).colorScheme.secondary,
                            elevation: 7.0,
                            child: Center(
                              child: loading
                                  ? Loading()
                                  : Text(
                                      'LOGIN',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat'),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 15.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New to Diarme?',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  const SizedBox(width: 5.0),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => Scaffold(body: SignupScreen()),
                      ));
                    },
                    child: Text(
                      'Register',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.8),
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    ));
  }

  void toggleLoadingState() {
    setState(() {
      loading = !loading;
    });
  }

  void login() async {
    if (_formKey.currentState?.validate() == false) {
      Fluttertoast.showToast(msg: "Please fill-in the form correctly");
      return;
    }
    toggleLoadingState();

    var response = await AuthenticationProvider.login(
        email: _emailFieldController.text,
        password: _passwordFieldController.text);

    toggleLoadingState();

    bool loginSuccess = response['success'];

    if (loginSuccess) {
      Provider.of<SharedPrefsProvider>(context, listen: false).userToken =
          response['token'];
      Provider.of<SharedPrefsProvider>(context, listen: false).userId =
          response['user']['_id'];

      _saveUserData(response['user']);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen('/all')),
      );

      Fluttertoast.showToast(msg: "Logged in successfully");
    } else {
      if (response['error'] != null) {
        validationError = response['error'];
        _formKey.currentState?.validate();
        validationError = '';
      } else {
        Fluttertoast.showToast(
            msg: "Something wrong happened, please try again");
      }
    }
  }

  TextFormField _passwordField() {
    return TextFormField(
      controller: _passwordFieldController,
      focusNode: _passwordFocus,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
          labelText: 'PASSWORD',
          labelStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          ))),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  TextFormField _emailField(BuildContext context) {
    return TextFormField(
      focusNode: _emailFocus,
      controller: _emailFieldController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      onFieldSubmitted: (term) {
        _emailFocus.unfocus();
        FocusScope.of(context).requestFocus(_passwordFocus);
      },
      decoration: InputDecoration(
          labelText: 'EMAIL',
          labelStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          ))),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your email';
        return null;
      },
    );
  }

  _saveUserData(Map<String, dynamic> userJson) async {
    User user = User.fromJson(userJson);
    var db = UserDBProvider();
    await db.open();
    await db.insert(user);
    await db.close();
  }
}
