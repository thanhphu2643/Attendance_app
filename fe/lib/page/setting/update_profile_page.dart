import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Thêm thư viện image_picker
import '../../api.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class UpdateProfilePage extends StatefulWidget {
  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _address = '';
  String _phoneNumber = '';
  String _picture = '';
  DateTime? _birthDate;
  String _gender = 'Nam';
  File? _image;
  bool _isLoading = true; // Biến trạng thái để kiểm tra dữ liệu đã được tải
  String _companyName = '';
  String _companyLocation = '';
  String _companyPhone = '';
  bool _isCameraImage = false;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? maND = prefs.getInt('maND');

    if (maND != null) {
      final response = await http.post(
        Uri.parse(ApiConstants.getNguoiDungWithCompanyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'maND': maND}),
      );
      print('Nội dung phản hồi: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _name = data['data']['nguoiDung']['hoTen'] ?? '';
          _email = data['data']['nguoiDung']['email'] ?? '';
          _address = data['data']['nguoiDung']['diaChi'] ?? '';
          _phoneNumber = data['data']['nguoiDung']['SDT'] ?? '';
          _picture = data['data']['nguoiDung']['IMG'] ?? ''; // Lấy ảnh từ DB
          _gender = (data['data']['nguoiDung']['gioiTinh'] == 'Nữ') ? 'Nữ' : 'Nam'; // Mặc định là 'Nam'
          _companyName = data['data']['congTy']['tenCongTy'] ?? '';
          _companyLocation = data['data']['congTy']['diaDiem'] ?? '';
          _companyPhone = data['data']['congTy']['soDienThoai'] ?? '';
          _isLoading = false;
        });
      } else {
        // Xử lý lỗi
        print('Lỗi: ${response.body}');
        setState(() {
          _isLoading = false; // Ngay cả khi có lỗi, đánh dấu dữ liệu đã tải
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin cá nhân'),
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
      ),
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
      body: _isLoading // Kiểm tra trạng thái loading
          ? Center(child: CircularProgressIndicator()) // Hiển thị vòng tròn chờ
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _chooseImage(context),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _image != null
                            ? FileImage(_image!) // Hiển thị ảnh từ file
                            : _picture.isNotEmpty
                            ? NetworkImage('${ApiConstants.storageUrl}/$_picture') // Hiển thị ảnh từ URL
                            : AssetImage('assets/img/avatar.png') as ImageProvider, // Hiển thị ảnh mặc định
                        child: _image == null
                            ? Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    SizedBox(width: 16.0), // Khoảng cách giữa Text và Container
                    GestureDetector(
                      onTap: () => _chooseImage(context),
                      child: Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text('Tải ảnh lên', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.0),
                Text('Thông tin cá nhân', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20.0), // Tăng khoảng cách giữa tiêu đề và form
                _buildFormField(
                  label: 'Họ và tên',
                  initialValue: _name,
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
                // Hiển thị thông tin công ty
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông tin công ty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.0),
                      _buildReadOnlyField(label: 'Tên công ty', value: _companyName),
                      SizedBox(height: 8.0),
                      _buildReadOnlyField(label: 'Địa điểm', value: _companyLocation),
                      SizedBox(height: 8.0),
                      _buildReadOnlyField(label: 'Số điện thoại', value: _companyPhone),
                    ],
                  ),
                ),
                // Đặt nút cập nhật ở giữa
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _updateUserInfo(context);
                      }
                    },
                    child: Text('Cập nhật'),
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
      ),
    );
  }

  Widget _buildFormField({required String label, required String initialValue, required FormFieldSetter<String> onSaved, FormFieldValidator<String>? validator}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      initialValue: initialValue, // Hiển thị thông tin cũ
      onSaved: onSaved,
      validator: validator,
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      initialValue: value,
      readOnly: true, // Trường chỉ đọc
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      onChanged: (value) {
        setState(() {
          _gender = value!;
        });
      },
      items: [
        DropdownMenuItem(child: Text('Nam'), value: 'Nam'),
        DropdownMenuItem(child: Text('Nữ'), value: 'Nữ'),
      ],
      decoration: InputDecoration(
        labelText: 'Giới tính',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Future<File> compressImage(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception("Could not decode image");
    }
    List<int> compressedBytes = img.encodeJpg(image, quality: 85);

    // Lưu ảnh đã nén vào tệp mới
    String newFilePath = imageFile.path.replaceFirst(RegExp(r'\.[^\.]+$'), '_compressed.jpg'); // Tạo tên tệp mới
    File compressedImage = File(newFilePath)..writeAsBytesSync(compressedBytes);

    return compressedImage;
  }

  Future<void> _updateUserInfo(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? maND = prefs.getInt('maND');

    if (maND != null) {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.updateUserUrl),
      );

      // Add fields to the request
      request.fields['maND'] = maND.toString();
      request.fields['hoTen'] = _name;
      request.fields['email'] = _email;
      request.fields['diaChi'] = _address;
      request.fields['SDT'] = _phoneNumber;
      request.fields['gioiTinh'] = _gender;

      // Check and add image if present
      // Trước khi thêm hình ảnh vào yêu cầu
      if (_image != null) {
        try {
          String imgPath;

          print("Is camera image: $_isCameraImage");
          String fileExtension = path.extension(_image!.path);
          print("File extension: $fileExtension");

          // In ra kích thước hình ảnh
          print("Image size: ${await _image!.lengthSync()}");

          // Nén ảnh
          File compressedImage = await compressImage(File(_image!.path));
          imgPath = compressedImage.path;

          print("Image path after compression: $imgPath");

          // Thêm hình ảnh vào yêu cầu
          request.files.add(
            http.MultipartFile(
              'IMG',
              File(imgPath).readAsBytes().asStream(),
              await File(imgPath).length(),
              filename: path.basename(imgPath),
            ),
          );
        } catch (e) {
          print('Error processing image: $e');
        }
      }



      // Send the request
      var response = await request.send();

      // Read the response
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật thông tin thành công!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        Navigator.pop(context, true); // Go back to the previous page
      } else {
        // Print detailed error
        print('Update error: ${response.statusCode}');
        print('Response from server: $responseBody');

        // Show error message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $responseBody'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }


  Future<void> _chooseImage(BuildContext context) async {
    // Mở dialog cho phép chọn giữa camera và thư viện
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chọn ảnh từ'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Đóng hộp thoại
                _isCameraImage = true; // Đánh dấu ảnh từ camera
                final pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 600,
                ); // Chụp ảnh
                if (pickedFile != null) {
                  setState(() {
                    _image = File(pickedFile.path);
                  });
                  // Gọi hàm cập nhật sau khi chụp ảnh
                  _updateUserInfo(context);
                }
              },
              child: Text('Camera'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Đóng hộp thoại
                final pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 600,
                ); // Chọn ảnh từ thư viện
                if (pickedFile != null) {
                  setState(() {
                    _image = File(pickedFile.path);
                  });
                  // Gọi hàm cập nhật sau khi chọn ảnh
                  _updateUserInfo(context);
                }
              },
              child: Text('Thư viện'),
            ),
          ],
        );
      },
    );
  }



}
