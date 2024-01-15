#!/bin/bash

# Get user inputs for variables
read -p "Enter the desired site name: " site_name
read -p "Enter the site URL (domain or server IP): " site_url
read -p "Enter the WordPress database name: " db_name
read -p "Enter the WordPress database user: " db_user
read -s -p "Enter the WordPress database password: " db_password
echo

# 1: Update and upgrade
sudo apt update
sudo apt upgrade -y

# 2: Make the directory for the new site
sudo mkdir -p /var/www/$site_name

# 3: Download and extract WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
sudo tar xf latest.tar.gz -C /var/www/
sudo mv /var/www/wordpress /var/www/$site_name
rm -rf /tmp/latest.tar.gz*
cd /var/www/

# 4: Ensure group ownership and permissions
sudo chown -R www-data:www-data /var/www/$site_name
sudo chmod -R 755 /var/www/$site_name

# 5: Install Apache, MySQL, PHP, and other utilities
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql

# 6: Check if MySQL root password is provided, if not, prompt for it
if [ -z "$mysql_root_password" ]; then
    read -s -p "Enter MySQL root password: " mysql_root_password
fi

# 7: Initialize MySQL, create WordPress database, and user
sudo mysql -u root -p"$mysql_root_password" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $db_name;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '$db_password';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';
ALTER USER '$db_user'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '$db_password';
FLUSH PRIVILEGES;
SHOW DATABASES LIKE '$db_name';
SELECT user, host, plugin FROM mysql.user WHERE user='$db_user' AND host='localhost';
EXIT;
MYSQL_SCRIPT

# 8: Configure Apache virtual host
# Add the Apache configuration
echo "<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/$site_name/wordpress
    ServerName $site_url

    <Directory /var/www/$site_name/wordpress>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" | sudo tee /etc/apache2/sites-available/$site_name.conf

# 9: Enable the site and restart Apache
sudo a2ensite $site_name.conf
sudo systemctl restart apache2

# 10: Install Certbot, allow ports, configure Certbot, and set up cronjob
sudo apt install -y python3-certbot-apache
sudo ufw allow 8080 \
sudo ufw allow 443
sudo certbot --apache
(crontab -l 2>/dev/null; echo "0 0 1 * * certbot renew") | crontab -
