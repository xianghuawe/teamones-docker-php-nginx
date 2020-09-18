FROM alpine:3.12
LABEL Maintainer="weijer <weiwei163@foxmail.com>" \
      Description="Lightweight container with PHP-FPM 7.4 based on Alpine Linux."


ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

RUN apk --update-cache add ca-certificates && \
    echo "https://dl.bintray.com/php-alpine/v3.11/php-7.4" >> /etc/apk/repositories

RUN apk --no-cache add php php-fpm php-opcache php-mysqli php-pdo php-pdo_mysql php-pdo_sqlite php-json php-ftp php-openssl php-curl \
    php-zip php-zlib php-xml php-phar php-dom php-xmlreader php-ctype php-session php-pcntl php-posix \
    php-sockets php-redis php-bcmath php-calendar php-mbstring php-gd php-iconv supervisor curl tar tzdata  \
    autoconf dpkg-dev dpkg file g++ gcc libc-dev make php-dev php-pear pkgconf re2c pcre-dev openssl-dev libffi-dev libressl-dev libevent-dev zlib-dev libtool automake

## 安装event扩展
#RUN pecl install event \
#    && chmod -R 755 /usr/lib/php7/modules/event.so \
#    && echo extension=event.so >> /etc/php7/conf.d/00_sockets.ini \
#    && pecl clear-cache
#
#RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
#    && composer self-update \
#    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
#
## Configure PHP-FPM
#COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
#COPY config/php.ini /etc/php7/conf.d/custom.ini
#
#
## Configure supervisord
#COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#
## Setup document root
#RUN mkdir -p /var/www
#
## Make sure files/folders needed by the processes are accessable when they run under the nobody user
#RUN chown -R nobody.nobody /var/www && \
#  chown -R nobody.nobody /run
#
## Switch to use a non-root user from here on
#USER root
#
## Add application
#WORKDIR /var/www
#
## Expose the port is reachable on
#EXPOSE 8080
#
## Let supervisord start & webman
#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
