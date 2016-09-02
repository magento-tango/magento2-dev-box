# 1. linux, php 70 [x]
# 2. mounted directory [x]
# 3. node, gulp, grunt,
# 4. blackfireio,
# 5. email-write-to-file, phpunit, composer, xdebug

FROM php:7.0.9-apache
MAINTAINER "Oleksandr Iegorov <oiegorov@magento.com>"

RUN apt-get update && apt-get install -y \
    varnish \
    htop \
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
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) mcrypt intl xsl gd zip pdo_mysql opcache \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && docker-php-ext-install opcache \
    && pecl install xdebug && docker-php-ext-enable xdebug \
    && echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.profiler_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.max_nesting_level=1000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN apt-get clean && apt-get update && apt-get install -y nodejs \
    && ln -s /usr/bin/nodejs /usr/bin/node

RUN apt-get clean && apt-get update && apt-get install -y npm \
    && npm update -g npm && npm install -g grunt-cli && npm install -g gulp

RUN docker-php-ext-install bcmath

RUN echo "vcl 4.0;backend default {.host = "127.0.0.1";.port = "80";}" > /etc/varnish/default.vcl

RUN a2enmod rewrite

# Site config
ADD default.conf /etc/apache2/sites-enabled/default.conf
RUN rm -f /etc/apache2/sites-enabled/000-default.conf
RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# PHP config
ADD php.ini /usr/local/etc/php

RUN curl -sS https://accounts.magento.cloud/cli/installer | php
ENV PATH /root/.magento-cloud/bin:$PATH
WORKDIR /root

EXPOSE 9000 80
CMD ["apache2-foreground"]