import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapin_app/screens/about_tapin_page.dart';
import 'login.dart';
import 'edit_profile.dart';
import '../chart/attendance_chart_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  User? _user;
  String _userName = "User";
  String _email = "example@email.com";
  String _bio = "No bio yet";
  String _profileImageUrl = "";
  bool _isDarkMode = false;
  String _selectedLanguage = "English";
  File? _image;
  bool _isUploading = false;
  final bool _hasChanges = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
    _loadTheme();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  }

  // Dapatkan data pengguna dari Firebase
  void _fetchUserData() async {
    if (_user != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref("users/${_user!.uid}");
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        Map userData = snapshot.value as Map;
        setState(() {
          _userName = userData["name"] ?? "User";
          _email = userData["email"] ?? "example@email.com";
          _bio = userData["bio"] ?? "No bio yet";
          _profileImageUrl = userData["profile_image"] ?? "";
        });
      }
    }
  }

  Future<void> _editField(String field, String currentValue) async {
    TextEditingController controller =
        TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${field == "name" ? "Name" : "Bio"}"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter new ${field == "name" ? "name" : "bio"}",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty && _user != null) {
                await FirebaseDatabase.instance
                    .ref("users/${_user!.uid}")
                    .update({field: controller.text.trim()});
                setState(() {
                  if (field == "name") {
                    _userName = controller.text.trim();
                  } else if (field == "bio") {
                    _bio = controller.text.trim();
                  }
                });
              }
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // Pilih gambar dari galeri
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File tempImage = File(pickedFile.path);

      setState(() {
        _image = tempImage;
        _isUploading = true; // 🔥 Mula upload
      });

      try {
        if (_user != null) {
          Reference ref = FirebaseStorage.instance
              .ref()
              .child("profile_images")
              .child("${_user!.uid}.jpg");

          await ref.putFile(tempImage);
          String imageUrl = await ref.getDownloadURL();

          await FirebaseDatabase.instance
              .ref("users/${_user!.uid}")
              .update({"profile_image": imageUrl});

          setState(() {
            _profileImageUrl = imageUrl;
            _isUploading = false; // 🔥 Upload siap
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile picture updated successfully!")),
          );
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error during upload: $e")),
        );
      }
    }
  }

  // Logout pengguna
  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Log Out"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text(
              "Log Out",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Tukar tema (Light/Dark)
  void _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("dark_mode", _isDarkMode);
  }

  // Muat naik tema dari SharedPreferences
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("dark_mode") ?? false;
    });
  }

  // Tukar bahasa
  void _changeLanguage(String? value) {
    if (value != null) {
      setState(() {
        _selectedLanguage = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = _isDarkMode ? Colors.white : Colors.black;
    Color secondaryTextColor = _isDarkMode ? Colors.white70 : Colors.grey;
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(
            fontSize: 22,
            color:
                const Color.fromARGB(255, 255, 255, 255), // contoh: warna biru
          ),
        ),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.white, // Set warna icon jadi putih
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                          userName: _userName,
                          email: _email,
                          bio: _bio,
                          profileImageUrl: _profileImageUrl,
                        )),
              ).then((_) => _fetchUserData()); // Refresh profile selepas edit
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            color: Colors.white,
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (_profileImageUrl.isNotEmpty
                              ? NetworkImage(_profileImageUrl)
                              : AssetImage("assets/default_profile.png"))
                          as ImageProvider,
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(_userName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            Text(_email,
                style: TextStyle(fontSize: 16, color: secondaryTextColor)),
            SizedBox(height: 10),
            Text(_bio,
                style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: secondaryTextColor)),
            SizedBox(height: 20),
            Divider(),
            ListTile(
  leading: Icon(Icons.bar_chart, color: Colors.blue[900]),
  title: Text("Attendance Chart", style: TextStyle(color: textColor)),
  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: secondaryTextColor),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AttendanceChartPage()),
  ),
),

ListTile(
  leading: Icon(Icons.dark_mode, color: Colors.blue[900]),
  title: Text("Dark Mode", style: TextStyle(color: textColor)),
  trailing: Switch(
    value: _isDarkMode,
    onChanged: _toggleDarkMode,
  ),
),

ListTile(
  leading: Icon(Icons.language, color: Colors.blue[900]),
  title: Text("Language",
      style: TextStyle(
        color: _isDarkMode ? Colors.white : Colors.black,
      )),
  trailing: DropdownButton<String>(
    value: _selectedLanguage,
    dropdownColor: _isDarkMode ? Colors.black : Colors.white,
    style: TextStyle(
      color: _isDarkMode ? Colors.white : Colors.black,
    ),
    items: ["English", "Bahasa Melayu"]
        .map((lang) => DropdownMenuItem(
              value: lang,
              child: Text(lang),
            ))
        .toList(),
    onChanged: _changeLanguage,
  ),
),

// ✅ Butang About TapIn di bawah sekali
ListTile(
  leading: Icon(Icons.info_outline, color: Colors.blue[900]),
  title: Text("About TapIn", style: TextStyle(color: textColor)),
  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: secondaryTextColor),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AboutTapInPage(isDarkMode: _isDarkMode),
      ),
    );
  },
),

          ],
        ),
      ),
    );
  }
}
