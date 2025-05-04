import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class MyRecordPage extends StatefulWidget {
  const MyRecordPage({super.key});

  @override
  _MyRecordPageState createState() => _MyRecordPageState();
}

class _MyRecordPageState extends State<MyRecordPage> {
  User? _user;
  DatabaseReference? _attendanceRef;
  List<Map<String, String>> _allRecords = [];
  List<Map<String, String>> _filteredRecords = [];
  String _searchQuery = '';
  String _selectedStatus = 'All';
  int _selectedTabIndex = 0;

  final List<String> _statuses = ['All', 'On Time', 'Late', 'Early Departure'];
  final List<String> _tabs = ['Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _attendanceRef =
          FirebaseDatabase.instance.ref("attendance/${_user!.uid}");
      _fetchRecords();
    }
  }

  void _fetchRecords() {
    _attendanceRef?.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<String, dynamic> data =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        List<Map<String, String>> tempRecords = [];

        data.forEach((key, record) {
          tempRecords.add({
            "date": record["time"] ?? "-",
            "latitude": record["latitude"]?.toString() ?? "Unknown",
            "longitude": record["longitude"]?.toString() ?? "Unknown",
            "type": record["type"] ?? "Unknown",
            "status": record["status"] ?? "Unknown",
          });
        });

        setState(() {
          _allRecords = tempRecords;
          _applyFilters();
        });
      }
    });
  }

  void _applyFilters() {
    List<Map<String, String>> temp = _allRecords.where((record) {
      bool matchesSearch = _searchQuery.isEmpty ||
          record.values
              .any((v) => v.toLowerCase().contains(_searchQuery.toLowerCase()));
      bool matchesStatus =
          _selectedStatus == 'All' || record["status"] == _selectedStatus;
      bool matchesTab = _isInSelectedPeriod(record["date"] ?? '');
      return matchesSearch && matchesStatus && matchesTab;
    }).toList();

    setState(() {
      _filteredRecords = temp;
    });
  }

  bool _isInSelectedPeriod(String dateString) {
    try {
      DateTime date = DateFormat('hh:mm:ss a, dd MMM yyyy').parse(dateString);
      DateTime now = DateTime.now();
      if (_selectedTabIndex == 0) {
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      } else if (_selectedTabIndex == 1) {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
            date.isBefore(now.add(Duration(days: 1)));
      } else if (_selectedTabIndex == 2) {
        return date.year == now.year && date.month == now.month;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.history, size: 28, color: Colors.white),
              SizedBox(width: 10),
              Text("Attendance History",
                  style: TextStyle(fontSize: 22, color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.blue[900],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: const Color.fromARGB(255, 63, 204, 209),
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
                _applyFilters();
              });
            },
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search attendance...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _applyFilters();
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                        _applyFilters();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredRecords.isEmpty
                  ? Center(
                      child: Text("No records found",
                          style: TextStyle(color: Colors.black54)))
                  : ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: _filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = _filteredRecords[index];
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(15),
                            leading: Icon(
                              record["type"] == "Check-In"
                                  ? Icons.login
                                  : record["type"] == "Check-Out"
                                      ? Icons.logout
                                      : Icons.coffee,
                              size: 30,
                              color: record["type"] == "Check-In"
                                  ? Colors.green
                                  : record["type"] == "Check-Out"
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                            title: Text(record["date"] ?? "-",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Latitude: ${record["latitude"]}"),
                                Text("Longitude: ${record["longitude"]}"),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(record["type"] ?? "Unknown"),
                                      backgroundColor:
                                          record["type"] == "Check-In"
                                              ? Colors.green[100]
                                              : record["type"] == "Check-Out"
                                                  ? Colors.red[100]
                                                  : Colors.orange[100],
                                    ),
                                    SizedBox(width: 8),
                                    if (record["status"] != null)
                                      Chip(
                                        label: Text(record["status"] ?? ""),
                                        backgroundColor:
                                            record["status"] == "Late"
                                                ? Colors.orange[200]
                                                : record["status"] ==
                                                        "Early Departure"
                                                    ? Colors.red[200]
                                                    : Colors.green[200],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// class AttendanceChartWidget extends StatelessWidget {
//   final Map<String, Map<String, int>> attendanceSummary;
//   final bool isDarkMode;

//   const AttendanceChartWidget({
//     required this.attendanceSummary,
//     required this.isDarkMode,
//   });

//   @override
//   Widget build(BuildContext context) {
//     List<String> days = attendanceSummary.keys.toList();

//     return Card(
//       margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 5,
//       color: isDarkMode ? Colors.grey[900] : Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Attendance Overview",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: isDarkMode ? Colors.white : Colors.black,
//               ),
//             ),
//             SizedBox(height: 20),
//             AspectRatio(
//               aspectRatio: 1.7,
//               child: BarChart(
//                 BarChartData(
//                   backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
//                   gridData: FlGridData(show: false),
//                   borderData: FlBorderData(show: false),
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           if (value.toInt() < days.length) {
//                             return Text(
//                               days[value.toInt()].substring(0, 3),
//                               style: TextStyle(
//                                 color: isDarkMode ? Colors.white70 : Colors.black87,
//                                 fontSize: 10,
//                               ),
//                             );
//                           }
//                           return Text('');
//                         },
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     topTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     rightTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                   ),
//                   barGroups: days.asMap().entries.map((entry) {
//                     int index = entry.key;
//                     String day = entry.value;
//                     final summary = attendanceSummary[day]!;

//                     return BarChartGroupData(x: index, barRods: [
//                       BarChartRodData(
//                         toY: summary['OnTime']?.toDouble() ?? 0,
//                         color: Colors.green,
//                         width: 6,
//                       ),
//                       BarChartRodData(
//                         toY: summary['Late']?.toDouble() ?? 0,
//                         color: Colors.orange,
//                         width: 6,
//                       ),
//                       BarChartRodData(
//                         toY: summary['EarlyDeparture']?.toDouble() ?? 0,
//                         color: Colors.red,
//                         width: 6,
//                       ),
//                     ]);
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
