import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateNotifier extends ChangeNotifier {
  //
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Future<Map<String, bool>> loadPrefs(BuildContext context) async {
    await _checkDarkMode();

    Map<String, bool> temp = {"diarme_dark_mode": isDarkMode};
    return temp;
  }

  set isDarkMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('diarme_dark_mode', isDarkMode);
    });
    notifyListeners();
  }

  Future _checkDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getBool('diarme_dark_mode') ?? false;
    this._isDarkMode = savedMode;
  }
}
