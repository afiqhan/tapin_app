import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AttendancePieChartPage extends StatefulWidget {
  const AttendancePieChartPage({super.key});

  @override
  _AttendancePieChartPageState createState() => _AttendancePieChartPageState();
}

class _AttendancePieChartPageState extends State<AttendancePieChartPage> {
  User? _user;
  DatabaseReference? _attendanceRef;
  final Map<String, int> _attendanceSummary = {
    "Check-In": 0,
    "Check-Out": 0,
    "Break-In": 0,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _attendanceRef = FirebaseDatabase.instance.ref("attendance/${_user!.uid}");
      _fetchAttendanceData();
    }
  }

  void _fetchAttendanceData() async {
    final snapshot = await _attendanceRef?.get();

    if (snapshot != null && snapshot.exists) {
      Map<String, dynamic> records = Map<String, dynamic>.from(snapshot.value as Map);

      records.forEach((key, value) {
        String type = value['type'];
        if (_attendanceSummary.containsKey(type)) {
          _attendanceSummary[type] = _attendanceSummary[type]! + 1;
        }
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<PieChartSectionData> buildPieSections() {
      final colors = [Colors.green, Colors.red, Colors.orange];
      int index = 0;
      return _attendanceSummary.entries.map((entry) {
        final isTouched = false;
        final double fontSize = isTouched ? 18 : 16;
        final double radius = isTouched ? 70 : 60;

        return PieChartSectionData(
          color: colors[index++ % colors.length],
          value: entry.value.toDouble(),
          title: '${entry.key}\n${entry.value}',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Pie Chart"),
        backgroundColor: Colors.blue[900],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: buildPieSections(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Ringkasan Kehadiran",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
    );
  }
}
