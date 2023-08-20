// ignore_for_file: use_build_context_synchronously

import 'package:diarme/src/ui/loading.dart';
import 'package:diarme/src/ui/pen_icon_text.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth.dart';
import '../providers/shared_prefs.dart';
import '../ui/app_title.dart';
import 'login.dart';
import 'home.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailFieldController = TextEditingController();
  final _usernameFieldController = TextEditingController();
  final _passwordFieldController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  String validationError = "";
  bool loading = false;

  late BuildContext scaffoldContext;

  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    return Scaffold(
        body: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(),
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
                  )
                ],
              ),
              Container(
                  padding:
                      const EdgeInsets.only(top: 15.0, left: 20.0, right: 20.0),
                  child: Column(
                    children: [
                      _emailField(context),
                      const SizedBox(height: 20.0),
                      _usernameField(context),
                      const SizedBox(height: 20.0),
                      _password(),
                      const SizedBox(height: 40.0),
                      SizedBox(
                        height: 40.0,
                        child: InkWell(
                          onTap: signup,
                          child: Material(
                            borderRadius: BorderRadius.circular(20.0),
                            shadowColor: Colors.white70,
                            color: Theme.of(context).colorScheme.secondary,
                            elevation: 7.0,
                            child: Center(
                              child: loading
                                  ? Loading()
                                  : Text(
                                      'SIGNUP',
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
                    'Already on Diarme?',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  const SizedBox(width: 5.0),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            const Scaffold(body: LoginScreen()),
                      ));
                    },
                    child: Text(
                      'Login',
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

  void signup() async {
    if (_formKey.currentState?.validate() == false) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return null;
    }

    toggleLoadingState();

    var response = await AuthenticationProvider.register(
        username: _usernameFieldController.text,
        email: _emailFieldController.text,
        password: _passwordFieldController.text);

    toggleLoadingState();

    bool signupSuccess = response['success'];

    if (signupSuccess) {
      Provider.of<SharedPrefsProvider>(context, listen: false).userToken =
          response['token'];
      Provider.of<SharedPrefsProvider>(context, listen: false).userId =
          response['user']['_id'];
      _saveUserData(response['user']);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen('/all')),
      );
      Fluttertoast.showToast(msg: "Signed up in successfully");
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

  TextFormField _password() {
    return TextFormField(
      controller: _passwordFieldController,
      focusNode: _passwordFocus,
      textInputAction: TextInputAction.done,
      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      decoration: InputDecoration(
          labelText: 'PASSWORD',
          labelStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withOpacity(0.7)))),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  TextFormField _usernameField(BuildContext context) {
    return TextFormField(
      focusNode: _usernameFocus,
      controller: _usernameFieldController,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      onFieldSubmitted: (term) {
        _usernameFocus.unfocus();
        FocusScope.of(context).requestFocus(_passwordFocus);
      },
      decoration: InputDecoration(
          labelText: 'USERNAME',
          labelStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withOpacity(0.7)))),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your username';
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
        FocusScope.of(context).requestFocus(_usernameFocus);
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
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
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
