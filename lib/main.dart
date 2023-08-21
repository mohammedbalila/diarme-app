import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:diarme/src/providers/shared_prefs.dart';
import 'package:diarme/src/providers/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SentryFlutter.init(
    (options) {
      options.dsn =
          options.dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider<SharedPrefsProvider>(
          create: (_) => SharedPrefsProvider(),
        ),
        ChangeNotifierProvider<AppStateNotifier>(
          create: (context) => AppStateNotifier(),
        )
      ],
      child: const DiarmeApp(),
    )),
  );
}
