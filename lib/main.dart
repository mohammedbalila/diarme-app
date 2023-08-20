import 'package:diarme/src/providers/shared_prefs.dart';
import 'package:diarme/src/providers/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/app.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
    providers: [
      ChangeNotifierProvider<SharedPrefsProvider>(
        create: (_) => SharedPrefsProvider(),
      ),
      ChangeNotifierProvider<AppStateNotifier>(
        create: (context) => AppStateNotifier(),
      )
    ],
    child: const DiarmeApp(),
  )
  );
}
