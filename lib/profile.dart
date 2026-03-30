import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // ডাটাবেস থেকে ইউজারের ইনফরমেশন টেনে আনার ফাংশন
  Future<void> _fetchUserData() async {
    if (currentUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
        });
      }
    }
  }

  // পাসওয়ার্ড রিসেট লিংক ইমেইলে পাঠানোর ফাংশন
  Future<void> _resetPassword() async {
    if (currentUser != null && currentUser!.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser!.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("পাসওয়ার্ড রিসেট লিংক আপনার ইমেইলে পাঠানো হয়েছে! দয়া করে ইনবক্স চেক করুন।"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ভুল হয়েছে: ${e.toString()}"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('আমার প্রোফাইল', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo, // প্রোফাইলের জন্য একটু ভিন্ন কালার দিলাম
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator()) // ডাটা আসার আগ পর্যন্ত লোডিং দেখাবে
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // প্রোফাইল আইকন বা ছবি
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // নাম এবং রোল
            Text(userData!['name'] ?? 'নাম নেই', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(userData!['role'] ?? 'রোল নেই', style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),

            const Divider(height: 50, thickness: 1.5),

            // আইডি এবং ইমেইল লিস্ট
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.badge, color: Colors.indigo, size: 30),
                title: const Text('আইডি নম্বর', style: TextStyle(color: Colors.grey)),
                subtitle: Text(userData!['id'] ?? 'আইডি নেই', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.indigo, size: 30),
                title: const Text('ইমেইল', style: TextStyle(color: Colors.grey)),
                subtitle: Text(userData!['email'] ?? 'ইমেইল নেই', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),

            const Spacer(), // বাটনটাকে একদম নিচে নামিয়ে দেওয়ার জন্য

            // পাসওয়ার্ড পরিবর্তন বাটন
            ElevatedButton.icon(
              onPressed: _resetPassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('পাসওয়ার্ড পরিবর্তন করুন', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
            ),

            const SizedBox(height: 15), // একটু ফাঁকা জায়গা

            // নতুন লগআউট বাটন
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  // লগআউট করে লগইন পেজে পাঠাবে এবং আগের সব পেজ ক্লোজ করে দেবে
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('লগআউট করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}