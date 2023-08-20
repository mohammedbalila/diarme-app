import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';
import '../providers/shared_prefs.dart';
import '../models/user.dart';

class AccountScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  String emailValidationError = '';
  late User? _user;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getUserData().then((user) {
      setState(() {
        _user = user;
        _usernameController.text = _user!.username;
        _emailController.text = _user!.email;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Account Info'),
          leading: BackButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, "settings");
            },
          ),
        ),
        body: ListView(children: <Widget>[
          Container(
              padding: EdgeInsets.only(top: 35.0, left: 20.0, right: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _emailField(context),
                    SizedBox(height: 10.0),
                    _usernameField(),
                    SizedBox(height: 50.0),
                    Container(
                      height: 40.0,
                      child: InkWell(
                        onTap: _handleFormSubmission,
                        child: Material(
                          borderRadius: BorderRadius.circular(20.0),
                          shadowColor: Colors.white70,
                          color: Theme.of(context).colorScheme.secondary,
                          elevation: 7.0,
                          child: Center(
                            child: isLoading ? _loading() : _saveText(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ]));
  }

  Text _saveText(BuildContext context) {
    return Text(
      'Save',
      style: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat'),
    );
  }

  Padding _loading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
    );
  }

  TextFormField _usernameField() {
    return TextFormField(
      controller: _usernameController,
      // focusNode: _usernameFocus,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      decoration: InputDecoration(
          labelText: 'Username ',
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
        if (value == null || value.isEmpty) return 'Please enter your username';
        return null;
      },
    );
  }

  TextFormField _emailField(BuildContext context) {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          ))),
      onFieldSubmitted: (_) {
        _emailFocus.unfocus();
        FocusScope.of(context).requestFocus(_usernameFocus);
      },
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your email';
        return null;
      },
    );
  }

  Future _handleFormSubmission() async {
    toggleLoadingState();
    if (_formKey.currentState!.validate()) {
      _user!.username = _usernameController.text;
      _user!.email = _emailController.text;
      String token =
          Provider.of<SharedPrefsProvider>(context, listen: false).userToken;
      var response =
          await AuthenticationProvider.updateUserData(_user!.toMap(), token);
      if (response['success']) {
        await _saveUserData(response['user']);
        Fluttertoast.showToast(msg: "User data updated successfully");
      } else {
        if (response['errors'] != null) {
          emailValidationError = response['errors'];
          _formKey.currentState!.validate();
          emailValidationError = '';
        } else {
          Fluttertoast.showToast(
              msg: "Something wrong happened, please try again");
        }
      }
    }

    toggleLoadingState();
  }

  void toggleLoadingState() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  Future<User?> _getUserData() async {
    var db = UserDBProvider();
    await db.open();
    User? user = await db.getUser();
    await db.close();
    return user;
  }

  Future _saveUserData(Map<String, dynamic> user) async {
    var db = UserDBProvider();
    await db.open();
    await db.update(user);
    await db.close();
  }
}
