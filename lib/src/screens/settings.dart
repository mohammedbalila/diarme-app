import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../providers/shared_prefs.dart';
import 'login.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        leading: BackButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, "home");
          },
        ),
      ),
      body: Consumer<SharedPrefsProvider>(
        builder: (context, provider, child) => Container(
          margin: EdgeInsets.all(5),
          child: ListView(
            children: [
              Card(
                child: ListTile(
                  title: Text('Account Info'),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, "account");
                  },
                ),
              ),
              Card(
                child: SwitchListTile(
                  title: const Text('Dark mode'),
                  value: provider.isDarkMode,
                  onChanged: (bool value) {
                    provider.isDarkMode = value;
                  },
                ),
              ),
              Card(
                child: SwitchListTile(
                  title: const Text('Set web as your default storage'),
                  activeColor: Theme.of(context).colorScheme.secondaryContainer,
                  value: provider.saveToWeb,
                  onChanged: (bool value) {
                    provider.saveToWeb = value;
                  },
                ),
              ),
              SizedBox(height: 20),
              Card(
                child: ListTile(
                  title: Text('Logout'),
                  onTap: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    var db = UserDBProvider();
                    prefs.remove('userToken');
                    await db.open();
                    await db.delete();

                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => Scaffold(body: LoginScreen()),
                    ));
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
