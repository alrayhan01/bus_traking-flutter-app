import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart'; // লগইন স্ক্রিন ইমপোর্ট করো

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
      home: const LoginScreen(), // শুরুতে লগইন স্ক্রিন আসবে
    );
  }
}