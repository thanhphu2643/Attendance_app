import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class EmployeeDetailPage extends StatefulWidget {
  final int employeeId;

  EmployeeDetailPage({required this.employeeId});

  @override
  _EmployeeDetailPageState createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  Map<String, dynamic>? employeeDetails;

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    final response = await http.get(Uri.parse('http://192.168.100.239:8000/api/nhanvien/${widget.employeeId}'));
    if (response.statusCode == 200) {
      setState(() {
        employeeDetails = jsonDecode(response.body);
      });
    } else {
      _showErrorDialog(context, 'Không thể tải chi tiết nhân viên.');
    }
  }

  Future<void> _uploadProfilePicture() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      final profilePicFile = File(result.files.single.path!);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.100.239:8000/api/nhanvien/${widget.employeeId}/upload-profile-picture'),
      );

      request.files.add(await http.MultipartFile.fromPath('profile_picture', profilePicFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        _loadEmployeeDetails(); // Cập nhật thông tin sau khi tải lên ảnh mới
      } else {
        _showErrorDialog(context, 'Không thể tải lên ảnh đại diện.');
      }
    }
  }

  Future<void> _updateEmployeeDetails() async {
    final response = await http.put(
      Uri.parse('http://192.168.100.239:8000/api/nhanvien/${widget.employeeId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(employeeDetails),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật thành công!')));
    } else {
      _showErrorDialog(context, 'Cập nhật thất bại.');
    }
  }

  Future<void> _deleteEmployee() async {
    final response = await http.delete(
      Uri.parse('http://192.168.100.239:8000/api/nhanvien/${widget.employeeId}'),
    );

    if (response.statusCode == 200) {
      // Quay lại trang trước và tải lại danh sách nhân viên
      Navigator.pop(context, true); // Truyền giá trị true để thông báo rằng có thay đổi

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa nhân viên thành công!')),
      );
    } else {
      _showErrorDialog(context, 'Xóa nhân viên thất bại.');
    }
  }

  void _showEditDialog() {
    final controllers = {
      'hoTen': TextEditingController(text: employeeDetails?['hoTen']),
      'diaChi': TextEditingController(text: employeeDetails?['diaChi']),
      'ngaySinh': TextEditingController(text: employeeDetails?['ngaySinh']),
      'gioiTinh': TextEditingController(text: employeeDetails?['gioiTinh']),
      'email': TextEditingController(text: employeeDetails?['email']),
      'SDT': TextEditingController(text: employeeDetails?['SDT']),
      'ngayBatDau': TextEditingController(text: employeeDetails?['ngayBatDau']),
      'ngayKetThuc': TextEditingController(text: employeeDetails?['ngayKetThuc']),
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa thông tin nhân viên'),
          content: SingleChildScrollView(
            child: Column(
              children: controllers.entries.map((entry) {
                return TextField(
                  controller: entry.value,
                  decoration: InputDecoration(labelText: entry.key),
                  onChanged: (value) {
                    employeeDetails![entry.key] = value;
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateEmployeeDetails();
                Navigator.of(context).pop();
              },
              child: Text('Lưu'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeHeader() {
    return Center(
      child: GestureDetector(
        onTap: _uploadProfilePicture,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: employeeDetails?['profilePictureUrl'] != null
              ? NetworkImage(employeeDetails!['profilePictureUrl'])
              : NetworkImage('https://via.placeholder.com/150'),
        ),
      ),
    );
  }

  Widget _buildEmployeeInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Họ và tên: ${employeeDetails?['hoTen'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('Địa chỉ: ${employeeDetails?['diaChi'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('Ngày sinh: ${employeeDetails?['ngaySinh'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('Giới tính: ${employeeDetails?['gioiTinh'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('Email: ${employeeDetails?['email'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('SDT: ${employeeDetails?['SDT'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('Ngày bắt đầu: ${employeeDetails?['ngayBatDau'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('Ngày kết thúc: ${employeeDetails?['ngayKetThuc'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('Trạng thái khuôn mặt: ${employeeDetails?['trangThaiKhuonMat'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('Mã vai trò: ${employeeDetails?['maVaiTro'] ?? ''}', style: TextStyle(fontSize: 16)),
          Text('Mã công ty: ${employeeDetails?['maCongTy'] ?? ''}', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (employeeDetails == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Chi tiết nhân viên')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết nhân viên'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _deleteEmployee();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
            _buildEmployeeHeader(),
            SizedBox(height: 16),
            _buildEmployeeInfo(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEditDialog,
        child: Icon(Icons.edit),
      ),
    );
  }
}
