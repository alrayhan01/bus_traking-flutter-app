import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _userRole = 'Student'; // ডিফল্ট রোল স্টুডেন্ট
  final _auth = FirebaseAuth.instance;

  Future<void> _signUp() async {
    try {
      // ১. ফায়ারবেস অথেনটিকেশনে ইউজার তৈরি করা
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ২. ফায়ারবেস ডাটাবেসে (Firestore) ইউজারের সব ইনফরমেশন সেভ করা
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'id': _idController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _userRole,
        'status': 'pending', // শুরুতে পেন্ডিং থাকবে, এডমিন এপ্রুভ করবে
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("রেজিস্ট্রেশন সফল! এপ্রুভালের জন্য অপেক্ষা করুন।")),
        );
        Navigator.pop(context); // রেজিস্ট্রেশন শেষে লগইন স্ক্রিনে ফিরে যাবে
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ভুল হয়েছে: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("নতুন অ্যাকাউন্ট খুলুন")),
      body: SingleChildScrollView( // স্ক্রিন যাতে স্ক্রল করা যায়
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "পুরো নাম")),
            TextField(controller: _idController, decoration: const InputDecoration(labelText: "স্টুডেন্ট/টিচার আইডি")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "ইমেইল")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "পাসওয়ার্ড"), obscureText: true),
            const SizedBox(height: 20),

            // রোল সিলেক্ট করার ড্রপডাউন মেনু
            const Text("আপনি কে?"),
            DropdownButton<String>(
              value: _userRole,
              isExpanded: true,
              items: <String>['Student', 'Teacher', 'Driver'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _userRole = newValue!;
                });
              },
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("রেজিস্ট্রেশন সম্পন্ন করুন"),
            ),
          ],
        ),
      ),
    );
  }
}