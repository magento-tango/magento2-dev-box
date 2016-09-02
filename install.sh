#!/bin/bash

echo 'Creating docker-compose config'

cat > docker-compose.yml <<- 'EOM'
##
# Services needed to run Magento2 application on Docker
#
# Docker Compose defines required services and attach them together through aliases
##
db:
  container_name: magento2-devbox-db
  restart: always
  image: mysql:5.6
  ports:
    - "1345:3306"
  environment:
    - MYSQL_ROOT_PASSWORD=root
    - MYSQL_DATABASE=magento2
  volumes:
    - ./shared/db:/var/lib/mysql
EOM

read -p 'Do you wish to install RabbitMQ (y/n): ' install_rabbitmq

link_to_rabbit=''
if [ $install_rabbitmq = 'y' ]
    then
        cat << 'EOM' >> docker-compose.yml
rabbit:
  container_name: magento2-devbox-rabbit
  image: rabbitmq:3-management
  ports:
    - "8282:15672"
    - "5672:5672" 
EOM
link_to_rabbit=$(cat <<SETVAR

    - rabbit:rabbit

SETVAR
)
fi

read -p 'Do you wish to install Varnish (y/n): ' install_varnish

link_to_varnish=''
if [ $install_varnish = 'y' ]
    then
        cat << 'EOM' >> docker-compose.yml
varnish:
  image: eeacms/varnish
  ports:
  - "1748:80"
  links:
  - web
EOM
link_to_varnish=$(cat <<SETVAR

    - varnish:varnish

SETVAR
)
fi

cat << EOM >> docker-compose.yml
web:
  build: web
  container_name: magento2-devbox-web
  volumes:
    - ./shared/webroot:/var/www/magento2
    - ./shared/.composer:/root/.composer
    - ./shared/.ssh:/root/.ssh
    #    - ./shared/.magento-cloud:/root/.magento-cloud
    - ./scripts:/root/scripts
  ports:
    - "1748:80"
#    - "9000:9000"
  links:
    - db:db$link_to_rabbit$link_to_varnish
  command: "apache2-foreground"
EOM

echo "Creating shared folders"

mkdir -p shared/.composer
mkdir -p shared/.ssh
mkdir -p shared/webroot
mkdir -p shared/db

echo 'Build docker images'

docker-compose up --build -d

docker exec -it --privileged magento2-devbox-web php /root/scripts/composerInstall.php
docker exec -it --privileged magento2-devbox-web php /root/scripts/magentoSetup.php --install-rabbitmq=$install_rabbitmq
docker exec -it --privileged magento2-devbox-web php /root/scripts/postInstall.php
