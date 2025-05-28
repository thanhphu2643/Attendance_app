import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import 'manager_form.dart';

class CompanyDetailPage extends StatefulWidget {
  final int companyId;

  CompanyDetailPage({required this.companyId});

  @override
  _CompanyDetailPageState createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage> {
  Map<String, dynamic>? companyDetails;

  @override
  void initState() {
    super.initState();
    _loadCompanyDetails();
  }

  Future<void> _loadCompanyDetails() async {
    final response = await http.get(Uri.parse('http://192.168.100.239:8000/api/congty/${widget.companyId}'));
    if (response.statusCode == 200) {
      setState(() {
        companyDetails = jsonDecode(response.body);
      });
    } else {
      // Xử lý lỗi tại đây
    }
  }

  Future<void> _uploadLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      final logoFile = File(result.files.single.path!);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.100.239:8000/api/congty/${widget.companyId}/upload-logo'),
      );

      request.files.add(await http.MultipartFile.fromPath('logo', logoFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          companyDetails!['logoUrl'] = 'URL của logo mới'; // Cập nhật URL của logo nếu cần
        });
      } else {
        // Xử lý lỗi tại đây
      }
    }
  }

  Future<void> _updateCompanyDetails(BuildContext context) async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.100.239:8000/api/congty/${widget.companyId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(companyDetails),
      );

      // In ra phản hồi để kiểm tra
      print('Phản hồi từ máy chủ: ${response.body}');

      if (response.statusCode == 200) {
        // Cập nhật thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật công ty thành công!')),
        );
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
        print('Lỗi khi cập nhật công ty: $errorMessage');
      }
    } catch (e) {
      // Xử lý lỗi mạng hoặc ngoại lệ
      String errorMessage = 'Có lỗi xảy ra: $e';
      _showErrorDialog(context, errorMessage);
      print('Ngoại lệ: $errorMessage');
    }
  }


