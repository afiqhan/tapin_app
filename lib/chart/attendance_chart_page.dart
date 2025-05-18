import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AttendanceChartPage extends StatefulWidget {
  const AttendanceChartPage({super.key});

  @override
  State<AttendanceChartPage> createState() => _AttendanceChartPageState();
}

class _AttendanceChartPageState extends State<AttendanceChartPage> {
  final Map<String, double> _workingHoursPerDay = {
    'Mon': 0,
    'Tue': 0,
    'Wed': 0,
    'Thu': 0,
    'Fri': 0,
    'Sat': 0,
    'Sun': 0,
  };

  final Map<String, double> _workingHoursPerWeek = {
    'Week 1': 0,
    'Week 2': 0,
    'Week 3': 0,
    'Week 4': 0,
    'Week 5': 0,
  };

  String _viewMode = 'Daily';

  User? _user;
  DatabaseReference? _attendanceRef;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      _attendanceRef =
          FirebaseDatabase.instance.ref("attendance/${_user!.uid}");
      _fetchAttendanceData();
    }
  }

  Future<void> _fetchAttendanceData() async {
    final snapshot = await _attendanceRef?.get();

    if (snapshot != null && snapshot.exists) {
      final records = Map<String, dynamic>.from(snapshot.value as Map);

      Map<String, DateTime> checkInTimes = {};
      Map<String, DateTime> checkOutTimes = {};

      for (var entry in records.entries) {
        final type = entry.value['type'];
        final timeStr = entry.value['time'];
        final parsedTime =
            DateTime.tryParse(_convertToIsoFormat(timeStr)) ?? DateTime.now();

        if (_viewMode == 'Daily') {
          final day = _getDayAbbreviation(parsedTime.weekday);
          if (type == 'Check-In') {
            checkInTimes[day] = parsedTime;
          } else if (type == 'Check-Out') {
            checkOutTimes[day] = parsedTime;
          }
        } else if (_viewMode == 'Weekly') {
          final week = _getWeekLabel(parsedTime);
          if (type == 'Check-In') {
            checkInTimes[week] = parsedTime;
          } else if (type == 'Check-Out') {
            checkOutTimes[week] = parsedTime;
          }
        }
      }

      if (_viewMode == 'Daily') {
        for (var day in checkInTimes.keys) {
          if (checkOutTimes.containsKey(day)) {
            final hours =
                checkOutTimes[day]!.difference(checkInTimes[day]!).inMinutes /
                    60;
            _workingHoursPerDay[day] = hours;
          }
        }
      } else if (_viewMode == 'Weekly') {
        for (var week in checkInTimes.keys) {
          if (checkOutTimes.containsKey(week)) {
            final hours =
                checkOutTimes[week]!.difference(checkInTimes[week]!).inMinutes /
                    60;
            _workingHoursPerWeek[week] = hours;
          }
        }
      }
    }

    setState(() {
      _loading = false;
    });
  }

  String _convertToIsoFormat(String timeStr) {
    try {
      return DateFormat('hh:mm:ss a, dd MMM yyyy')
          .parse(timeStr)
          .toIso8601String();
    } catch (_) {
      return DateTime.now().toIso8601String();
    }
  }

  String _getDayAbbreviation(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getWeekLabel(DateTime date) {
    int day = date.day;
    if (day <= 7) return 'Week 1';
    if (day <= 14) return 'Week 2';
    if (day <= 21) return 'Week 3';
    if (day <= 28) return 'Week 4';
    return 'Week 5';
  }

  List<BarChartGroupData> _buildBarGroups() {
    if (_viewMode == 'Daily') {
      return _workingHoursPerDay.entries
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
                  color: Colors.blue[800],
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          )
          .toList();
    } else {
      return _workingHoursPerWeek.entries
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
                  color: Colors.blue[800],
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          )
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Chart"),
        titleTextStyle: const TextStyle(fontSize: 22, color: Colors.white),
        backgroundColor: Colors.blue[900],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: _viewMode,
                    items: ['Daily', 'Weekly'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _viewMode = newValue!;
                        _loading = true;
                      });
                      _fetchAttendanceData();
                    },
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 12,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                return Text("${value.toInt()}h",
                                    style: TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final labels = _viewMode == 'Daily'
                                    ? [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun'
                                      ]
                                    : [
                                        'Week 1',
                                        'Week 2',
                                        'Week 3',
                                        'Week 4',
                                        'Week 5'
                                      ];
                                return Text(
                                  labels[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        barGroups: _buildBarGroups(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
