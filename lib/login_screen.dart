import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// আলাদা আলাদা স্ক্রিনগুলো ইমপোর্ট করা হলো
import 'student.dart';
import 'teacher.dart';
import 'driver.dart';
import 'signup_screen.dart';
import 'admin.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  // লগইন, এপ্রুভাল এবং রোল চেক করার ফাংশন
  Future<void> _login() async {
    try {
      // ১. ইমেইল-পাসওয়ার্ড চেক
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ২. ফায়ারবেস থেকে ইউজারের স্ট্যাটাস এবং রোল (Role) নিয়ে আসা
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String status = userDoc['status'];
        String role = userDoc['role'];

        // এডমিন হলে স্ট্যাটাস চেক করার দরকার নেই, সরাসরি এডমিন প্যানেলে যাবে
        if (role == 'Admin') {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
          }
        }
        // বাকিদের জন্য এপ্রুভড কিনা চেক করবে
        else if (status == 'approved') {
          if (mounted) {
            if (role == 'Student') {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentScreen()));
            } else if (role == 'Teacher') {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherScreen()));
            } else if (role == 'Driver') {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DriverScreen()));
            }
          }
        } else {
          await _auth.signOut();
          if (mounted) {
            _showErrorDialog("আপনার অ্যাকাউন্টটি এখনো পেন্ডিং আছে। দয়া করে এডমিনের এপ্রুভালের জন্য অপেক্ষা করুন।");
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("এরর: ইমেইল বা পাসওয়ার্ড ভুল!")),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("অপেক্ষা করুন"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ঠিক আছে"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login - Bus Tracker"), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "ইমেইল")),
            const SizedBox(height: 10),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "পাসওয়ার্ড"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white
              ),
              child: const Text("লগইন", style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
              },
              child: const Text("অ্যাকাউন্ট নেই? এখানে সাইন-আপ করুন"),
            )
          ],
        ),
      ),
    );
  }
}