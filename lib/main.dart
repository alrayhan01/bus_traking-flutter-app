import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart'; // লগইন স্ক্রিন ইমপোর্ট করো
import 'splash_screen.dart'; // এটা উপরে যোগ করবে

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DU Bus Tracker',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const SplashScreen(), // এখন শুরুতে স্প্ল্যাশ স্ক্রিন আসবে
    );
  }
}