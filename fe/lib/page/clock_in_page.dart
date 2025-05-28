import 'package:checkin/page/quanly/manager_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api.dart';
import './attendance_page.dart';
import './settings_page.dart';
import './report_page.dart';
import './set_target.dart';
import 'Admin/admin_page.dart';

class ClockInPage extends StatefulWidget {
  @override
  _ClockInPageState createState() => _ClockInPageState();
}

class _ClockInPageState extends State<ClockInPage> {
  int _selectedIndex = 0;
  int? _maVaiTro;

  final List<Widget> _attendancePages = [
    AttendancePage(),
    ReportPage(),
    SettingsPage(),
  ];

  final List<Widget> _destinationPages = [
    ManagerPage(),
    SetTargetPage(),
    SettingsPage(),
  ];

  final List<Widget> _companyManagementPages = [
    AdminPage(),
    SettingsPage(),
  ];

  Future<void> fetchRole() async {
    // Retrieve maND from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? maND = prefs.getInt('maND');

    if (maND != null) {
      try {
        final response = await http.post(
          Uri.parse(ApiConstants.nguoidungUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'maND': maND}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _maVaiTro = data['data']['maVaiTro'];
          });
        } else {
          // Handle the error
          throw Exception('Failed to load role');
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRole();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _maVaiTro == null
          ? Center(child: CircularProgressIndicator())
          : IndexedStack(
        index: _selectedIndex,
        children: _maVaiTro == 1
            ? _companyManagementPages
            : _maVaiTro == 2
            ? _destinationPages
            : _attendancePages,
      ),
      bottomNavigationBar: _maVaiTro == null
          ? null
          : BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: _maVaiTro == 1
            ? [
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Công ty',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ]
            : _maVaiTro == 2
            ? [
          BottomNavigationBarItem(
            icon: Icon(Icons.perm_contact_calendar),
            label: 'Nhân sự',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.place),
            label: 'Vị trí',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ]
            : [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Chấm công',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
