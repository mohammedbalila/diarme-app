import 'package:diarme/src/screens/account.dart';
import 'package:diarme/src/screens/note_editor.dart';
import 'package:diarme/src/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/shared_prefs.dart';
import './screens/home.dart';
import './screens/splash.dart';

// Create theme data

class AppTheme {
  final Map<int, Color> primary = {
    50: Color(0xffe0c2c0),
    100: Color(0xffd3b1af),
    200: Color(0xffc5a09e),
    300: Color(0xffb7908d),
    400: Color(0xffaa7f7c),
    500: Color(0xff9c6e6b),
    600: Color(0xff8f5d5a),
    700: Color(0xff814c49),
  };
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: MaterialColor(0xFFE91E63, AppTheme().primary),
    useMaterial3: true,
    scaffoldBackgroundColor: Color(0xffe0c2c0),
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xff57394a),
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xff57394a),
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xff57394a),
      ),
      bodySmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Color(0xff57394a),
      ),
      bodyMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: Color(0xff57394a),
      ),
      bodyLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.normal,
        color: Color(0xff57394a),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: Color(0xff57394a),
      titleTextStyle: TextStyle(
        color: Color(0xff57394a),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    colorScheme: ColorScheme.light(
        secondary: Color(0xff57394a),
        secondaryContainer: Color(0xffeab586),
        tertiary: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xff57394a),
      actionsIconTheme: IconThemeData(
        color: Colors.white,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: Color.fromARGB(255, 243, 213, 186),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      secondary: Colors.white,
      tertiary: Colors.black,
      secondaryContainer: Colors.black,
    ),
  );
}

class DiarmeApp extends StatelessWidget {
  const DiarmeApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var sharedPrefs = Provider.of<SharedPrefsProvider>(context);
    return FutureBuilder(
      future: sharedPrefs.loadPrefs(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          bool isDarkMode = snapshot.data!['isDarkMode'] ?? false;
          return MaterialApp(
            title: 'Diarme',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            onGenerateRoute: routes,
            debugShowCheckedModeBanner: false,
          );
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
    );
  }

  Route routes(RouteSettings settings) {
    String route = settings.name ?? "";

    String param = route.split("/").lastOrNull ?? "";

    if (route.contains("home")) {
      return MaterialPageRoute(builder: (context) {
        return HomeScreen(param);
      });
    } else if (route.contains("notes")) {
      return MaterialPageRoute(builder: (context) {
        return NoteEditorScreen(param);
      });
    } else if (route.contains("account")) {
      return MaterialPageRoute(builder: (context) {
        return AccountScreen();
      });
    } else if (route.contains("settings")) {
      return MaterialPageRoute(builder: (context) {
        return SettingsScreen();
      });
    } else {
      return MaterialPageRoute(builder: (context) {
        return const SplashScreen();
      });
    }
  }
}
