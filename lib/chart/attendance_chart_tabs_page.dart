import 'package:flutter/material.dart';
import 'attendance_chart_page.dart';
import 'attendance_pie_chart_page.dart';

class AttendanceChartTabsPage extends StatelessWidget {
  const AttendanceChartTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Tab: Bar Chart & Pie Chart
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Attendance Overview",
            style: TextStyle(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: Colors.blue[900],
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(Icons.bar_chart, size: 26),
                text: "Bar Chart",
              ),
              Tab(
                icon: Icon(Icons.pie_chart, size: 26),
                text: "Pie Chart",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AttendanceChartPage(),
            AttendancePieChartPage(),
          ],
        ),
      ),
    );
  }
}
