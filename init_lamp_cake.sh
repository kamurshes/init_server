#!/bin/bash
set -e

# ==========================
# 基本パッケージ更新
# ==========================
sudo apt update -y && sudo apt upgrade -y

# ==========================
# Apache2, PHP, MySQL, phpMyAdmin, Certbot のインストール
# ==========================
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql php-cli php-curl php-json php-mbstring php-xml unzip wget curl git

# phpMyAdmin の非対話型インストール
# debconf で事前設定
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password root" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
sudo apt install -y phpmyadmin

# Certbot (Let's Encrypt)
sudo apt install -y certbot python3-certbot-apache

# ==========================
# CakePHP インストール
# ==========================
# Composer のインストール
if ! command -v composer &> /dev/null; then
  EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
      echo 'ERROR: Invalid installer checksum'
      rm composer-setup.php
      exit 1
  fi
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm composer-setup.php
fi

# CakePHP プロジェクト作成例（必要に応じてパスを変更）
# sudo -u ubuntu composer create-project --prefer-dist cakephp/app /var/www/cakephp-app

# ==========================
# 権限設定
# ==========================
# /var/www/ の所有者を ubuntu:www-data に設定
sudo chown -R ubuntu:www-data /var/www/
sudo find /var/www/ -type d -exec chmod 775 {} \;
sudo find /var/www/ -type f -exec chmod 664 {} \;

# Apache の www-data を ubuntu とグループ共有
sudo usermod -aG www-data ubuntu

# Apache モジュール有効化
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "=========================="
echo " 初期セットアップ完了！"
echo " /var/www/ は ubuntu:www-data の所有権になりました。"
echo "=========================="

