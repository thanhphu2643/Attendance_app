<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thông Tin Đăng Nhập Của Bạn</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 20px;
            color: #333;
            line-height: 1.6;
        }
        .email-container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #fff;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            overflow: hidden;
            padding: 30px;
        }
        .header {
            text-align: center;
            background-color: #007BFF;
            color: #fff;
            padding: 15px;
            border-radius: 8px 8px 0 0;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .content {
            padding: 20px;
        }
        .content p {
            margin: 10px 0;
            font-size: 16px;
        }
        .highlight {
            font-weight: bold;
            color: #000;
        }
        .link {
            color: #007BFF;
            text-decoration: none;
            font-weight: bold;
        }
        .note {
            margin-top: 20px;
            font-size: 14px;
            color: #777;
        }
        .footer {
            margin-top: 20px;
            font-size: 13px;
            color: #666;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>Thông Tin Đăng Nhập Của Bạn</h1>
        </div>
        <div class="content">
            <p>Xin chào,</p>
            <p>Chúng tôi xin gửi đến bạn thông tin đăng nhập để sử dụng ứng dụng <span class="highlight">Attendance</span>:</p>
            <p><span class="highlight">Tên đăng nhập (Username):</span> {{ $tenTaiKhoan }}</p>
            <p><span class="highlight">Mật khẩu (Password):</span> {{ $matKhau }}</p>
            <div class="note">
                <p><strong>Lưu ý:</strong></p>
                <p>Để bảo mật thông tin, bạn nên thay đổi mật khẩu sau lần đăng nhập đầu tiên.</p>
                <p>Nếu bạn không yêu cầu thông tin này hoặc gặp bất kỳ vấn đề nào, vui lòng liên hệ với chúng tôi qua <a href="mailto:hunglam0809@gmail.com" class="link">hunglam0809@gmail.com</a> hoặc gọi số <span class="highlight">0353627994</span>.</p>
            </div>
        </div>
        <div class="footer">
            <p>Chân thành cảm ơn bạn đã sử dụng <span class="highlight">Attendance</span>.</p>
        </div>
    </div>
</body>
</html>
