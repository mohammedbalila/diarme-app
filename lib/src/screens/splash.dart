import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'login.dart';
import '../providers/shared_prefs.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    var sharedPrefs = Provider.of<SharedPrefsProvider>(context);
    return Scaffold(
      body: FutureBuilder(
        future: sharedPrefs.loadPrefs(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            bool loggedId = snapshot.data!['loggedId'] ?? false;
            if (loggedId == true) {
              return HomeScreen('/all');
            }
            return LoginScreen();
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CircularProgressIndicator()],
              ),
            ),
          );
        },
      ),
    );
  }
}
