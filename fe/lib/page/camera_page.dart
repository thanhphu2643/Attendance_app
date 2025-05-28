import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/page/report_page.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  late CameraDescription frontCamera;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
      _controller = CameraController(frontCamera, ResolutionPreset.high);
      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    } catch (e) {
      print("Lỗi khi khởi tạo camera: $e");
      _showErrorDialog("Không thể khởi tạo camera");
    }
  }

  Future<String> _saveImage(XFile image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(image.path);
      await imageFile.copy(imagePath);

      // Lưu đường dẫn vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('imagePath', imagePath);

      return imagePath;
    } catch (e) {
      print("Lỗi khi lưu ảnh: $e");
      _showErrorDialog("Không thể lưu ảnh");
      rethrow;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Lỗi"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chụp ảnh'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: FloatingActionButton(
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          final image = await _controller!.takePicture();
                          await _saveImage(image);

                          // Hiển thị thông báo thành công và chuyển trang
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Chụp ảnh thành công!'),
                          ));

                          // Chuyển đến trang ReportPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ReportPage()),
                          );
                        } catch (e) {
                          print("Lỗi khi chụp ảnh: $e");
                          _showErrorDialog("Không thể chụp ảnh");
                        }
                      },
                      child: Icon(Icons.camera_alt),
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
