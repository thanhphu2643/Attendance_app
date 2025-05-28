# Sử dụng PHP 8.2 với FPM
FROM php:8.2-fpm

# Cài đặt các thư viện hệ thống
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \ 
    nginx \
    build-essential \
    supervisor \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Cài đặt các extension PHP
RUN docker-php-ext-install gd pdo pdo_mysql sockets zip

# Cài Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Tạo người dùng để chạy ứng dụng
RUN groupadd -g 1000 www && useradd -u 1000 -ms /bin/bash -g www www

# Set thư mục làm việc
WORKDIR /var/www

# Copy Composer files và cài đặt dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copy toàn bộ mã nguồn
COPY . .

# Thiết lập quyền
RUN chown -R www:www /var/www && \
    chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Copy cấu hình Supervisor
COPY ./supervisord.conf /etc/supervisord.conf

# Expose port
EXPOSE 80

# CMD chạy Supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
