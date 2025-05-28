import 'dart:async'; // Thêm thư viện này để sử dụng Timer
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

void main() {
  runApp(FaceRecognitionApp());
}

class FaceRecognitionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chấm công',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: FaceRecognitionScreen(
        onSuccess: (bool success) {
          // Callback để xử lý khi chấm công thành công
          if (success) {
            // Lấy dữ liệu mới cho trang Report
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FaceRecognitionScreen extends StatefulWidget {
  final Function(bool) onSuccess; // Thêm callback

  FaceRecognitionScreen({required this.onSuccess});

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  final picker = ImagePicker();
  String recognizedName = "Unknown";
  int? maND;
  Timer? _timer; // Timer để kiểm tra thời gian chờ

  @override
  void initState() {
    super.initState();
    getMaNDFromPreferences(); // Lấy maND từ SharedPreferences khi bắt đầu
    getImage(); // Gọi hàm getImage ngay khi vào trang
  }

  // Hàm lấy maND từ SharedPreferences
  Future<void> getMaNDFromPreferences() async {
    maND = await getMaNDFromSharedPreferences();
  }

  // Hàm lấy maND từ SharedPreferences
  Future<int?> getMaNDFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('maND');
  }

  // Hàm chụp ảnh bằng camera
  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      uploadImage(File(pickedFile.path));
    } else {
      print('No image selected.');
      // Nếu không có ảnh, quay lại màn hình chính
      Navigator.pop(context);
    }
  }

  // Hàm upload ảnh lên server Python để nhận diện
  Future<void> uploadImage(File image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.recognizeUrl),
    );
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    // Khởi tạo timer để kiểm tra thời gian chờ
    _timer = Timer(Duration(seconds: 15), () {
      // Nếu quá 15 giây mà không nhận được phản hồi, hiển thị thông báo
      showDialogMessage({"message": "Chấm công thất bại! Vui lòng thử lại."}, false, "Chấm công thất bại!");
      Navigator.pop(context); // Quay lại màn hình chính
    });

    try {
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      var result = jsonDecode(responseData.body);

      // Hủy timer nếu nhận được phản hồi
      _timer?.cancel();

      // Kiểm tra thông báo từ API
      if (response.statusCode == 200 && result['message'] != "Không nhận diện được khuôn mặt") {
        recognizedName = result['name'];
        // Kiểm tra tên đã nhận diện có khớp với mã nhân viên
        if (recognizedName == maND.toString()) {
          await sendChamCong(maND!); // Gọi API chấm công nếu khớp
        } else {
          showDialogMessage({"message": "Nhân viên không đúng \n Vui lòng thử lại!"}, false, "Nhân viên không đúng \n Vui lòng thử lại!"); // Thông báo thất bại
        }
      } else {
        // Nếu nhận thông báo không nhận diện được khuôn mặt
        showDialogMessage({"message": "Chấm công thất bại! Không nhận diện được khuôn mặt."}, false, "Chấm công thất bại!");
      }
    } catch (e) {
      print('Lỗi khi gửi yêu cầu: $e');
      showDialogMessage({"message": "Chấm công thất bại! Lỗi kết nối."}, false, "Chấm công thất bại!");
    }
  }

  // Hàm gửi yêu cầu chấm công tới API Laravel
  Future<void> sendChamCong(int maND) async {
    var response = await http.post(
      Uri.parse(ApiConstants.chamCongUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'maND': maND}),
    );

    String errorMessage; // Khai báo biến để lưu thông báo lỗi

    if (response.statusCode == 200) {
      print("Chấm công thành công");
      widget.onSuccess(true);
      showDialogMessage({"message": "Chấm công thành công!"}, true, ""); // Hiện thông báo thành công
    } else {
      print("Chấm công thất bại");
      try {
        final Map<String, dynamic> errorResponse = jsonDecode(response.body);
        errorMessage = errorResponse['message'] ?? "Chấm công thất bại!";
      } catch (e) {
        errorMessage = "Chấm công thất bại!";
      }
      showDialogMessage({"message": errorMessage}, false, errorMessage); // Hiện thông báo lỗi
    }
  }

  // Hàm hiện thông báo
  void showDialogMessage(Map<String, dynamic> result, bool isSuccess, String detailMessage) {
    String message;
    IconData dialogIcon;

    if (isSuccess) {
      message = "Chấm công thành công!";
      dialogIcon = Icons.check_circle;
      detailMessage = "Đã chấm công thành công vào lúc ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} ngày: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    } else {
      message = "Chấm công thất bại!";
      dialogIcon = Icons.error;
      // Nếu không có thông tin chi tiết, hiển thị thông báo mặc định
      if (detailMessage.isEmpty) {
        detailMessage = "Vui lòng thử lại!";
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(dialogIcon, color: isSuccess ? Colors.green : Colors.red, size: 48),
              SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(fontSize: 24, color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(detailMessage, style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Đóng"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context); // Quay lại màn hình chính
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
