import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'profile.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  GoogleMapController? _mapController;
  LatLng? _busPosition;

  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? _busSubscription;

  String _statusMessage = "বাসের আইডি লিখে সার্চ করুন (যেমন: Khaonika_01)";
  String _teacherName = "একজন শিক্ষক"; // ডিফল্ট নাম

  @override
  void initState() {
    super.initState();
    _loadTeacherData(); // শুরুতে টিচারের নাম টেনে আনবে
  }

  // ফায়ারবেস থেকে লগইন করা টিচারের নাম বের করার ফাংশন
  Future<void> _loadTeacherData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _teacherName = userDoc['name']; // সাইন-আপের সময় দেওয়া নামটা এখানে সেট হবে
        });
      }
    }
  }

  // বাস খোঁজার ফাংশন (স্টুডেন্টদের মতোই)
  void _searchBus() {
    String busId = _searchController.text.trim();
    if (busId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("আগে বাসের আইডি লিখুন!")));
      return;
    }

    setState(() {
      _statusMessage = "খোঁজা হচ্ছে...";
      _busPosition = null;
    });

    _busSubscription?.cancel();

    _busSubscription = FirebaseFirestore.instance.collection('buses').doc(busId).snapshots().listen((DocumentSnapshot snapshot) {
      if (!snapshot.exists) {
        setState(() {
          _statusMessage = "এই আইডি দিয়ে কোনো বাস পাওয়া যায়নি!";
          _busPosition = null;
        });
        return;
      }

      var data = snapshot.data() as Map<String, dynamic>;
      bool isActive = data['is_active'] ?? false;

      if (!isActive) {
        setState(() {
          _statusMessage = "বাসটি এখন অফলাইনে আছে বা ট্রিপ বন্ধ আছে।";
          _busPosition = null;
        });
        return;
      }

      setState(() {
        _busPosition = LatLng(data['latitude'], data['longitude']);
        _statusMessage = "বাসের লাইভ লোকেশন দেখানো হচ্ছে!";
      });

      if (_mapController != null && _busPosition != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_busPosition!));
      }
    });
  }

  // 🚨 স্পেশাল ইমার্জেন্সি মেসেজ পাঠানোর ফাংশন
  Future<void> _sendWaitMessage() async {
    String busId = _searchController.text.trim();

    // বাস সার্চ করা না থাকলে মেসেজ পাঠাতে দেবে না
    if (busId.isEmpty || _busPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("আগে একটি রানিং বাস সার্চ করুন!"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // ফায়ারবেসে বাসের ডকুমেন্টে মেসেজটা লিখে দেওয়া
      await FirebaseFirestore.instance.collection('buses').doc(busId).set({
        'teacher_message': '$_teacherName স্যার রাস্তায় আছেন, দয়া করে ৫ মিনিট অপেক্ষা করুন!',
      }, SetOptions(merge: true)); // merge: true দিলে বাসের লোকেশন মুছবে না, শুধু মেসেজ অ্যাড হবে

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ড্রাইভারকে মেসেজ পাঠানো হয়েছে!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
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
        title: const Text('টিচার ড্যাশবোর্ড', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple, // টিচারদের জন্য পার্পল রং
        actions: [
          // প্রোফাইলে যাওয়ার বাটন
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),

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
                    backgroundColor: Colors.purple,
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
                  markerId: const MarkerId('teacher_view_bus'),
                  position: _busPosition!,
                  infoWindow: InfoWindow(title: 'বাস: ${_searchController.text}'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
              },
            ),
          ),
        ],
      ),
      // 🚨 টিচারদের স্পেশাল বাটন
      floatingActionButton: _busPosition != null ? FloatingActionButton.extended(
        onPressed: _sendWaitMessage,
        label: const Text('৫ মিনিট ওয়েট করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.pan_tool, color: Colors.white),
        backgroundColor: Colors.red,
      ) : null, // বাস সার্চ না করা পর্যন্ত বাটনটা হাইড থাকবে
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}