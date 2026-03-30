import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'profile.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  GoogleMapController? _mapController;
  LatLng? _busPosition;

  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? _busSubscription;

  String _statusMessage = "বাসের আইডি লিখে সার্চ করুন ";

  // বাস খোঁজার মেইন ফাংশন
  void _searchBus() {
    String busId = _searchController.text.trim();
    if (busId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("আগে বাসের আইডি লিখুন!"))
      );
      return;
    }

    setState(() {
      _statusMessage = "খোঁজা হচ্ছে...";
      _busPosition = null; // আগের কোনো লোকেশন থাকলে মুছে দেবে
    });

    // আগের কোনো সার্চ থাকলে সেটা ক্যানসেল করে নতুন করে খুঁজবে
    _busSubscription?.cancel();

    _busSubscription = FirebaseFirestore.instance
        .collection('buses')
        .doc(busId) // স্টুডেন্ট যেই আইডি লিখেছে, শুধু সেটাই খুঁজবে
        .snapshots()
        .listen((DocumentSnapshot snapshot) {

      if (!snapshot.exists) {
        setState(() {
          _statusMessage = "এই আইডি দিয়ে কোনো বাস পাওয়া যায়নি!";
          _busPosition = null;
        });
        return;
      }

      var data = snapshot.data() as Map<String, dynamic>;
      bool isActive = data['is_active'] ?? false;

      // যদি ড্রাইভার 'Stop Trip' করে রাখে
      if (!isActive) {
        setState(() {
          _statusMessage = "বাসটি এখন অফলাইনে আছে বা ট্রিপ বন্ধ আছে।";
          _busPosition = null;
        });
        return;
      }

      // যদি বাস চলতে থাকে (is_active: true)
      setState(() {
        _busPosition = LatLng(data['latitude'], data['longitude']);
        _statusMessage = "বাসের লাইভ লোকেশন দেখানো হচ্ছে!";
      });

      if (_mapController != null && _busPosition != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_busPosition!));
      }
    });
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('স্টুডেন্ট ড্যাশবোর্ড', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        actions: [
          // প্রোফাইলে যাওয়ার বাটন
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          // লগআউট বাটন

        ],
      ),
      body: Column(
        children: [
          // 🔍 সার্চ বক্স এরিয়া
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "বাসের আইডি লিখুন...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _searchBus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),

          // 🗺️ ম্যাপ বা মেসেজ দেখানোর এরিয়া
          Expanded(
            child: _busPosition == null
                ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)
                  ),
                )
            )
                : GoogleMap(
              initialCameraPosition: CameraPosition(target: _busPosition!, zoom: 17.0),
              onMapCreated: (controller) => _mapController = controller,
              markers: {
                Marker(
                  markerId: const MarkerId('student_view_bus'),
                  position: _busPosition!,
                  infoWindow: InfoWindow(title: 'বাস: ${_searchController.text}'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}