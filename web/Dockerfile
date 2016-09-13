FROM php:7.0.10-fpm
MAINTAINER "Oleksandr Iegorov <oiegorov@magento.com>"

RUN apt-get update && apt-get install -y \
    apt-utils \
    cron \
    curl \
    libmcrypt-dev \
    libicu-dev \
    libxml2-dev libxslt1-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng12-dev \
    git \
    vim \
    openssh-server \
    supervisor \
    mysql-client \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) mcrypt intl xsl gd zip pdo_mysql opcache \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && docker-php-ext-install opcache \
    && pecl install xdebug && docker-php-ext-enable xdebug \
    && echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.max_nesting_level=1000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && mkdir /var/run/sshd \
    && apt-get clean && apt-get update && apt-get install -y nodejs \
    && ln -s /usr/bin/nodejs /usr/bin/node \
    && apt-get clean && apt-get update && apt-get install -y npm \
    && npm update -g npm && npm install -g grunt-cli && npm install -g gulp \
    && docker-php-ext-install bcmath \
    && echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
    && echo "[magento2]" >> /usr/local/etc/php-fpm.d/docker.conf \
    && echo "access.log = /proc/self/fd/2" >> /usr/local/etc/php-fpm.d/docker.conf \
    && echo "clear_env = no" >> /usr/local/etc/php-fpm.d/docker.conf \
    && echo "catch_workers_output = yes" >> /usr/local/etc/php-fpm.d/docker.conf \
    && apt-get install -y apache2 \
    && a2enmod rewrite \
    && a2enmod proxy \
    && a2enmod proxy_fcgi \
    && rm -f /etc/apache2/sites-enabled/000-default.conf \
    && useradd -m -d /home/magento2 magento2 \
    && curl -sS https://accounts.magento.cloud/cli/installer -o /home/magento2/installer

# PHP config
ADD conf/php.ini /usr/local/etc/php

# SSH config
ADD conf/sshd_config /etc/ssh/sshd_config

# supervisord config
ADD conf/supervisord.conf /etc/supervisord.conf

# php-fpm config
ADD conf/php-fpm-magento2.conf /usr/local/etc/php-fpm.d/php-fpm-magento2.conf

# apache config
ADD conf/apache-default.conf /etc/apache2/sites-enabled/apache-default.conf

ENV PATH /home/magento2/scripts/:/home/magento2/.magento-cloud/bin:$PATH

# Initial scripts
COPY scripts/ /home/magento2/scripts/
RUN cd /home/magento2/scripts && composer install

EXPOSE 80 22 44100
WORKDIR /home/magento2

USER root

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
