import 'package:checkin/page/Admin/admin_page.dart';
import 'package:checkin/page/attendance_page.dart';
import 'package:flutter/material.dart';
import '../page/clock_in_page.dart';
import 'auth/login.dart';

void main() {
  runApp(ChamCongApp());
}

class ChamCongApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chấm Công',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home:  LoginScreen(),
    );
  }
}

