# Automated WordPress Setup Script with Apache

This Bash script automates the setup of a WordPress site on an Apache server. Follow the steps below for a seamless installation:

### Usage:

1. Run the script:

    ```bash
    bash apache_script.sh
    ```

2. Enter the desired site name, site URL (domain or server IP), WordPress database name, WordPress database user, and MySQL root password as prompted.

### Installation Steps:

1. **Update and Upgrade:**

    ```bash
    sudo apt update
    sudo apt upgrade -y
    ```

2. **Make Site Directory:**

    ```bash
    sudo mkdir -p /var/www/$site_name
    ```

3. **Download and Extract WordPress:**

    ```bash
    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    sudo tar xf latest.tar.gz -C /var/www/
    sudo mv /var/www/wordpress /var/www/$site_name
    rm -rf /tmp/latest.tar.gz*
    cd /var/www/
    ```

4. **Set Ownership and Permissions:**

    ```bash
    sudo chown -R www-data:www-data /var/www/$site_name
    sudo chmod -R 755 /var/www/$site_name
    ```

5. **Install Apache, MySQL, PHP, and Utilities:**

    ```bash
    sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql
    ```

6. **Initialize MySQL, Create WordPress Database/User:**

    ```bash
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
    ```

7. **Configure Apache Virtual Host:**

    ```bash
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
    ```

8. **Enable the Site and Restart Apache:**

    ```bash
    sudo a2ensite $site_name.conf
    sudo systemctl restart apache2
    ```

9. **Install Certbot, Allow Ports, Configure Certbot, and Set Up Cronjob:**

    ```bash
    sudo apt install -y python3-certbot-apache
    sudo ufw allow 8080
    sudo ufw allow 443
    sudo certbot --apache
    (crontab -l 2>/dev/null; echo "0 0 1 * * certbot renew") | crontab -
    ```