echo "-----------------Started Removing All Files-------------"
echo "Updating System..."
apt-get update

echo "Removing Repositories"
add-apt-repository --remove ppa:nginx/stable
add-apt-repository --remove ppa:rwky/redis
add-apt-repository --remove ppa:ondrej/php5-5.6
apt-get autoremove

apt-get update

echo "Uninstalling PHP5-FPM"
apt-get purge php5 php5-common
apt-get autoremove

echo "Uninstalling wget..."
apt-get remove wget
apt-get autoremove

apt-get update

echo "Removing Curl..."
apt-get purge curl
apt-get autoremove

apt-get update

echo "Removing PHP5-CLI..."
apt-get -y purge php.*
apt-get remove --purge php5-cli
apt-get remove --purge php5-dev
apt-get remove --purge php5-pear
apt-get remove phpunit
apt-get remove php5-pear
apt-get autoremove

echo "Removing Mailparse..."
pecl uninstall mailparse
rm -rf /tmp/pear

echo "Removing Composer..."
composer global remove phpunit/phpunit

apt-get update

echo "Removing Laravel Envoy..."
composer global remove "laravel/envoy=~1.0"

echo "Removing Nginx..."
sudo apt-get purge nginx nginx-common
sudo apt-get autoremove
rm -rf /etc/nginx

echo "Removing PHP5-FPM..."
apt-get purge php5-fpm
apt-get purge --auto-remove php5-fpm
rm -rf /etc/php5

echo "Removing User..."
userdel sedev
userdel -r sedev

echo "Removing Node Js..."
apt-get remove nodejs
apt-get autoremove
rm /usr/bin/npm

apt-get update

echo "Removing SQlite..."
apt-get purge sqlite
apt-get purge --auto-remove sqlite

echo "Removing MySql..."
apt-get remove --purge mysql-server mysql-client mysql-common
apt-get autoremove
apt-get autoclean

echo "Removing Postgres..."
apt-get --purge remove postgresql
apt-get atoremove

apt-get update

echo "We Successfully removes Everything."