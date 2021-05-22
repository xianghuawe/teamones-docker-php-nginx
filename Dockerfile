FROM php:7.4.14-cli-alpine3.13
LABEL Maintainer="weijer <weiwei163@foxmail.com>" \
      Description="Webman Lightweight container with PHP 7.4 based on Alpine Linux."

# Add basics first
RUN apk update && apk upgrade && apk add \
	bash curl ca-certificates openssl openssh git nano libxml2-dev tzdata icu-dev openntpd libedit-dev libzip-dev libjpeg-turbo-dev libpng-dev freetype-dev \
	    autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c pcre-dev openssl-dev libffi-dev libressl-dev libevent-dev zlib-dev libtool automake \
        supervisor

RUN docker-php-ext-install soap zip pcntl sockets intl exif opcache pdo_mysql mysqli bcmath calendar gd

RUN pecl install -o -f redis \
    && pecl install -o -f event \
    && docker-php-ext-enable redis \
    && echo extension=event.so >> /usr/local/etc/php/conf.d/docker-php-ext-sockets.ini \
    && pecl clear-cache

RUN php -m

# Add Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Copy swoole_tracker.so
COPY install/swoole_tracker.so /usr/local/lib/php/extensions/custom/swoole_tracker.so

RUN printf 'extension=/usr/local/lib/php/extensions/custom/swoole_tracker.so\napm.enable=1\napm.sampling_rate=100\napm.enable_memcheck=1' > /usr/local/etc/php/conf.d/swoole-tracker.ini

# Configure PHP
COPY config/php.ini /usr/local/etc/php/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 部署node-agent ./deploy_env.sh 服务端IP
ADD install/swoole-tracker.tar.gz /tmp
RUN tar -C / -xvf /tmp/swoole-tracker.tar.gz && \
    cd /swoole-tracker/node-agent && \
    ./deploy_env.sh 42.193.175.42 && \
    rm /tmp/swoole-tracker.tar.gz

# 添加entrypoint脚本
RUN printf '#!/bin/sh\n/opt/swoole/script/php/swoole_php /opt/swoole/node-agent/src/node.php $@' > /opt/swoole/entrypoint.sh && \
    chmod 755 /opt/swoole/entrypoint.sh

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /run

# Setup document root
RUN mkdir -p /app

# Make the document root a volume
VOLUME /app

#echo " > /usr/local/etc/php/conf.d/phalcon.ini
# Switch to use a non-root user from here on
USER root

# Add application
WORKDIR /app

# Expose the port nginx is reachable on
EXPOSE 8080

# 启用entrypoint脚本（-x方便调试， 可以去掉）
ENTRYPOINT [ "sh", "", "/opt/swoole/entrypoint.sh" ]

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
