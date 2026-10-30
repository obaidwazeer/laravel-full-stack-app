#!/bin/bash

set -Eeuo pipefail

exec > /var/log/laravel-web-bootstrap.log 2>&1

export DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# 1. Update Ubuntu
# --------------------------------------------------

apt-get update

# --------------------------------------------------
# 2. Install Nginx, PHP and required extensions
# --------------------------------------------------

apt-get install -y \
    nginx \
    php8.3-cli \
    php8.3-fpm \
    php8.3-common \
    php8.3-mysql \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-curl \
    php8.3-zip \
    php8.3-bcmath \
    php8.3-intl \
    php8.3-gd \
    php8.3-opcache \
    awscli \
    jq \
    rsync \
    curl \
    unzip

# --------------------------------------------------
# 3. Start and enable services
# --------------------------------------------------

systemctl enable --now nginx
systemctl enable --now php8.3-fpm

# --------------------------------------------------
# 4. Prepare deployment user and directories
# --------------------------------------------------

usermod -aG www-data ubuntu

install -d \
    -o ubuntu \
    -g www-data \
    -m 2775 \
    /var/www/laravel

install -d \
    -o ubuntu \
    -g www-data \
    -m 2775 \
    /var/www/laravel/storage

install -d \
    -o ubuntu \
    -g www-data \
    -m 2775 \
    /var/www/laravel/storage/app/public

install -d \
    -o ubuntu \
    -g www-data \
    -m 2775 \
    /var/www/laravel/storage/framework/cache/data

install -d \
    -o ubuntu \
    -g www-data \
    -m 2775 \
    /var/www/laravel/storage/framework/sessions

install -d \
    -o ubuntu \
    -g www-data \
    -m 2775 \
    /var/www/laravel/storage/framework/views

install -d \
    -o ubuntu \
    -g www-data \
    -m 2775 \
    /var/www/laravel/storage/logs

install -d \
    -o ubuntu \
    -g www-data \
    -m 2775 \
    /var/www/laravel/bootstrap/cache

# --------------------------------------------------
# 5. Configure Nginx for Laravel
# --------------------------------------------------

cat > /etc/nginx/sites-available/laravel <<'NGINX'

server {

    listen 80 default_server;

    server_name _;

    root /var/www/laravel/public;

    index index.php index.html;

    client_max_body_size 30M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {

        try_files $uri =404;

        include snippets/fastcgi-php.conf;

        fastcgi_pass unix:/run/php/php8.3-fpm.sock;

        fastcgi_read_timeout 60s;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}

NGINX

# --------------------------------------------------
# 6. Enable Laravel Nginx configuration
# --------------------------------------------------

ln -sfn \
    /etc/nginx/sites-available/laravel \
    /etc/nginx/sites-enabled/laravel

rm -f /etc/nginx/sites-enabled/default

# --------------------------------------------------
# 7. Validate and reload Nginx
# --------------------------------------------------

nginx -t

systemctl reload nginx

# --------------------------------------------------
# 8. Verify installed software
# --------------------------------------------------

php -v
php -m

nginx -v

systemctl is-active nginx
systemctl is-active php8.3-fpm

echo "Web EC2 bootstrap completed successfully."
