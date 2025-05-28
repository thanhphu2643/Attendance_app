import 'package:checkin/page/clock_in_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api.dart';

class ChangePasswordScreen extends StatelessWidget {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đổi mật khẩu'),
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
      ),
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
      body: FutureBuilder<bool>(
        future: _isFirstLogin(), // Gọi phương thức bất đồng bộ
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Có lỗi xảy ra.'));
          } else if (snapshot.hasData) {
            bool isFirstLogin = snapshot.data!;
            return _buildChangePasswordForm(context, isFirstLogin);
          } else {
            return Center(child: Text('Không tìm thấy dữ liệu.'));
          }
        },
      ),
    );
  }

  Widget _buildChangePasswordForm(BuildContext context, bool isFirstLogin) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(controller: _oldPasswordController, labelText: 'Mật khẩu cũ', icon: Icons.lock),
              _buildTextField(controller: _newPasswordController, labelText: 'Mật khẩu mới', icon: Icons.lock),
              _buildTextField(controller: _confirmPasswordController, labelText: 'Nhập lại mật khẩu mới', icon: Icons.lock),
              SizedBox(height: 16),
              Text('Mật khẩu phải thỏa mãn các điều kiện sau:', style: TextStyle(color: Colors.black54)),
              _buildPasswordRequirements(),
              Spacer(),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_validatePassword(context)) {
                        await _changePassword(context, isFirstLogin);
                      }
                    },
                    child: Text('Đổi mật khẩu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFA726),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      textStyle: TextStyle(fontSize: 16, color: Colors.white),
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

  Future<bool> _isFirstLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstLogin') ?? false; // Sử dụng getBool
  }


  Widget _buildTextField({required TextEditingController controller, required String labelText, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Color(0xFFFFA726)),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFA726)),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFFE9F7FE),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('- Có độ dài từ 8 đến 20 ký tự.'),
          Text('- Chứa ít nhất 01 ký tự số, 01 ký tự chữ, 01 ký tự đặc biệt.'),
          Text('Ví dụ: B@123456; 123456@D; 121512V@'),
        ],
      ),
    );
  }

  bool _validatePassword(BuildContext context) {
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mật khẩu mới và mật khẩu xác nhận không khớp.')),
      );
      return false;
    }

    if (newPassword.length < 8 || newPassword.length > 20 ||
        !RegExp(r'[0-9]').hasMatch(newPassword) ||
        !RegExp(r'[A-Za-z]').hasMatch(newPassword) ||
        !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mật khẩu không thỏa mãn các điều kiện.')),
      );
      return false;
    }

    return true;
  }

  Future<void> _changePassword(BuildContext context, bool isFirstLogin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? maND = prefs.getInt('maND');

    if (maND != null) {
      final response = await http.post(
        Uri.parse(ApiConstants.doimatkhauUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'maND': maND,
          'matKhauCu': _oldPasswordController.text,
          'matKhauMoi': _newPasswordController.text,
          'matKhauMoi_confirmation': _confirmPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đổi mật khẩu thành công.')),
        );

        if (isFirstLogin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => ClockInPage()),
          );
        } else {
          Navigator.of(context).pop();
        }
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Đã xảy ra lỗi.')),
        );
      }
    }
  }
}
