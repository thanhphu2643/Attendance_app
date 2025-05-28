# Sử dụng một image Python chính thức
FROM python:3.9-slim

# Cài đặt các công cụ cần thiết cho dlib và hệ thống
RUN apt-get update && apt-get install -y \
    nginx \
    cmake \
    g++ \
    libgtk2.0-dev \
    libboost-all-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*  # Dọn dẹp cache

# Tạo thư mục cho app
WORKDIR /app

# Sao chép mã nguồn vào container
COPY ./app /app

# Sao chép các yêu cầu vào container
COPY ./requirements.txt /app/requirements.txt

# Cài đặt pip và các gói phụ thuộc từ requirements.txt
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r /app/requirements.txt

# Cài đặt dlib sau khi đã cài đặt các công cụ cần thiết
RUN pip install dlib

# Tạo thư mục log cho Nginx
RUN mkdir -p /var/log/nginx

# Sao chép file cấu hình nginx
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

# Expose port 80 để truy cập qua Nginx
EXPOSE 80

# Chạy Nginx trong foreground và Flask server bằng gunicorn
CMD nginx -g 'daemon off;' & gunicorn --workers 3 --bind 0.0.0.0:5000 app:app
