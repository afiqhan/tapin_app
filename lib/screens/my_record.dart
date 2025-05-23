import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void _showRemarkDialog(String recordKey, String recordDate) async {
    TextEditingController remarkController = TextEditingController();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedRemark = prefs.getString('remark_$recordDate');
    if (savedRemark != null) remarkController.text = savedRemark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.edit_note, color: Colors.orange),
              SizedBox(width: 8),
              Text('Sebab Lewat'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sila nyatakan sebab anda lewat hari ini:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Hujan lebat, jem teruk, masalah kereta...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Simpan'),
              onPressed: () async {
                final remark = remarkController.text.trim();
                if (remark.isNotEmpty) {
                  // Simpan ke Firebase
                  await _attendanceRef!
                      .child(recordKey)
                      .update({'remark': remark});
                  // Simpan ke local storage
                  await prefs.setString('remark_$recordDate', remark);

                  Navigator.pop(context);
                  // Optional: paparkan mesej berjaya
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sebab Lewat telah disimpan.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _fetchRecords() {
    _attendanceRef?.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<String, dynamic> data =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        List<Map<String, String>> tempRecords = [];

        data.forEach((key, record) {
          tempRecords.add({
            "key": key, // ← inilah yang hilang
            "date": record["time"] ?? "-",
            "latitude": record["latitude"]?.toString() ?? "Unknown",
            "longitude": record["longitude"]?.toString() ?? "Unknown",
            "type": record["type"] ?? "Unknown",
            "status": record["status"] ?? "Unknown",
            "remark": record["remark"] ?? "",
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
                          child: record["type"] == "Check-Out"
                              ? ExpansionTile(
                                  tilePadding: EdgeInsets.all(15),
                                  leading: Icon(Icons.logout,
                                      size: 30, color: Colors.red),
                                  title: Text(
                                    record["date"] ?? "-",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Latitude: ${record["latitude"]}"),
                                      Text("Longitude: ${record["longitude"]}"),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Chip(
                                              label: Text("Check-Out"),
                                              backgroundColor: Colors.red[100]),
                                          SizedBox(width: 8),
                                          Chip(
                                            label: Text(record["status"] ?? ""),
                                            backgroundColor: Colors.green[200],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16.0, right: 16.0, bottom: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Divider(),
                                          Row(
                                            children: [
                                              Icon(Icons.timer_outlined,
                                                  size: 18,
                                                  color: Colors.grey[700]),
                                              SizedBox(width: 8),
                                              Text(
                                                  "Working Hours: ${record["working_hours"] ?? '-'}"),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.straighten,
                                                  size: 18,
                                                  color: Colors.grey[700]),
                                              SizedBox(width: 8),
                                              Text(
                                                  "Distance: ${record["distance"] ?? '-'}"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListTile(
                                  contentPadding: EdgeInsets.all(15),
                                  leading: Icon(Icons.login,
                                      size: 30, color: Colors.green),
                                  title: Text(
                                    record["date"] ?? "-",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if ((record["status"] == "Late") &&
                                          (record["remark"] == null ||
                                              record["remark"]!.isEmpty))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: TextButton.icon(
                                            icon: Icon(Icons.edit,
                                                size: 18, color: Colors.purple),
                                            label: Text("Tambah Sebab Lewat",
                                                style: TextStyle(
                                                    color: Colors.purple)),
                                            onPressed: () {
                                              _showRemarkDialog(record["key"]!,
                                                  record["date"]!);
                                            },
                                          ),
                                        ),
                                      Text("Latitude: ${record["latitude"]}"),
                                      Text("Longitude: ${record["longitude"]}"),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Chip(
                                              label: Text("Check-In"),
                                              backgroundColor:
                                                  Colors.green[100]),
                                          SizedBox(width: 8),
                                          Chip(
                                            label: Text(record["status"] ?? ""),
                                            backgroundColor: Colors.orange[200],
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
