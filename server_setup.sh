#!/usr/bin/env bash
echo "Starting teh setup installation..."
echo "By Sourceeasy..."
echo "----------------SERVER SETUP STARTING----------------"
# Update Package List
echo "Starting Update..."
apt-get update
echo "Update Finished"

# Update System Packages
echo "Starting Upgrading..."
apt-get -y upgrade
echo "Upgraded Successfully"

# Force Locale

echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8

# Install Some PPAs
echo "Started Installing Some Personal Package Archieve(PPAs)..."
apt-get install -y software-properties-common curl
apt-add-repository ppa:nginx/stable -y
apt-add-repository ppa:rwky/redis -y
apt-add-repository ppa:ondrej/php5-5.6 -y
echo "PPAs Installed Successfully"

#Install Wget for Non-Interactive Network Downloader
echo "Started Installing Non-Interactive Network Downloader(wget)"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" >> /etc/apt/sources.list.d/postgresql.list'
echo "wget Installed Successfully"


echo "Installing Curl..."
curl -s https://packagecloud.io/gpg.key | sudo apt-key add -
echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list

curl --silent --location https://deb.nodesource.com/setup_0.12 | sudo bash -

echo "Curl Installed Successfully..."

# Update Package Lists
echo "Running Package Update..."
apt-get update
echo "Updated Successfully"

# Install Some Basic Packages
echo "Started Installing Few More Packages"
apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev \
make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim
echo "Package Installed Successfully"

# Set My Timezone
echo "Setting Time Zone..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo "Local Time Zone has been set"

# Install PHP Stuffs
echo "Installing PHP and SQLITE and other stuffs..."
apt-get install -y php5-cli php5-dev php-pear \
php5-mysqlnd php5-pgsql php5-sqlite \
php5-apcu php5-json php5-curl php5-gd \
php5-gmp php5-imap php5-mcrypt php5-xdebug \
php5-memcached
echo "Installed Successfully"

# Install Mailparse PECL Extension
echo "Installing Mailparse for manipulation with emails..."
pecl install mailparse
echo "extension=mailparse.so" > /etc/php5/mods-available/mailparse.ini
ln -s /etc/php5/mods-available/mailparse.ini /etc/php5/cli/conf.d/20-mailparse.ini
echo "Mailparse successfully Installed"

# Install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
echo "Composer Installed Successfully"

# Add Composer Global Bin To Path
echo "Adding COmposer to sedev..."
printf "\nPATH=\"/home/sedev/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/sedev/.profile
echo "Successfully Done"

# Install Laravel Envoy
echo "Installing Laravel Envoy..."
sudo su sedev <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
EOF
echo "Envoy installed successfully"

# Set Some PHP CLI Settings
echo "Setting up for some CLI settings..."
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/cli/php.ini
echo "CLI settings done"

# Install Nginx & PHP-FPM
echo "Installing Ngnix and PHP-FPM(FastCGI Process Manager)"
apt-get install -y nginx php5-fpm
service nginx restart
echo "Installation Completed"

# Setup Some PHP-FPM Options
echo "Installing some PHP-FPM options..."
ln -s /etc/php5/mods-available/mailparse.ini /etc/php5/fpm/conf.d/20-mailparse.ini

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php5/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php5/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/fpm/php.ini

echo "xdebug.remote_enable = 1" >> /etc/php5/fpm/conf.d/20-xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php5/fpm/conf.d/20-xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php5/fpm/conf.d/20-xdebug.ini
echo "xdebug.max_nesting_level = 512" >> /etc/php5/fpm/conf.d/20-xdebug.ini
echo "Installation Completed"

# Copy fastcgi_params to Nginx because they broke it on the PPA

cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param   QUERY_STRING        \$query_string;
fastcgi_param   REQUEST_METHOD      \$request_method;
fastcgi_param   CONTENT_TYPE        \$content_type;
fastcgi_param   CONTENT_LENGTH      \$content_length;
fastcgi_param   SCRIPT_FILENAME     \$request_filename;
fastcgi_param   SCRIPT_NAME     \$fastcgi_script_name;
fastcgi_param   REQUEST_URI     \$request_uri;
fastcgi_param   DOCUMENT_URI        \$document_uri;
fastcgi_param   DOCUMENT_ROOT       \$document_root;
fastcgi_param   SERVER_PROTOCOL     \$server_protocol;
fastcgi_param   GATEWAY_INTERFACE   CGI/1.1;
fastcgi_param   SERVER_SOFTWARE     nginx/\$nginx_version;
fastcgi_param   REMOTE_ADDR     \$remote_addr;
fastcgi_param   REMOTE_PORT     \$remote_port;
fastcgi_param   SERVER_ADDR     \$server_addr;
fastcgi_param   SERVER_PORT     \$server_port;
fastcgi_param   SERVER_NAME     \$server_name;
fastcgi_param   HTTPS           \$https if_not_empty;
fastcgi_param   REDIRECT_STATUS     200;
EOF



# Restarting Ngix and PHP5-FPM services
echo "Restarting and stting up Ngix and PHP5-FPM services..."
# Set The Nginx & PHP-FPM User

sed -i "s/user www-data;/user sedev;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/user = www-data/user = sedev/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = sedev/" /etc/php5/fpm/pool.d/www.conf

sed -i "s/listen\.owner.*/listen.owner = sedev/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = sedev/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php5/fpm/pool.d/www.conf

service nginx restart
service php5-fpm restart
echo "Restarted Successfully"

# Add sedev User To WWW-Data
adduser sedev adduser 
sudo adduser sedev sudo
sudo mkdir /home/sedev
sudo mkdir /home/sedev/repos
usermod -a -G www-data sedev
id sedev
groups sedev

# Install Node
echo "Installing NodeJs..."
apt-get install -y nodejs
/usr/bin/npm install -g grunt-cli
/usr/bin/npm install -g gulp
/usr/bin/npm install -g bower
echo "NodeJs installed Successfully"

# Install SQLite
echo "Installing Sqlite..."
apt-get install -y sqlite3 libsqlite3-dev
echo "Sqlite installed successfully"

# Install MySQL
echo "Installing Mysql..."
debconf-set-selections <<< "mysql-server mysql-server/root_password password secret"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password secret"
apt-get install -y mysql-server-5.6
echo "Mysql installed Successfully"

# Configure MySQL Remote Access
echo "Configuring MySql..."
sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
service mysql restart

mysql --user="root" --password="secret" -e "CREATE USER 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret';"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'homestead'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"
mysql --user="root" --password="secret" -e "CREATE DATABASE homestead;"
service mysql restart
echo "Username: root, password:secret"

# Add Timezone Support To MySQL

#mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=secret --force mysql
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql -force 2> /dev/null
echo "MySql time zone has been set successfully"

# Install Postgres
echo "Installing Postgres"
apt-get install -y postgresql-9.4 postgresql-contrib-9.4
echo "Postgres Installed Successfully"

# Configure Postgres Remote Access
echo "Configuring Postgres..."
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.4/main/postgresql.conf
echo "host    all             all             10.0.2.2/32               md5" | tee -a /etc/postgresql/9.4/main/pg_hba.conf
sudo -u postgres psql -c "CREATE ROLE homestead LOGIN UNENCRYPTED PASSWORD 'secret' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"
sudo -u postgres /usr/bin/createdb --echo --owner=homestead homestead
echo "Configured Successfully"
service postgresql restart
echo "Postgresql Service Restarted"

# Enable Swap Memory

/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1

# Minimize The Disk Image

echo "Minimizing disk image..."
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync

echo "We are done..Now you are good to go"
echo "Database username is root and password is secret"
echo "Thankyou"

echo "---------------------SERVER SETUP FINISHED---------------------"
