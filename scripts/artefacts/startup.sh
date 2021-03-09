#!/bin/bash

sudo bash -c 'echo "Your openideal instance is deploying, be patient..." >> /etc/motd'

password=`pwgen 10 1`

ip=`curl http://checkip.amazonaws.com`
domain=$ip.c.hossted.com

sudo sed -i -e 's/PROJECT_BASE_URL=openideal.docker.localhost/PROJECT_BASE_URL='$domain'/g' .env
sudo sed -i -e 's/ACCOUNT_PASSWORD=1234/ACCOUNT_PASSWORD='$password'/g' .env

cd ~
curl -sS https://getcomposer.org/installer -o composer-setup.php
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer --1
export COMPOSER_HOME=/usr/local/bin/composer
sudo chmod +x /usr/local/bin/docker-compose
cd {{app_dir}}
sudo chown -R hossted:hossted .
composer create-project linnovate/openideal-composer openideal --no-interaction
cd /opt/openideal/openideal
composer require --dev drush/drush
mv ../Makefile .
mv ../docker-compose.yml .
mv ../.env .
cp -R ../nginx ./
cp -R ../error-pages ./

sudo chown -R hossted:hossted .
sudo gpasswd -a hossted docker

sudo -u hossted docker-compose up -d 

sudo chmod 777 web/sites/default

echo "waiting 60 sec before actual containers start and it will be possible to fill out database with initial data"
sleep 60s

echo "filling data..."
sudo -u hossted make
sudo docker-compose exec -T php ../vendor/bin/drush cset -y system.site mail 'mail@hossted.com'

sudo sed -i -e 's/Your openideal instance is deploying, be patient.../ /g' /etc/motd
sudo bash -c 'echo "Your OpenideaL instance is serving on https://'$domain'">>/etc/motd'
sudo bash -c 'echo "Default username is admin, password is '$password'">>/etc/motd'

rm $0
sudo rm /etc/systemd/system/hossted.service
