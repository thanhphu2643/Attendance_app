import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../../api.dart';

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
    final response = await http.get(Uri.parse(ApiConstants.getNhanVienUrl(widget.employeeId)));
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
        Uri.parse(ApiConstants.uploadProfilePictureUrl(widget.employeeId)),
      );

      request.files.add(await http.MultipartFile.fromPath('profile_picture', profilePicFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        _loadEmployeeDetails();
      } else {
        _showErrorDialog(context, 'Không thể tải lên ảnh đại diện.');
      }
    }
  }

  Future<void> _updateEmployeeDetails() async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.100.239:8000/api/nhanvien/${widget.employeeId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(employeeDetails),
      );

      // In ra phản hồi để kiểm tra
      print('Phản hồi từ máy chủ: ${response.body}');

      if (response.statusCode == 200) {
        // Cập nhật thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thành công!')),
        );
        _loadEmployeeDetails(); // Tải lại thông tin mới sau khi cập nhật
      } else {
        // Xử lý lỗi không phải 200
        String errorMessage = 'Có lỗi xảy ra!';

        // Kiểm tra nếu phản hồi có thể là JSON
        try {
          final Map<String, dynamic> errorResponse = jsonDecode(response.body);
          errorMessage = errorResponse['message'] ?? 'Có lỗi xảy ra!';
        } catch (e) {
          // Nếu không thể phân tích cú pháp JSON, giữ lại thông điệp mặc định
          errorMessage = 'Có lỗi xảy ra: ${response.statusCode}';
        }

        _showErrorDialog(context, errorMessage);
        print('Lỗi khi cập nhật: $errorMessage');
      }
    } catch (e) {
      // Xử lý lỗi mạng hoặc ngoại lệ
      String errorMessage = 'Có lỗi xảy ra: $e';
      _showErrorDialog(context, errorMessage);
      print('Ngoại lệ: $errorMessage');
    }
  }

  Future<void> _deleteEmployee() async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.nhanvienUrl}/${widget.employeeId}'),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa nhân viên thành công!')));
    } else {
      _showErrorDialog(context, 'Xóa nhân viên thất bại.');
    }
  }

  void _showEditDialog() {
    final controllers = {
      'Họ tên': TextEditingController(text: employeeDetails?['hoTen']),
      'Địa chỉ': TextEditingController(text: employeeDetails?['diaChi']),
      'Ngày sinh': TextEditingController(text: employeeDetails?['ngaySinh']),
      'Giới tính': TextEditingController(text: employeeDetails?['gioiTinh']),
      'Email': TextEditingController(text: employeeDetails?['email']),
      'Số điện thoại': TextEditingController(text: employeeDetails?['SDT']),
      'Ngày Bắt đầu': TextEditingController(text: employeeDetails?['ngayBatDau']),
      'Ngày Kết thúc': TextEditingController(text: employeeDetails?['ngayKetThuc']),
      'Trạng thái khuôn mặt': TextEditingController(text: employeeDetails?['trangThaiKhuonMat']),
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
                setState(() {
                  employeeDetails!['hoTen'] = controllers['Họ tên']!.text;
                  employeeDetails!['diaChi'] = controllers['Địa chỉ']!.text;
                  employeeDetails!['ngaySinh'] = controllers['Ngày sinh']!.text;
                  employeeDetails!['gioiTinh'] = controllers['Giới tính']!.text;
                  employeeDetails!['email'] = controllers['Email']!.text;
                  employeeDetails!['SDT'] = controllers['Số điện thoại']!.text;
                  employeeDetails!['ngayBatDau'] = controllers['Ngày Bắt đầu']!.text;
                  employeeDetails!['ngayKetThuc'] = controllers['Ngày Kết thúc']!.text;
                  employeeDetails!['trangThaiKhuonMat'] = controllers['Trạng thái khuôn mặt']!.text;
                });
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
          backgroundImage: employeeDetails?['IMG'] != null
              ? NetworkImage('${ApiConstants.storageUrl}/${employeeDetails!['IMG']}')
              : AssetImage('assets/img/avatar.png') as ImageProvider,
        ),
      ),
    );
  }

  Widget _buildEmployeeInfo() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildInfoRow('Họ và tên:', employeeDetails?['hoTen']),
              _buildSpacer(),
              _buildInfoRow('Địa chỉ:', employeeDetails?['diaChi']),
              _buildSpacer(),
              _buildInfoRow('Ngày sinh:', employeeDetails?['ngaySinh']),
              _buildSpacer(),
              _buildInfoRow('Giới tính:', employeeDetails?['gioiTinh']),
              _buildSpacer(),
              _buildInfoRow('Email:', employeeDetails?['email']),
              _buildSpacer(),
              _buildInfoRow('SDT:', employeeDetails?['SDT']),
              _buildSpacer(),
              _buildInfoRow('Ngày bắt đầu:', employeeDetails?['ngayBatDau']),
              _buildSpacer(),
              _buildInfoRow('Ngày kết thúc:', employeeDetails?['ngayKetThuc']),
              _buildSpacer(),
              _buildInfoRow('Trạng thái khuôn mặt:', employeeDetails?['trangThaiKhuonMat']),
              _buildSpacer(),
            ],
          ),
        ),
        SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSpacer() {
    return SizedBox(height: 10);
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(value ?? 'Không có dữ liệu'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (employeeDetails == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin nhân viên'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteEmployee,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildEmployeeHeader(),
              SizedBox(height: 20),
              _buildEmployeeInfo(),
              ElevatedButton(
                onPressed: _showEditDialog,
                child: Text('Chỉnh sửa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
