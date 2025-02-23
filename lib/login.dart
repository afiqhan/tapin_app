import 'package:flutter/material.dart';
import 'sign_up.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Login to TapIn",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text("Username", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  _buildTextField("hello@tapin.com", _usernameController, false),
                  SizedBox(height: 15),
                  Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  _buildTextField("password", _passwordController, true),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                          ),
                          Text("Remember Me"),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Forgot password?",
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        print("User Logged In: ${_usernameController.text}");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Login", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 15),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          text: "New to TapIn? ",
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: "Sign Up Now",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String hintText, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintText: hintText,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }
}