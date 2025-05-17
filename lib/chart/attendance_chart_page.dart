import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AttendanceChartPage extends StatefulWidget {
  const AttendanceChartPage({super.key});

  @override
  _AttendanceChartPageState createState() => _AttendanceChartPageState();
}

class _AttendanceChartPageState extends State<AttendanceChartPage> {
  User? _user;
  DatabaseReference? _attendanceRef;
  final Map<String, double> _workingHoursPerDay = {
    'Mon': 0,
    'Tue': 0,
    'Wed': 0,
    'Thu': 0,
    'Fri': 0,
    'Sat': 0,
    'Sun': 0,
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

      // Simpan Check-In dan Check-Out
      Map<String, DateTime> checkInTimes = {};
      Map<String, DateTime> checkOutTimes = {};

      records.forEach((key, value) {
        String type = value['type'];
        String timeStr = value['time'];

        DateTime time = DateTime.tryParse(_convertToIsoFormat(timeStr)) ?? DateTime.now();

        String day = _getDayAbbreviation(time.weekday);

        if (type == 'Check-In') {
          checkInTimes[day] = time;
        } else if (type == 'Check-Out') {
          checkOutTimes[day] = time;
        }
      });

      // Kira working hours
      checkInTimes.forEach((day, checkIn) {
        if (checkOutTimes.containsKey(day)) {
          double hours = checkOutTimes[day]!.difference(checkIn).inMinutes / 60;
          _workingHoursPerDay[day] = hours;
        }
      });
    }

    setState(() {
      _loading = false;
    });
  }

  String _convertToIsoFormat(String timeStr) {
    // Format asal: hh:mm:ss a, dd MMM yyyy
    try {
      return DateFormat('hh:mm:ss a, dd MMM yyyy').parse(timeStr).toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Chart"),
        backgroundColor: Colors.blue[900],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 12,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() < days.length) {
                            return Text(days[value.toInt()]);
                          }
                          return Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _workingHoursPerDay.entries
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.value,
                              width: 18,
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
    );
  }
}