// Hàm hiển thị dialog lỗi
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lỗi'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCompany() async {
    final response = await http.delete(
      Uri.parse('http://192.168.100.239:8000/api/congty/${widget.companyId}'),
    );

    if (response.statusCode == 200) {
      // Quay lại trang admin và yêu cầu reload danh sách công ty
      Navigator.pop(context, true);
    } else {
      // Xử lý lỗi tại đây (hiển thị thông báo lỗi cho người dùng)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Không thể xóa công ty. Vui lòng thử lại sau.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showEditOrDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lựa chọn hành động'),
          content: Text('Bạn muốn làm gì với thông tin công ty này?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditDialog();
              },
              child: Text('Sửa thông tin'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCompany();
              },
              child: Text('Xóa công ty'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController nameController =
        TextEditingController(text: companyDetails!['tenCongTy']);
        final TextEditingController locationController =
        TextEditingController(text: companyDetails!['diaDiem']);
        final TextEditingController phoneController =
        TextEditingController(text: companyDetails!['soDienThoai']);
        final TextEditingController emailController =
        TextEditingController(text: companyDetails!['email']);
        final TextEditingController representativeController =
        TextEditingController(text: companyDetails!['nguoiDaiDien']);
        final TextEditingController businessFieldController =
        TextEditingController(text: companyDetails!['linhVucKinhDoanh']);

        return AlertDialog(
          title: Text('Chỉnh sửa thông tin công ty'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Tên công ty'),
                ),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Địa điểm'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Điện thoại'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: representativeController,
                  decoration: InputDecoration(labelText: 'Người đại diện'),
                ),
                TextField(
                  controller: businessFieldController,
                  decoration: InputDecoration(labelText: 'Lĩnh vực'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  companyDetails!['tenCongTy'] = nameController.text;
                  companyDetails!['diaDiem'] = locationController.text;
                  companyDetails!['soDienThoai'] = phoneController.text;
                  companyDetails!['email'] = emailController.text;
                  companyDetails!['nguoiDaiDien'] = representativeController.text;
                  companyDetails!['linhVucKinhDoanh'] = businessFieldController.text;
                });
                _updateCompanyDetails(context);
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

  void _showLogoEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa logo'),
          content: Text('Bạn có muốn tải lên logo mới không?'),
          actions: [
            TextButton(
              onPressed: () {
                _uploadLogo();
                Navigator.of(context).pop();
              },
              child: Text('Tải lên'),
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

  // void _showAddAccountDialog() {
  //   final TextEditingController nameController = TextEditingController();
  //   final TextEditingController usernameController = TextEditingController();
  //   final TextEditingController passwordController = TextEditingController();
  //   final TextEditingController confirmPasswordController = TextEditingController();
  //
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Thêm tài khoản quản lý'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             children: [
  //               TextField(
  //                 controller: nameController,
  //                 decoration: InputDecoration(labelText: 'Họ và tên'),
  //               ),
  //               TextField(
  //                 controller: usernameController,
  //                 decoration: InputDecoration(labelText: 'Tên tài khoản'),
  //               ),
  //               TextField(
  //                 controller: passwordController,
  //                 decoration: InputDecoration(labelText: 'Mật khẩu'),
  //                 obscureText: true,
  //               ),
  //               TextField(
  //                 controller: confirmPasswordController,
  //                 decoration: InputDecoration(labelText: 'Xác nhận mật khẩu'),
  //                 obscureText: true,
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               if (passwordController.text != confirmPasswordController.text) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text('Mật khẩu không khớp')),
  //                 );
  //               } else {
  //                 _addAccount(nameController.text, usernameController.text, passwordController.text);
  //                 Navigator.of(context).pop();
  //               }
  //             },
  //             child: Text('Lưu'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Hủy'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<void> _addAccount(String name, String username, String password) async {
    final response = await http.post(
      Uri.parse('http://192.168.100.239:8000/api/congty/${widget.companyId}/accounts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      // Xử lý thành công tại đây
      setState(() {
        companyDetails!['accounts'] = companyDetails!['accounts'] ?? [];
        companyDetails!['accounts'].add({
          'name': name,
          'username': username,
        });
      });
    } else {
      // Xử lý lỗi tại đây
    }
  }

  Widget _buildCompanyHeader() {
    return GestureDetector(
      onTap: _showLogoEditDialog,
      child: CircleAvatar(
        radius: 50,
        backgroundImage: companyDetails!['logoUrl'] != null
            ? NetworkImage(companyDetails!['logoUrl'])
            : NetworkImage('https://via.placeholder.com/150'),
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return GestureDetector(
      onTap: _showEditOrDeleteDialog,
      child: Container(
        width: double.infinity, // Đảm bảo chiều rộng là toàn bộ không gian có sẵn
        child: Card(
          elevation: 4,
          margin: EdgeInsets.all(4), // Thêm margin bên ngoài card là 1 pixel
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Căn trái nội dung
              children: [
                Text('Tên công ty: ${companyDetails!['tenCongTy']}', style: TextStyle(fontSize: 16)), // Thêm style cho Text
                Text('Địa điểm: ${companyDetails!['diaDiem']}', style: TextStyle(fontSize: 16)), // Thêm style cho Text
                Text('Điện thoại: ${companyDetails!['soDienThoai']}', style: TextStyle(fontSize: 16)), // Thêm style cho Text
                Text('Email: ${companyDetails!['email']}', style: TextStyle(fontSize: 16)), // Thêm style cho Text
                Text('Người đại diện: ${companyDetails!['nguoiDaiDien']}', style: TextStyle(fontSize: 16)), // Thêm style cho Text
                Text('Lĩnh vực: ${companyDetails!['linhVucKinhDoanh']}', style: TextStyle(fontSize: 16)), // Thêm style cho Text
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildManager() {
    return GestureDetector(
      child: Container(
        width: double.infinity, // Đảm bảo chiều rộng là toàn bộ không gian có sẵn
        child: Card(
          elevation: 4,
          margin: EdgeInsets.all(4), // Loại bỏ khoảng cách bên ngoài card
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Căn trái nội dung
              children: [
                Text(
                  'Tên tài khoản quản lý: ${companyDetails!['nguoiDaiDien']}',
                  style: TextStyle(fontSize: 16), // Thay đổi kích thước chữ nếu cần
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAccountsList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: companyDetails!['accounts']?.length ?? 0,
      itemBuilder: (context, index) {
        final account = companyDetails!['accounts'][index];
        return ListTile(
          title: Text(account['name']),
          subtitle: Text(account['username']),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (companyDetails == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Thông tin công ty')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin công ty'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCompanyHeader(),
            SizedBox(height: 16),
            _buildCompanyInfo(),
            SizedBox(height: 16),
            _buildManager(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManagerFormPage()), // Điều hướng tới trang ManagerFormPage
                );
              },
              child: Text('Thêm tài khoản quản lý'),
            ),
          ],
        ),
      ),
    );
  }
}
