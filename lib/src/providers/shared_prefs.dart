import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsProvider with ChangeNotifier {
  late bool _firstRun;
  late String _userToken;
  late String _userId;
  bool _isDarkMode = false;
  bool _saveToWeb = true;
  bool _hasUnSavedChanges = false;

  bool get isDarkMode => _isDarkMode;
  bool get saveToWeb => _saveToWeb;
  bool get hasUnSavedChanges => _hasUnSavedChanges;
  bool get loggedId => _userToken != "";
  bool get firstRun => _firstRun;
  String get userId => _userId;
  String get userToken => _userToken;

  Future<Map<String, bool>> loadPrefs(BuildContext context) async {
    await _checkFirstRun();
    await _checkSignedIn();
    await _checkDarkMode();
    await _checkDefaultStorage();
    await _checkUnsavedChanges();

    Map<String, bool> temp = {
      "firstRun": firstRun,
      "loggedId": loggedId,
      "isDarkMode": isDarkMode,
      "saveToWeb": saveToWeb,
      "hasUnSavedChanges": hasUnSavedChanges,
    };
    return temp;
  }

  set isDarkMode(bool val) {
    _isDarkMode = val;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkMode', val);
    });
    notifyListeners();
  }

  set saveToWeb(bool val) {
    _saveToWeb = val;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('saveToWeb', val);
    });
    notifyListeners();
  }

  set hasUnSavedChanges(bool val) {
    _hasUnSavedChanges = val;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('hasUnSavedChanges', val);
    });
    notifyListeners();
  }

  set firstRun(bool val) {
    _firstRun = val;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('firstRun', val);
    });
    notifyListeners();
  }

  set userToken(String val) {
    _userToken = val;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('userToken', val);
    });
    notifyListeners();
  }

  set userId(String val) {
    _userId = val;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('userId', val);
    });
    notifyListeners();
  }

  Future _checkFirstRun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final firstRun = prefs.getBool('firstRun') ?? true;
    _firstRun = firstRun;
  }

  Future _checkSignedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken') ?? "";
    final id = prefs.getString('userId') ?? "";
    _userToken = token;
    _userId = id;
  }

  Future _checkDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getBool('isDarkMode') ?? false;
    _isDarkMode = savedMode;
  }

  Future _checkDefaultStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final saveToWeb = prefs.getBool('saveToWeb') ?? true;
    _saveToWeb = saveToWeb;
  }

  Future _checkUnsavedChanges() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final hasUnSavedChanges = prefs.getBool('hasUnSavedChanges') ?? false;
    _hasUnSavedChanges = hasUnSavedChanges;
  }
}
