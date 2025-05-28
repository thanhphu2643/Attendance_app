import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'employee_detail.dart'; // Đảm bảo bạn đã tạo trang EmployeeDetailPage
import 'manager_form.dart'; // Trang manager_form.dart đã chỉnh sửa

class ManagerPage extends StatefulWidget {
  @override
  _ManagerPageState createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  List<Map<String, dynamic>> employees = [];
  String managerName = 'Manager';
  final String apiUrl = 'http://192.168.100.239:8000/api/nhanvien'; // Đổi URL API của bạn

  @override
  void initState() {
    super.initState();
    _loadEmployees(); // Tải danh sách nhân viên từ API khi khởi động
  }

  Future<void> _loadEmployees() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        employees = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      throw Exception('Không thể tải danh sách nhân viên');
    }
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
                  // Điều hướng đến trang chi tiết nhân viên và chờ kết quả
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EmployeeDetailPage(employeeId: employee['maND']),
                    ),
                  );

                  // Nếu có kết quả trả về từ trang chi tiết nhân viên
                  if (result == true) {
                    _loadEmployees(); // Tải lại danh sách nhân viên
                  }
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Điều hướng đến trang ManagerFormPage
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManagerFormPage(),
              ),
            );
          },
          child: Icon(Icons.add),
          tooltip: 'Thêm nhân viên',
        ),
      ),
    );
  }

  void _changeAvatar() {
    // Hàm thay đổi ảnh đại diện
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
    // Hàm đăng xuất
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
                Navigator.of(context).pop(); // Đóng dialog
                // Thực hiện đăng xuất, ví dụ: Navigator.pop(context)
              },
            ),
          ],
        );
      },
    );
  }
}
