#!/bin/bash

request () {
    local varName=$1
    local question=$2
    local isBoolean=$3
    local defaultValue=$4
    local value
    local output

    if [[ $isBoolean = 1 ]]; then
        if [[ $defaultValue = 1 ]]; then
            question="$question [Y/n]"
        else
            question="$question [y/N]"
        fi
    else
        if [[ $defaultValue != '' ]]; then
            question="$question [default: $defaultValue]"
        fi
    fi

    read -p "$question: " value #prompt value
    value=$(echo $value | xargs) #trim input

    if [[ ${#value} > 0 ]]; then
        if [[ $isBoolean = 1 ]]; then
            if echo $value | grep -Eiq '^(?:[1y]|yes|true)$'; then
                value=1
                output='yes'
            else
                value=0
                output='no'
            fi
        else
            output=$value
        fi
    else
        if [[ $isBoolean = 1 ]]; then
            if [[ $defaultValue = 1 ]]; then
                value=1
                output='yes'
            else
                value=0
                output='no'
            fi
        else
            value=$defaultValue
            output=$value
        fi
    fi

    export $varName=$value
    echo $output
}

while test $# -gt 0; do
    case $1 in
        --*)
            export $(echo $1 | sed -e 's/^--\([^=]*\)=[^=]*$/\1/g' | sed -e 's/-/_/g')=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        *)
            break
            ;;
    esac
done

echo 'Creating docker-compose config'

if [[ $webroot_path ]]; then
    use_existing_sources=1
else
    webroot_path='./shared/webroot'

    if [[ ! $use_existing_sources ]]; then
        request 'use_existing_sources' 'Do you have existing copy of Magento 2?' 1
    fi

    if [[ $use_existing_sources = 1 ]]; then
        request 'webroot_path' 'Please provide full path to the magento2 folder'
    fi
fi

if [[ ! $composer_path ]]; then
    composer_path='./shared/.composer'
fi

if [[ ! $ssh_path ]]; then
    ssh_path='./shared/.ssh'
fi

if [[ ! $db_path ]]; then
    db_path='./shared/db'
fi

db_host=db
db_port=3306
db_password=root
db_user=root
db_name=magento2

cat > docker-compose.yml <<- EOM
##
# Services needed to run Magento2 application on Docker
#
# Docker Compose defines required services and attach them together through aliases
##
version: '2'
services:
  $db_host:
    container_name: magento2-devbox-db
    restart: always
    image: mysql:5.6
    ports:
      - "1345:$db_port"
    environment:
      - MYSQL_ROOT_PASSWORD=$db_password
      - MYSQL_DATABASE=$db_name
    volumes:
      - $db_path:/var/lib/mysql
EOM

rabbit_host='rabbit'
rabbit_port=5672

if [[ $install_rabbitmq = 1 ]]; then
    cat << EOM >> docker-compose.yml
  $rabbit_host:
    container_name: magento2-devbox-rabbit
    image: rabbitmq:3-management
    ports:
      - "8282:15672"
      - "$rabbit_port:$rabbit_port"
EOM
fi

if [[ ! $redis_session ]]; then
    redis_session=1
fi

if [[ ! $redis_cache ]]; then
    redis_cache=1
fi

if [[ $redis_fpc = 1 ]]; then
    varnish_fpc=0
else
    if [[ ! $varnish_fpc ]]; then
        varnish_fpc=1
    fi
fi

([[ $redis_session = 1 ]] || [[ $redis_cache = 1 ]] || [[ $redis_fpc = 1 ]]) && install_redis=1 || install_redis=0
redis_host='redis'

if [[ $install_redis = 1 ]]; then
    cat << EOM >> docker-compose.yml
  $redis_host:
    container_name: magento2-devbox-redis
    image: redis:3.0.7
EOM
fi

web_port=1748
varnish_host_container=magento2-devbox-varnish

if [[ $varnish_fpc = 1 ]]; then
    cat << EOM >> docker-compose.yml
  varnish:
    image: magento/magento2devbox_varnish:latest
    container_name: $varnish_host_container
    ports:
      - "1748:6081"
EOM
    web_port=1749
fi

magento_path='/var/www/magento2'
main_host=web
main_host_port=80
main_host_container=magento2-devbox-web

cat << EOM >> docker-compose.yml
  $main_host:
    # image: magento/magento2devbox_web:latest
    build: web
    container_name: $main_host_container
    volumes:
      - $webroot_path:$magento_path
      - $composer_path:/home/magento2/.composer
      - $ssh_path:/home/magento2/.ssh
      #    - ./shared/.magento-cloud:/root/.magento-cloud
    ports:
      - "$web_port:$main_host_port"
      - "2222:22"
EOM

echo 'Creating shared folders'
mkdir -p shared/.composer
mkdir -p shared/.ssh
mkdir -p shared/webroot
mkdir -p shared/db

echo 'Build docker images'
docker-compose up --build -d

docker exec -it --privileged magento2-devbox-web /bin/sh -c 'chown -R magento2:magento2 /home/magento2 && chown -R magento2:magento2 /var/www/magento2'

docker exec -it --privileged -u magento2 magento2-devbox-web \
    php -f /home/magento2/scripts/devbox magento:download \
        --use-existing-sources=$use_existing_sources

if [[ ! $install_sample_data ]]; then
    install_sample_data=1
fi

if [[ ! $backend_path ]]; then
    backend_path='admin'
fi

if [[ ! $admin_user ]]; then
    admin_user='admin'
fi

if [[ ! $admin_password ]]; then
    admin_password='admin123'
fi

docker exec -it --privileged -u magento2 magento2-devbox-web \
    php -f /home/magento2/scripts/devbox magento:setup \
        --use-existing-sources=$use_existing_sources \
        --install-sample-data=$install_sample_data \
        --backend-path=$backend_path \
        --admin-user=$admin_user \
        --admin-password=$admin_password \
        --rabbitmq-install=$install_rabbitmq \
        --rabbitmq-host=$rabit_host \
        --rabbitmq-port=$rabbit_port

if [[ $install_redis = 1 ]]; then
    docker exec -it --privileged -u magento2 magento2-devbox-web \
        php -f /home/magento2/scripts/devbox magento:setup:redis \
            --as-all-cache=$redis_cache \
            --as-cache=$redis_fpc \
            --as-session=$redis_session \
            --host=$redis_host \
            --magento-path=$magento_path
fi

if [[ $varnish_fpc = 1 ]]; then
    varnish_file=/home/magento2/scripts/default.vcl

    docker exec -it --privileged -u magento2 magento2-devbox-web \
        php -f /home/magento2/scripts/devbox magento:setup:varnish \
            --db-host=$db_host \
            --db-port=$db_port \
            --db-user=$db_user \
            --db-name=$db_name \
            --db-password=$db_password \
            --backend-host=$main_host \
            --backend-port=$main_host_port \
            --out-file-path=/home/magento2/scripts/default.vcl

    docker cp "$main_host_container:/$varnish_file" ./web/scripts/command/default.vcl
    docker cp ./web/scripts/command/default.vcl $varnish_host_container:/etc/varnish/default.vcl
    rm ./web/scripts/command/default.vcl

    docker-compose restart varnish
fi

docker exec -it --privileged -u magento2 magento2-devbox-web mysql -h db -u root -proot -e 'CREATE DATABASE IF NOT EXISTS magento_integration_tests;'
docker cp ./web/integration/install-config-mysql.php magento2-devbox-web:/var/www/magento2/dev/tests/integration/etc/install-config-mysql.php

if [[ ! $static_deploy ]]; then
    static_deploy=1
fi

if [[ ! $static_grunt_compile ]]; then
    static_grunt_compile=1
fi

if [[ ! $di_compile ]]; then
    di_compile=1
fi

docker exec -it --privileged -u magento2 magento2-devbox-web \
    php -f /home/magento2/scripts/devbox magento:prepare \
        --static-deploy=$static_deploy \
        --static-grunt-compile=$static_grunt_compile \
        --di-compile=$di_compile
