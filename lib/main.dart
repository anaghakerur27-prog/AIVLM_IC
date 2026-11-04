
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'screens/login_page.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

const String environment =
    String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only once.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: environment == 'prod'
          ? prod.DefaultFirebaseOptions.currentPlatform
          : dev.DefaultFirebaseOptions.currentPlatform,
    );
  }
  final app = Firebase.app();

debugPrint('========== FIREBASE DEBUG ==========');
debugPrint('Environment: $environment');
debugPrint('Project ID: ${app.options.projectId}');
debugPrint('Sender ID: ${app.options.messagingSenderId}');
debugPrint('App ID: ${app.options.appId}');
debugPrint('====================================');

  // Configure Crashlytics.
  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '123',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
