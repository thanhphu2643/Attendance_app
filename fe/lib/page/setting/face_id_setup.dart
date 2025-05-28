import 'package:flutter/material.dart';
import 'camera_page.dart';

class FaceIDSetupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Đặt màu nền thành trắng
      appBar: AppBar(
        backgroundColor: Colors.white, // Đặt màu AppBar thành trắng
        elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue), // Biểu tượng mũi tên quay lại
            onPressed: () {
              Navigator.pop(context); // Quay lại trang trước
            },
          ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Face ID
            Icon(
              Icons.face,
              size: 100,
              color: Colors.black, // Đổi màu biểu tượng thành đen
            ),
            SizedBox(height: 20),
            // Tiêu đề
            Text(
              'Cách thiết lập khuôn mặt',
              style: TextStyle(
                color: Colors.black, // Đổi màu tiêu đề thành đen
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            // Mô tả
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                'Đầu tiên, định vị khuôn mặt của bạn trong khung hình camera. '
                    'Sau đó, cần nhìn thẳng để lấy các góc cạnh trên khuôn mặt của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16), // Đổi màu mô tả
              ),
            ),
            SizedBox(height: 50),
            // Nút "Bắt đầu"
            ElevatedButton(
              onPressed: () {
                // Chuyển đến trang camera
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300], // Màu nền xám nhẹ
                disabledBackgroundColor: Colors.white, // Màu chữ khi nhấn nút
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Bo tròn góc nút
                ),
                shadowColor: Colors.grey, // Màu của bóng đổ
                elevation: 5, // Độ nổi của bóng đổ
              ),
              child: Text(
                'Bắt đầu',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54, // Chữ màu trắng
                  fontWeight: FontWeight.bold, // Chữ đậm
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
