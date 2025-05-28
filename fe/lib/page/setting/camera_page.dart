import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';
import '../../service/user_service.dart';
import '../clock_in_page.dart';
import '../../service/shared_preferences.dart';
import '../settings_page.dart';  // Import SharedPreferences

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  bool _isEyesOpen = false;
  bool _isLookingAtCamera = false;
  bool _isFaceComplete = false;
  Timer? _timer;
  bool _isFaceDetected = false;
  File? _originalImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      // Tìm camera trước
      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _controller!.initialize();
      setState(() {});

      _startFaceDetection();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }


  void _startFaceDetection() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (_controller != null && _controller!.value.isInitialized && !_isFaceDetected) {
        try {
          final image = await _controller!.takePicture();
          await _processImage(image.path);
        } catch (e) {
          print('Error taking picture for detection: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _processImage(String imagePath) async {
    final faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        setState(() {
          _isLookingAtCamera = true;
          _isEyesOpen = faces.any((face) => face.leftEyeOpenProbability! > 0.5 && face.rightEyeOpenProbability! > 0.5);
          _isFaceComplete = faces.any((face) => face.boundingBox.width > 100 && face.boundingBox.height > 100);
        });

        if (_isLookingAtCamera && _isEyesOpen && _isFaceComplete) {
          _takePicture(imagePath);
        }
      } else {
        setState(() {
          _isLookingAtCamera = false;
          _isEyesOpen = false;
          _isFaceComplete = false;
        });
      }

      _originalImage = File(imagePath);
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      faceDetector.close();
    }
  }
  Future<bool> uploadImage(File imageFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? maND = prefs.getInt('maND'); // Lấy maND từ SharedPreferences
    if (maND != null) {
        // final userData = await fetchUserData(maND);

        // if (userData != null) {
          String filename = '$maND.jpg';  // Đặt tên file theo định dạng MaND_HoVaTen

          var stream = http.ByteStream(Stream.castFrom(imageFile.openRead()));
          var length = await imageFile.length();

          var uri = Uri.parse(ApiConstants.uploadUrl);

          var request = http.MultipartRequest("POST", uri);
          var multipartFile = http.MultipartFile(
            'image',
            stream,
            length,
            filename: filename,  // Sử dụng tên file mới
          );

          request.files.add(multipartFile);

          var response = await request.send();
          var responseBody = await http.Response.fromStream(response);

          // Trả về true nếu upload thành công, ngược lại false
          if (response.statusCode == 200) {
            print('Upload successful');
            await updateFaceStatusInDatabase(maND, true);
            return true; // Thành công
          } else {
            // Xử lý các lỗi khác nhau từ server
            String errorMessage;

            if (response.statusCode == 400) {
              errorMessage = 'Upload failed: ${responseBody.body}';
              print(errorMessage);
              await _showDialog('Thiết lập khuôn mặt thất bại!', isSuccess: false); // Hiển thị thông báo thất bại
            } else if (responseBody.body.contains("Failed to detect or encode face")) {
              errorMessage = 'Face detection or encoding failed';
              print(errorMessage);
              await _showDialog('Không phát hiện khuôn mặt, vui lòng chụp lại ảnh.', isSuccess: false);
            } else {
              errorMessage = 'Upload failed';
              print(errorMessage);
              await _showDialog('Thiết lập khuôn mặt thất bại!', isSuccess: false);
            }
            return false; // Thất bại
          }
        // } else {
        //   print('User data not found');
        //   await _showDialog('Không tìm thấy thông tin người dùng!', isSuccess: false);
        // }
      } else {
        print('MaND not found');
        await _showDialog('Không tìm thấy MaND!', isSuccess: false);
      }

    return false; // Thất bại nếu không vào được
  }


  Future<void> updateFaceStatusInDatabase(int maND, bool status) async {
    try {
      // Gọi API để cập nhật trangThaiKhuonMat
      var uri = Uri.parse(ApiConstants.updateFaceStatusUrl); // URL của API cập nhật
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'maND': maND, 'trangThaiKhuonMat': status ? 1 : 0}), // Update to send 1 for true, 0 for false
      );

      if (response.statusCode == 200) {
        print('Cập nhật trạng thái khuôn mặt thành công');
      } else {
        print('Cập nhật trạng thái khuôn mặt thất bại: ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái khuôn mặt: $e');
    }
  }


  Future<void> _showDialog(String message, {bool isSuccess = true}) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error, // Biểu tượng thành công hoặc thất bại
                color: isSuccess ? Colors.green : Colors.red,
                size: 64, // Kích thước biểu tượng
              ),
              SizedBox(height: 16), // Khoảng cách giữa biểu tượng và text
              Text(
                message,
                textAlign: TextAlign.center, // Căn giữa văn bản
                style: TextStyle(
                  color: Colors.blueAccent, // Đặt màu cho văn bản
                  fontSize: 20, // Kích thước văn bản (bạn có thể điều chỉnh kích thước này)
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng hộp thoại khi nhấn nút
                if (!isSuccess) {
                  // Nếu là thông báo thất bại, chuyển về trang SettingsPage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }



  void _takePicture(String imagePath) async {
    if (!_isFaceDetected) {
        _timer?.cancel();

        final originalImageFile = File(imagePath);
        setState(() {
          _originalImage = originalImageFile;
          _isFaceDetected = true;
        });

        // Gọi hàm uploadImage và chờ đợi kết quả
        bool uploadSuccess = await uploadImage(originalImageFile);

        // Kiểm tra kết quả upload
        if (uploadSuccess) {
          // Hiển thị thông báo thành công
          await _showDialog('Thiết lập khuôn mặt thành công!', isSuccess: true); // Chờ hộp thoại hoàn tất

          // Điều hướng tới AttendancePage sau khi upload thành công
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ClockInPage()),
          );
        }

    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thiết lập khuôn mặt')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _startFaceDetection(); // Khởi động phát hiện khuôn mặt
            return Stack(
              children: [
                CameraPreview(_controller!),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (!_isLookingAtCamera)
                          Text(
                            'Bạn cần nhìn thẳng vào camera',
                            style: TextStyle(color: Colors.red, fontSize: 18),
                          )
                        else if (!_isEyesOpen && _isLookingAtCamera)
                          Text(
                            'Vui lòng mở mắt',
                            style: TextStyle(color: Colors.red, fontSize: 18),
                          )
                        else if (!_isFaceComplete)
                            Text(
                              'Đảm bảo khuôn mặt không bị che khuất',
                              style: TextStyle(color: Colors.red, fontSize: 18),
                            )
                          else // Nếu tất cả các điều kiện trên đều không thỏa mãn
                            Text(
                              'Vui lòng chờ trong giây lát.',
                              style: TextStyle(color: Colors.green, fontSize: 18),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
