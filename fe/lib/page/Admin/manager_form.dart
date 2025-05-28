import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ManagerFormPage extends StatefulWidget {
  final int companyId;

  ManagerFormPage({required this.companyId});

  @override
  _ManagerFormPageState createState() => _ManagerFormPageState();
}

class _ManagerFormPageState extends State<ManagerFormPage> {
  final _formKeyUser = GlobalKey<FormState>();
  final TextEditingController _ngaySinhController = TextEditingController(); // Khởi tạo controller cho ngày sinh

  // Thông tin người dùng
  String _name = '';
  String _email = 'default@example.com';
  String _address = '123 Đường ABC, Thành phố XYZ';
  String _phoneNumber = '0123456789';
  String _gender = 'Nam';
  String _ngaySinh = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Nếu _ngaySinh không rỗng, cập nhật giá trị cho TextEditingController
    if (_ngaySinh.isNotEmpty) {
      _ngaySinhController.text = DateFormat('yyyy-MM-dd').format(DateTime.parse(_ngaySinh));
    }
  }

  @override
  void dispose() {
    _ngaySinhController.dispose(); // Giải phóng controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm người dùng mới'),
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thông tin người dùng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Form(
                key: _formKeyUser,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormField(
                      label: 'Họ và tên',
                      onSaved: (value) {
                        _name = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    _buildFormField(
                      label: 'Email',
                      initialValue: _email,
                      onSaved: (value) {
                        _email = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                          return 'Vui lòng nhập email hợp lệ';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    _buildFormField(
                      label: 'Địa chỉ',
                      initialValue: _address,
                      onSaved: (value) {
                        _address = value!;
                      },
                    ),
                    SizedBox(height: 16.0),
                    _buildFormField(
                      label: 'Số điện thoại',
                      initialValue: _phoneNumber,
                      onSaved: (value) {
                        _phoneNumber = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    _buildGenderDropdown(),
                    SizedBox(height: 16.0),
                    _buildDateField(
                      label: 'Ngày sinh',
                      onSaved: (value) {
                        _ngaySinh = value!;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveInformation,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Lưu Thông Tin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFA726),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required FormFieldSetter<String> onSaved, FormFieldValidator<String>? validator, bool obscureText = false, String? initialValue}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      onSaved: onSaved,
      validator: validator,
      obscureText: obscureText,
      initialValue: initialValue,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Giới tính',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Nam', 'Nữ'].map((gender) {
        return DropdownMenuItem<String>(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _gender = value!;
        });
      },
    );
  }

  Widget _buildDateField({required String label, required FormFieldSetter<String> onSaved}) {
    return TextFormField(
      controller: _ngaySinhController, // Sử dụng controller
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      readOnly: true,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: _ngaySinh.isNotEmpty ? DateTime.parse(_ngaySinh) : DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          // Cập nhật giá trị ngày sinh
          setState(() {
            _ngaySinh = DateFormat('yyyy-MM-dd').format(pickedDate); // Lưu vào biến _ngaySinh
            _ngaySinhController.text = _ngaySinh; // Cập nhật giá trị cho controller
          });
          // Cập nhật giá trị hiển thị trong trường
          onSaved(_ngaySinh); // Gọi onSaved để lưu giá trị vào form
        }
      },
    );
  }

  Future<void> _saveInformation() async {
    if (_formKeyUser.currentState!.validate()) {
      _formKeyUser.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      // Data to send to the API, including maCongTy (companyId)
      Map<String, String> requestBody = {
        'hoTen': _name,
        'email': _email,
        'diaChi': _address,
        'SDT': _phoneNumber,
        'gioiTinh': _gender,
        'ngaySinh': _ngaySinh,
        'maCongTy': widget.companyId.toString(), // Add maCongTy here
      };

      try {
        final response = await http.post(
          Uri.parse('http://192.168.100.239:8000/api/quanly'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 201) {
          // Success: handle accordingly
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thêm người dùng thành công')),
          );
          // Quay lại trang trước đó và gửi tín hiệu reload danh sách
          Navigator.pop(
              context, true); // Trả về giá trị true để báo hiệu thành công
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: Không thể thêm người dùng')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
