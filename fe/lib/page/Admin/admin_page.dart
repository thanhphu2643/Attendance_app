import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';
import 'company_detail.dart'; // Đảm bảo bạn đã tạo trang CompanyDetailPage

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> companies = [];
  String searchQuery = '';
  String _hoVaTen = 'Chưa có thông tin';
  String? _imgUrl;

  final String apiUrl = 'http://192.168.100.239:8000/api/congty';

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _getUserInfo();
  }
  Future<void> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? maND = prefs.getInt('maND'); // Lấy maND từ SharedPreferences

    if (maND != null) {
      final response = await http.post(
        Uri.parse(ApiConstants.nguoidungUrl), // Sử dụng ApiConstants
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'maND': maND}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Kiểm tra xem dữ liệu có hợp lệ không
        if (data['data'] != null) {
          setState(() {
            _hoVaTen = data['data']['hoTen'] ?? 'Chưa có thông tin';
            _imgUrl = data['data']['IMG'] != null && data['data']['IMG'].isNotEmpty
                ? '${ApiConstants.storageUrl}/${data['data']['IMG']}'
                : 'assets/img/avatar.png';
          });
        } else {
          setState(() {
            _hoVaTen = 'Không tìm thấy thông tin người dùng';
          });
        }
      } else {
        // Xử lý lỗi từ API
        print('Lỗi: ${response.body}');
        setState(() {
          _hoVaTen = 'Không tìm thấy thông tin người dùng';
        });
      }
    } else {
      // Nếu không có maND trong SharedPreferences
      setState(() {
        _hoVaTen = 'Không tìm thấy thông tin người dùng';
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 100,
          elevation: 0.5,
          backgroundColor: Color.fromARGB(255, 245, 245, 245),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _imgUrl != null &&
                      _imgUrl!.isNotEmpty &&
                      _imgUrl!.startsWith('http')
                      ? NetworkImage(_imgUrl!) // Sử dụng NetworkImage cho URL
                      : AssetImage('assets/img/avatar.png') as ImageProvider,
                ),
                SizedBox(width: 16),
                Expanded( // Thêm Expanded để kéo dài không gian
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      Text(
                        _hoVaTen ?? '...',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {}, // Thêm hành động cho biểu tượng thông báo nếu cần
                  icon: Icon(Icons.notifications, color: Colors.black),
                ),
              ],
            ),

          ),
        body: Container(
          color: Color.fromARGB(255, 245, 245, 245), // Màu trắng cho body
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Thêm khoảng cách giữa AppBar và ô tìm kiếm
              SizedBox(height: 20), // Điều chỉnh giá trị này để tăng khoảng cách
              Container(
                margin: EdgeInsets.only(bottom: 16.0),
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Màu xám nhẹ cho ô tìm kiếm
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: 'Tìm công ty...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              Row(
                children: [
                  Icon(Icons.list),
                  SizedBox(width: 8.0),
                  Text(
                    'Danh sách công ty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10), // Khoảng cách giữa tiêu đề và danh sách công ty
              Expanded(
                child: companies.isEmpty
                    ? Center(child: Text('Không có công ty nào'))
                    : ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final company = companies[index];

                    // Kiểm tra nếu tên công ty chứa chuỗi tìm kiếm
                    if (searchQuery.isNotEmpty &&
                        !company['tenCongTy'].toLowerCase().contains(searchQuery.toLowerCase())) {
                      return Container(); // Ẩn công ty không khớp
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        leading: Icon(Icons.business_sharp, size: 40),
                        title: Text(company['tenCongTy'] ?? 'Công ty $index'),
                        subtitle: Text(company['diaDiem'] != null && company['diaDiem'].isNotEmpty
                            ? company['diaDiem']
                            : ''), // Không hiển thị 'Địa chỉ không xác định'
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          // Điều hướng đến trang chi tiết công ty
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompanyDetailPage(companyId: company['maCongTy']),
                            ),
                          );
                          _loadCompanies(); // Tải lại danh sách công ty nếu cần
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
          backgroundColor: Color(0xFFFFA726),
        ),
      ),
    );
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
      'trangThai': 'Hoạt động',
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
}

// AddCompanyPage tương tự như AddEmployeePage
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
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
        title: Text('Thêm công ty mới'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Tên công ty', 'name'),
              SizedBox(height: 16), // Khoảng cách giữa các trường
              _buildTextField('Địa chỉ', 'location'),
              SizedBox(height: 16), // Khoảng cách giữa các trường
              _buildTextField('Số điện thoại', 'phone', keyboardType: TextInputType.phone),
              SizedBox(height: 16), // Khoảng cách giữa các trường
              _buildTextField('Email', 'email', keyboardType: TextInputType.emailAddress),
              SizedBox(height: 16), // Khoảng cách giữa các trường
              _buildTextField('Người đại diện', 'representative'),
              SizedBox(height: 16), // Khoảng cách giữa các trường
              _buildTextField('Lĩnh vực kinh doanh', 'businessField'),
              SizedBox(height: 20), // Khoảng cách trước nút lưu
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Lưu công ty'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFFFFA726), // Màu chữ của nút
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0), // Padding lớn hơn
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Giảm độ bo góc
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTextField(String label, String key,{TextInputType? keyboardType}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
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
      widget.onCompanyCreated(_companyData); // Gọi hàm tạo công ty
      Navigator.pop(context, true); // Đóng trang và trả về kết quả
    }
  }
}
