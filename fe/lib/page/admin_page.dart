import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'company_detail.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> companies = [];
  String adminName = 'Admin';
  final String apiUrl = 'http://192.168.100.239:8000/api/congty'; // Thay đổi đường dẫn đến API của bạn

  @override
  void initState() {
    super.initState();
    _loadCompanies(); // Tải danh sách công ty từ API khi khởi động
  }

  Future<void> _loadCompanies() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        companies = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      throw Exception('Không thể tải danh sách công ty');
    }
  }
  Future<void> _saveCompany(Map<String, String> company) async {
    // Chuyển đổi các trường cho phù hợp với API
    final Map<String, String> formattedCompany = {
      'tenCongTy': company['name'] ?? '',
      'diaDiem': company['location'] ?? '',
      'soDienThoai': company['phone'] ?? '',
      'email': company['email'] ?? '',
      'nguoiDaiDien': company['representative'] ?? '',
      'linhVucKinhDoanh': company['businessField'] ?? '',
      'trangThai': 'Hoạt động', // Nếu cần
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(formattedCompany),
    );

    if (response.statusCode == 200) {
      // Công ty đã được lưu thành công
      print('Company saved: ${formattedCompany['tenCongTy']}');
      _loadCompanies(); // Tải lại danh sách công ty
    } else {
      throw Exception('Không thể lưu công ty');
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
                      backgroundImage: AssetImage('assets/img/admin.png'),
                    ),
                    SizedBox(width: 10),
                    Text(adminName),
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
        body: companies.isEmpty
            ? Center(child: Text('Không có công ty nào'))
            : ListView.builder(
          itemCount: companies.length,
          itemBuilder: (context, index) {
            final company = companies[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: ListTile(
                leading: Icon(Icons.business, size: 40),
                title: Text(company['tenCongTy'] ?? 'Công ty $index'),
                subtitle: Text(company['diaDiem'] ?? 'Địa điểm chưa rõ'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  // Điều hướng đến trang chi tiết công ty và chờ kết quả
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompanyDetailPage(companyId: company['maCongTy']),
                    ),
                  );

                  // Nếu có kết quả trả về từ trang chi tiết công ty
                  if (result == true) {
                    _loadCompanies(); // Tải lại danh sách công ty
                  }
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Điều hướng đến trang tạo công ty mới và chờ kết quả
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCompanyPage(onCompanyCreated: _saveCompany),
              ),
            );

            // Nếu có công ty mới được thêm vào, load lại danh sách công ty
            if (result == true) {
              _loadCompanies(); // Tải lại danh sách công ty
            }
          },
          child: Icon(Icons.add),
          tooltip: 'Thêm công ty',
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

class AddCompanyPage extends StatefulWidget {
  final Function(Map<String, String>) onCompanyCreated;

  AddCompanyPage({required this.onCompanyCreated});

  @override
  _AddCompanyPageState createState() => _AddCompanyPageState();
}

class _AddCompanyPageState extends State<AddCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _companyData = {
    'tenCongTy': '',
    'diaDiem': '',
    'soDienThoai': '',
    'email': '',
    'nguoiDaiDien': '',
    'linhVucKinhDoanh': '',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm công ty mới'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Tên công ty', 'name'),
              _buildTextField('Địa điểm làm việc', 'location'),
              _buildTextField('Số điện thoại', 'phone', keyboardType: TextInputType.phone),
              _buildTextField('Email', 'email', keyboardType: TextInputType.emailAddress),
              _buildTextField('Người đại diện', 'representative'),
              _buildTextField('Lĩnh vực kinh doanh', 'businessField'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Lưu công ty'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập $label';
        }
        return null;
      },
      onSaved: (value) {
        if (value != null) {
          _companyData[key] = value;
        }
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onCompanyCreated(_companyData);
      Navigator.of(context).pop(true); // Trở về với kết quả thành công
    }
  }
}
