import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'my_record.dart';
import 'profile.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    MyRecordPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "My Record",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  String _currentTime = "";
  String _userName = "Employee";
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _trackingTimer;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  bool _isCheckedIn = false;
  bool _hasRequestedPermission = false;
  final DatabaseReference _db = FirebaseDatabase.instance.ref("attendance");
  final List<Position> _positions = [];
  double _totalDistance = 0.0;
  GoogleMapController? _mapController;
  final List<LatLng> _polylineCoordinates = [];
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _updateTime();
    _fetchUserName();
    _loadCheckInStatus();

    if (!_hasRequestedPermission) {
    checkLocationPermission();
    _hasRequestedPermission = true;
  }

  _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
    _updateTime();
  });
}

Future<void> checkLocationPermission() async {
  PermissionStatus status = await Permission.location.status;

  if (status.isGranted) {
    return; // ✅ Jika sudah diberi, keluar awal
  }

  if (status.isDenied) {
    final newStatus = await Permission.location.request();
    if (newStatus.isGranted) {
      return;
    }
  }

  if (status.isPermanentlyDenied) {
    // ❗Popup hanya sekali dan tidak dipanggil semula secara automatik
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Location Permission Required 📍"),
          content: Text(
            "Please enable location access in your device settings to continue.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings(); // Pergi ke Settings
                Navigator.pop(context);
              },
              child: Text("Go to Settings"),
            ),
          ],
        ),
      );
    });
  }
}



  @override
  void dispose() {
    _timer?.cancel();
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime =
          DateFormat('hh:mm:ss a, dd MMM yyyy').format(DateTime.now());
    });
  }

  void _fetchUserName() async {
    if (_user != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref("users/${_user!.uid}");
      final snapshot = await userRef.get();
      if (snapshot.exists && snapshot.value != null) {
        setState(() {
          _userName = (snapshot.value as Map)["name"] ?? "Employee";
        });
      }
    }
  }

  void _startTracking() {
    _stopwatch.start();
    _positions.clear();
    _polylineCoordinates.clear();
    _totalDistance = 0.0;

    _trackingTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!_isPaused) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (_positions.isNotEmpty) {
          double distance = Geolocator.distanceBetween(
            _positions.last.latitude,
            _positions.last.longitude,
            position.latitude,
            position.longitude,
          );
          _totalDistance += distance;
        }

        _positions.add(position);
        _polylineCoordinates.add(LatLng(position.latitude, position.longitude));

        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: PolylineId("route"),
          points: _polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));

        setState(() {
          _elapsed = _stopwatch.elapsed;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      }
    });
  }

  void _pauseTracking() async {
    bool confirm = await _showConfirmationDialog(
        "Pause Tracking", "Anda pasti mahu hentikan sementara tracking?");
    if (confirm) {
      setState(() {
        _isPaused = true;
        _stopwatch.stop();
      });
    }
  }

  void _resumeTracking() async {
    bool confirm = await _showConfirmationDialog(
        "Resume Tracking", "Are you sure you want to resume tracking?");
    if (confirm) {
      setState(() {
        _isPaused = false;
        _stopwatch.start();
      });
    }
  }

  void _loadCheckInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckedIn = prefs.getBool("isCheckedIn") ?? false;
    });
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                child: Text(
                  "Ya",
                  style:
                      TextStyle(color: Colors.white), // ✔️ Letak di dalam Text
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _stopTracking() {
    _stopwatch.stop();
    _trackingTimer?.cancel();
  }

  Future<void> _handleCheckInOut(String type) async {
    _updateTime();

    if (type == "Check-In" && _isCheckedIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Info"),
          content:
              Text("Check-in already recorded. No need to check in again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    if (_user == null) return;

    DateTime now = DateTime.now();
    String status = "";

    if (type == "Check-In") {
      DateTime startTime = DateTime(now.year, now.month, now.day, 8, 30);
      status = now.isAfter(startTime) ? "Late" : "On Time";
      _startTracking();
    } else if (type == "Check-Out") {
      DateTime endTime = DateTime(now.year, now.month, now.day, 17, 30);
      status = now.isBefore(endTime) ? "Early Departure" : "On Time";
      _stopTracking();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    String latitude = position.latitude.toString();
    String longitude = position.longitude.toString();

    String recordId = _db.child(_user!.uid).push().key!;
    await _db.child(_user!.uid).child(recordId).set({
      "type": type,
      "time": _currentTime,
      "latitude": latitude,
      "longitude": longitude,
      "status": status,
      "working_hours":
          type == "Check-Out" ? "${_elapsed.inMinutes} mins" : "",
      "distance": type == "Check-Out"
          ? "${(_totalDistance / 1000).toStringAsFixed(2)} km"
          : "",
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList("attendance") ?? [];
    records.add("$recordId|$type|$latitude|$longitude|$_currentTime|$status");
    await prefs.setStringList("attendance", records);
    prefs.setBool("isCheckedIn", type == "Check-In");

    if (type == "Check-In") {
      final motivationalMessages = [
        "Have a blessed workday.",
        "Purpose fuels progress.",
        "Have a nice day.",
        "Keep moving forward.",
        "Do your best, let the rest flow."
      ];
      motivationalMessages.shuffle();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Check-In Successful ✅"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$type successful at $_currentTime"),
              SizedBox(height: 12),
              Text(
                motivationalMessages.first,
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.blueGrey),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      if (type == "Check-Out") {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Check-Out Successful ✅"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("You have successfully checked out at $_currentTime."),
                SizedBox(height: 10),
                Text("Elapsed: ${_elapsed.inMinutes} minutes"),
                Text(
                    "Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km"),
                SizedBox(height: 10),
                Text("Thank you for your hard work today!💼"),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
            ],
          ),
        );
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[900]!, Colors.blue[600]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/tapin_logo.png',
                          height: 100,
                        ),
                        SizedBox(width: 15),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.cyanAccent,
                              Colors.blueAccent,
                              Colors.white
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                          child: Text(
                            'TapIn',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .white, // Warna asal akan ditimpa shader
                              shadows: [
                                Shadow(
                                  blurRadius: 12.0,
                                  color: Colors.blueAccent.withOpacity(0.8),
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildWelcomeCard(),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 400,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(3.1390, 101.6869),
                        zoom: 14,
                      ),
                      polylines: _polylines,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildCheckInButton(),
                  SizedBox(height: 10),
                  _buildPauseResumeButtons(),
                  SizedBox(height: 10),
                  _buildCheckOutButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: Colors.white,
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: Icon(
                Icons.access_time_filled,
                size: 140,
                color: Colors.blue.withOpacity(0.09),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome, $_userName",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Current Time: $_currentTime",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Elapsed: ${_elapsed.inHours.toString().padLeft(2, '0')}:${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km",
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => _handleCheckInOut("Check-In"),
        icon: Icon(Icons.check_circle, size: 24, color: Colors.white),
        label: Text(
          "Check-In",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

 Widget _buildCheckOutButton() {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton.icon(
      onPressed: () async {
        if (!_isCheckedIn) {
          // ❗Jika belum check-in, paparkan mesej
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Check-In Required"),
              content: Text("You must check-in first before checking out."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
          );
          return; // ⛔ Hentikan proses
        }

        // ✅ Jika sudah check-in, proceed seperti biasa
        bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Confirm Check-Out"),
            content: Text(
                "Confirm check-out? Your work session will end at this time!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Confirm"),
              ),
            ],
          ),
        );

        if (confirm) {
          _handleCheckInOut("Check-Out");
        }
      },
      icon: Icon(Icons.exit_to_app, size: 24, color: Colors.white),
      label: Text(
        "Check-Out",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}


  Widget _buildPauseResumeButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _pauseTracking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              textStyle: TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pause",
                  style: TextStyle(
                      color: Colors.white), // Tukar warna teks ke putih
                ),
                Icon(Icons.pause, color: Colors.white),
                SizedBox(width: 8),
              ],
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _resumeTracking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Resume",
                  style: TextStyle(color: Colors.white), // Warna teks putih
                ),
                Icon(Icons.play_arrow, color: Colors.white), // Ikon resume
                SizedBox(width: 8), // Jarak antara ikon dan teks
              ],
            ),
          ),
        ),
      ],
    );
  }
}
