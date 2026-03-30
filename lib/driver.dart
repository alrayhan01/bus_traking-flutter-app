import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart'; // প্রোফাইল পেজ ইমপোর্ট করা হলো

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  bool _isTripStarted = false;
  StreamSubscription<Position>? _positionStream;

  String? _busId;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _getInitialLocation();
  }

  Future<void> _loadDriverData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _busId = userDoc['id'];
        });
      }
    }
  }

  Future<void> _getInitialLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _startTrip() {
    if (_busId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("আপনার বাস আইডি পাওয়া যায়নি!")));
      return;
    }

    setState(() { _isTripStarted = true; });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen((Position position) {
      setState(() { _currentPosition = LatLng(position.latitude, position.longitude); });

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
      }
      _updateLocationToFirebase(position, true);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("ট্রিপ শুরু! বাস আইডি: $_busId"), backgroundColor: Colors.green),
    );
  }

  void _stopTrip() {
    if (_busId == null) return;

    setState(() { _isTripStarted = false; });
    _positionStream?.cancel();

    FirebaseFirestore.instance.collection('buses').doc(_busId).set({
      'is_active': false,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ট্রিপ বন্ধ! লোকেশন শেয়ারিং অফ।"), backgroundColor: Colors.red),
    );
  }

  Future<void> _updateLocationToFirebase(Position position, bool isActive) async {
    if (_busId == null) return;

    try {
      await FirebaseFirestore.instance.collection('buses').doc(_busId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'is_active': isActive,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_busId == null ? 'ড্রাইভার ড্যাশবোর্ড' : 'বাস: $_busId', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        actions: [
          // প্রোফাইল পেজে যাওয়ার বাটন
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
          Expanded(
            child: _currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
              initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 17.0),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              markers: {
                Marker(
                  markerId: const MarkerId('live_bus'),
                  position: _currentPosition!,
                  infoWindow: InfoWindow(title: _busId ?? 'আমার বাস'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, spreadRadius: 2)]
            ),
            child: Column(
              children: [
                // টিচারদের মেসেজ দেখার অপশন
                if (_busId != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('buses').doc(_busId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;

                        // মেসেজ থাকলে এবং ফাঁকা না হলে দেখাবে
                        if (data.containsKey('teacher_message') && data['teacher_message'] != '') {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent)
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notification_important, color: Colors.red, size: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                        data['teacher_message'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16)
                                    )
                                ),
                                // ❌ নতুন ক্রস বাটন
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red, size: 25),
                                  onPressed: () {
                                    // বাটনে চাপ দিলে ফায়ারবেস থেকে মেসেজটা মুছে যাবে (ফাঁকা হয়ে যাবে)
                                    FirebaseFirestore.instance.collection('buses').doc(_busId).update({
                                      'teacher_message': ''
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isTripStarted ? null : _startTrip,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start Trip", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: !_isTripStarted ? null : _stopTrip,
                      icon: const Icon(Icons.stop),
                      label: const Text("Stop Trip", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}