import 'package:checkin/page/setting/change_password.dart';
import 'package:checkin/page/setting/update_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api.dart'; // Đảm bảo bạn đã import ApiConstants
import '../auth/login.dart';
import 'setting/face_id_setup.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _hoTen;
  String? _diaChi;
  String? _ngaySinh;
  String? _gioiTinh;
  String? _email;
  String? _SDT;
  bool _isFaceIDEnabled = false;
  int? _maVaiTro;
  @override
  void initState() {
    super.initState();
    _getUserInfo(); // Lấy thông tin người dùng
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
        setState(() {
          _hoTen = data['data']['hoTen'];
          _diaChi = data['data']['diaChi'];
          _ngaySinh = data['data']['ngaySinh'];
          _gioiTinh = data['data']['gioiTinh'];
          _email = data['data']['email'];
          _SDT = data['data']['SDT'];
          _isFaceIDEnabled = data['data']['trangThaiKhuonMat'] == 1;
          _maVaiTro = data['data']['maVaiTro'];
        });
      } else {
        // Xử lý lỗi
        print('Lỗi: ${response.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
        title: Row(
          children: [
            Icon(Icons.settings), // Biểu tượng cài đặt
            SizedBox(width: 8),    // Khoảng cách giữa icon và chữ
            Text(
              'Cài đặt',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Chữ đậm
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // Thông tin cá nhân
          _buildSectionHeader('Thông tin cá nhân'),
          ListTile(
            leading: Icon(Icons.person),
            title: Text(' ${_hoTen ?? 'Chưa có thông tin'}'),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text(' ${_email ?? 'Chưa có thông tin'}'),
          ),
          ListTile(
            leading: Icon(Icons.phone),
            title: Text(' ${_SDT ?? 'Chưa có thông tin'}'),
          ),
          ListTile(
            leading: Icon(Icons.perm_contact_calendar_outlined), // Thay đổi icon
            title: Text('Cập nhật thông tin cá nhân'), // Thay đổi tiêu đề
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateProfilePage()), // Chuyển qua trang cập nhật thông tin
              );
            },
          ),
          Divider(),

          // Đổi mật khẩu
          _buildSectionHeader('Đổi mật khẩu'),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Đổi mật khẩu'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordScreen()), // Điều hướng đến ChangePasswordScreen
              );
            },
          ),
          Divider(),

          // Thiết lập nhận diện khuôn mặt (hiển thị nếu maVaiTro == 3)
          if (_maVaiTro == 3) ...[
            _buildSectionHeader('Cài đặt khuôn mặt'),
            ListTile(
              leading: Icon(Icons.face),
              title: Text('Thiết lập khuôn mặt'),
              trailing: Switch(
                value: _isFaceIDEnabled,
                onChanged: _isFaceIDEnabled ? (bool value) async {
                  setState(() {
                    _isFaceIDEnabled = value;
                  });

                  // Lưu trạng thái mới vào SharedPreferences
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('trangThaiKhuonMat', value ? 1 : 0);
                } : null,
              ),
              onTap: () {
                // Điều hướng đến trang cài đặt FaceID
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FaceIDSetupScreen()),
                );
              },
            ),
            Divider(),
          ],

          // Các cài đặt khác
          _buildSectionHeader('Cài đặt khác'),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Thông báo'),
            trailing: Switch(
              value: true,
              onChanged: (bool value) {
                // Thay đổi trạng thái của thông báo
              },
            ),
          ),

          Divider(),

          // Đăng xuất
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Đăng xuất'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}
