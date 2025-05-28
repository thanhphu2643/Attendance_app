import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Import thư viện shared_preferences
import '../api.dart';
import '../page/clock_in_page.dart';
import '../page/setting/change_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorText;

  Future<void> _login() async {
    String tenTK = _usernameController.text;
    String matKhau = _passwordController.text;

    if (tenTK.isEmpty || matKhau.isEmpty) {
      setState(() {
        _errorText = "Vui lòng nhập tên đăng nhập và mật khẩu";
      });
      return;
    }

    final String url = ApiConstants.loginUrl;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'tenTK': tenTK,
          'matKhau': matKhau,
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('maND', responseData['maND']);
        await prefs.setBool('isFirstLogin', responseData['isFirstLogin'] == 1);
        bool isFirstLogin = (responseData['isFirstLogin'] == 1);
        if (isFirstLogin) {
          // Điều hướng đến trang đổi mật khẩu
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(),
            ),
          );
        } else {
          // Điều hướng đến ClockInPage nếu không phải lần đầu
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ClockInPage(),
            ),
          );
        }
      } else {
        setState(() {
          _errorText = responseData['message'] == "Incorrect tenTK or password"
              ? "tenTK hoặc Password không đúng"
              : responseData['message'] ?? 'Đăng nhập thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Request failed: $e';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/img/logo4.png', height: 100),
              const SizedBox(height: 20),
              const Text('Đăng nhập', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.blue[50],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.blue[50],
                ),
              ),
              const SizedBox(height: 10),
              if (_errorText != null)
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đăng nhập', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
