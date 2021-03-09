#!/bin/bash

echo "$@" > /opt/parameters.log
artefacts=$3
sudo wget $artefacts/motd -O /etc/motd
sudo bash -c 'echo "Your openideal instance is deploying, be patient..." >> /etc/motd'

user=$1
if [ -z $user ]; then
    echo "ERROR: Need paramter 'user'"
    exit 1
fi
ip=$2
if [ -z $ip ]; then
    echo "ERROR: Need paramter 'ip'"
    exit 1
fi


echo "User='$user'"
echo "Ip='$ip'"
home=/home/$user
owner_group=`grep "^$user" /etc/passwd | cut -d':' -f4`

groupadd sudo
adduser --disabled-password --gecos "" hossted

usermod -aG sudo hossted
usermod -aG admin hossted


curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

apt-get -y update
apt-get -y upgrade

apt-get -y install pwgen docker-compose curl apt-transport-https ca-certificates software-properties-common docker-ce wget build-essential php-gd python-dev php-mbstring php-cli php-xml php-mbstring python-pip pwgen php-zip composer

curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

mkdir /opt/openideal
mkdir /opt/openideal/letsencrypt

chmod -R 755 /opt/openideal
chown -R hossted:hossted /opt/openideal

cd /opt/openideal

#downloading

curl -k -XPOST https://vhd.linnovate.net/service?sw=Linnovate-ARM-Openideal

password=`pwgen 10 1`

ip=`curl http://checkip.amazonaws.com`
domain=$ip.c.hossted.com

cd ~
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer --1
export COMPOSER_HOME=/usr/local/bin/composer

chmod +x /usr/local/bin/docker-compose
cd /opt/openideal
chown -R hossted:hossted .
sudo -u hossted composer create-project linnovate/openideal-composer openideal --no-interaction
cd /opt/openideal/openideal
chown -R hossted:hossted .
sudo -u hossted composer require --dev drush/drush

wget $artefacts/.env -O /opt/openideal/openideal/.env

sed -i -e 's/PROJECT_BASE_URL=openideal.docker.localhost/PROJECT_BASE_URL='$domain'/g' .env
sed -i -e 's/ACCOUNT_PASSWORD=1234/ACCOUNT_PASSWORD='$password'/g' .env


wget $artefacts/Makefile -O /opt/openideal/openideal/Makefile
wget $artefacts/docker-compose.yml -O /opt/openideal/openideal/docker-compose.yml

mkdir /opt/openideal/openideal/error-pages
mkdir /opt/openideal/openideal/nginx

wget $artefacts/default.conf -O /opt/openideal/openideal/nginx/default.conf
wget $artefacts/404.html -O /opt/openideal/openideal/error-pages/404.html

chown -R hossted:hossted .
gpasswd -a hossted docker

sudo -E -u hossted docker-compose up -d

chmod 777 web/sites/default

echo "waiting 90 sec before actual containers start and it will be possible to fill out database with initial data"
sleep 90s

echo "filling data..."

sudo -u hossted make
sudo -u hossted docker-compose exec -T php ../vendor/bin/drush cset -y system.site mail 'mail@hossted.com'

sed -i -e 's/Your openideal instance is deploying, be patient.../ /g' /etc/motd
bash -c 'echo "Your OpenideaL instance is serving on https://'$domain'">>/etc/motd'
bash -c 'echo "Default username is admin, password is '$password'">>/etc/motd'

