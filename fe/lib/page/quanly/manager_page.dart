import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import 'employee_detail.dart';
import 'employee_form.dart';

class ManagerPage extends StatefulWidget {
  @override
  _ManagerPageState createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  List<Map<String, dynamic>> employees = [];
  String managerName = 'Manager';
  int? _maCongTy;

  @override
  void initState() {
    super.initState();
    fetchRole(); // Lấy mã công ty của quản lý
  }

  Future<void> fetchRole() async {
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
            _maCongTy = data['data']['maCongTy'];
          });
          _loadEmployees(); // Sau khi có mã công ty, tải danh sách nhân viên
        } else {
          throw Exception('Failed to load');
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  Future<void> _loadEmployees() async {
    if (_maCongTy == null) return;

    final String apiUrl = 'http://192.168.100.239:8000/api/nhanviencongty/$_maCongTy';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true && responseData['data'] != null) {
        setState(() {
          employees = List<Map<String, dynamic>>.from(responseData['data']);
        });
      } else {
        setState(() {
          employees = [];
        });
        throw Exception('Không có nhân viên nào được tìm thấy');
      }
    } else {
      throw Exception('Không thể tải danh sách nhân viên');
    }
  }


  void _navigateToAddEmployee() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagerFormPage(companyId: _maCongTy ?? 1),
      ),
    );
    _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFFFA726),
          title: Row(
            children: [
              GestureDetector(
                onTap: _changeAvatar,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/img/manager.png'),
                    ),
                    SizedBox(width: 10),
                    Text(managerName),
                  ],
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
        ),
        body: employees.isEmpty
            ? Center(child: Text('Không có nhân viên nào'))
            : ListView.builder(
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: ListTile(
                leading: Icon(Icons.person, size: 40),
                title: Text(employee['hoTen'] ?? 'Nhân viên $index'),
                subtitle: Text(employee['chucVu'] ?? 'Nhân viên'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EmployeeDetailPage(employeeId: employee['maND']),
                    ),
                  );

                  if (result == true) {
                    _loadEmployees();
                  }
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await fetchRole();
            _navigateToAddEmployee();
          },
          child: Icon(Icons.add),
          tooltip: 'Thêm nhân viên',
        ),
      ),
    );
  }

  void _changeAvatar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chọn ảnh đại diện'),
          content: Text('Tính năng thay đổi ảnh đại diện ở đây'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đăng xuất'),
          content: Text('Bạn có chắc muốn đăng xuất?'),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Đăng xuất'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
