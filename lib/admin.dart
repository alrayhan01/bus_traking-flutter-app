import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('এডমিন প্যানেল', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      // ফায়ারবেস থেকে শুধু 'pending' স্ট্যাটাসওয়ালা ইউজারদের টেনে আনবে
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("কোনো নতুন রিকোয়েস্ট নেই! 🎉", style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          var pendingUsers = snapshot.data!.docs;

          // রোল অনুযায়ী ইউজারদের আলাদা করা হচ্ছে
          var pendingStudents = pendingUsers.where((doc) => doc['role'] == 'Student').toList();
          var pendingTeachers = pendingUsers.where((doc) => doc['role'] == 'Teacher').toList();
          var pendingDrivers = pendingUsers.where((doc) => doc['role'] == 'Driver').toList();

          return ListView(
            padding: const EdgeInsets.all(15),
            children: [
              _buildCategoryCard(context, 'স্টুডেন্ট রিকোয়েস্ট', pendingStudents, Colors.blueAccent),
              _buildCategoryCard(context, 'টিচার রিকোয়েস্ট', pendingTeachers, Colors.purple),
              _buildCategoryCard(context, 'ড্রাইভার রিকোয়েস্ট', pendingDrivers, Colors.redAccent),
            ],
          );
        },
      ),
    );
  }

  // সুন্দর কার্ড ডিজাইন করার ফাংশন
  Widget _buildCategoryCard(BuildContext context, String title, List<QueryDocumentSnapshot> users, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
        // পাশে কয়টা রিকোয়েস্ট আছে তার ব্যাজ (Badge)
        trailing: CircleAvatar(
          backgroundColor: color,
          child: Text('${users.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        // কার্ডে ক্লিক করলে লিস্ট ওপেন হবে
        children: users.map((userDoc) {
          return ListTile(
            title: Text(userDoc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${userDoc['id']} \nEmail: ${userDoc['email']}'),
            isThreeLine: true,
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () {
                // এপ্রুভ বাটনে ক্লিক করলে ফায়ারবেসে স্ট্যাটাস 'approved' হয়ে যাবে
                FirebaseFirestore.instance.collection('users').doc(userDoc.id).update({
                  'status': 'approved'
                });
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${userDoc['name']}-কে এপ্রুভ করা হয়েছে!"), backgroundColor: Colors.green)
                );
              },
              child: const Text('Approve'),
            ),
          );
        }).toList(),
      ),
    );
  }
}


