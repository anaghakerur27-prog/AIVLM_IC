import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'welcome_screen.dart';
// import 'firebase_options.dart'; // if you use flutterfire configure

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIVLM-I&C',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      // WelcomeScreen (Member / Not a Member) is now the first screen
      // instead of LoginPage.
      home: const WelcomeScreen(),
    );
  }
}