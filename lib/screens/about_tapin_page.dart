import 'package:flutter/material.dart';

class AboutTapInPage extends StatelessWidget {
  final bool isDarkMode;

  const AboutTapInPage({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color bgColor = isDarkMode ? Colors.black : Colors.white;
    Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "About TapIn",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo TapIn
            Center(
              child: Image.asset(
                'assets/images/tapin_logo.png',
                height: 100,
              ),
            ),
            const SizedBox(height: 20),

            // Kad Info
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What is TapIn?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "TapIn is an innovative attendance and time tracking solution designed for modern teams. It allows users to check-in and check-out with real-time GPS tracking, manage working hours, and visualize weekly and monthly attendance statistics.",
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Kad Ciri-Ciri
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Key Features:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildFeature(
                        textColor, "✔ Real-time GPS check-in & check-out"),
                    _buildFeature(
                        textColor, "✔ Daily, weekly & monthly analytics"),
                    _buildFeature(
                        textColor, "✔ Have a user-friendly interface"),
                    _buildFeature(
                        textColor, "✔ Database integrated & secure login"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Version 1.0.0 by Afiq Developer 🧠",
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(Color textColor, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, color: textColor),
      ),
    );
  }
}
