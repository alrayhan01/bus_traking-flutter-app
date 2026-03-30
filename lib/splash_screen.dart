import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// সব স্ক্রিন ইমপোর্ট করতে হবে যাতে সরাসরি পাঠানো যায়
import 'login_screen.dart';
import 'student.dart';
import 'teacher.dart';
import 'driver.dart';
import 'admin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // ৩ সেকেন্ড ওয়েট করবে স্প্ল্যাশ স্ক্রিন দেখানোর জন্য
    await Future.delayed(const Duration(seconds: 3));

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // যদি লগইন করা থাকে, তাহলে ফায়ারবেস থেকে তার রোল চেক করবে
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists && mounted) {
        String status = userDoc['status'];
        String role = userDoc['role'];

        if (role == 'Admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
          return;
        } else if (status == 'approved') {
          if (role == 'Student') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentScreen()));
            return;
          } else if (role == 'Teacher') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherScreen()));
            return;
          } else if (role == 'Driver') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DriverScreen()));
            return;
          }
        }
      }
    }

    // যদি লগইন না থাকে বা এপ্রুভড না হয়, তাহলে লগইন পেজে যাবে
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // বাসের ছবির সাথে সাদা ব্যাকগ্রাউন্ড ভালো মানাবে
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/bus_logo.png ', height: 250),
            const SizedBox(height: 20),
            const Text(
              ' Bus Tracker',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1.5),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.redAccent),
          ],
        ),
      ),
    );
  }
}