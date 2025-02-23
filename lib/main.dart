import 'package:flutter/material.dart';
import 'login.dart';
import 'sign_up.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TapIn',
      home: LoginPage(),
    );
  }
}
