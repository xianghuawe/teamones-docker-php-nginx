FROM alpine:3.12
LABEL Maintainer="weijer <weiwei163@foxmail.com>" \
      Description="Lightweight container with PHP-FPM 7.4 based on Alpine Linux."

# Install packages and remove default server definition
RUN set -x \
    && apk add --no-cache wget ca-certificates \
       && wget -O /etc/apk/keys/phpearth.rsa.pub https://repos.php.earth/alpine/phpearth.rsa.pub \
       && echo "https://repos.php.earth/alpine/v3.9" >> /etc/apk/repositories

RUN apk search --no-cache php7.4*

#RUN apk add --no-cache php7.4 php7.4-fpm php7.4-opcache php7.4-mysqli php7.4-pdo php7.4-pdo_mysql php7.4-pdo_sqlite php7.4-json php7.4-ftp php7.4-openssl php7.4-curl \
#    php7.4-zip php7.4-zlib php7.4-xml php7.4-phar php7.4-intl php7.4-dom php7.4-xmlreader php7.4-ctype php7.4-session php7.4-fileinfo php7.4-pcntl php7.4-posix \
#    php7.4-sockets php7.4-redis php7.4-bcmath php7.4-calendar php7.4-mbstring php7.4-gd php7.4-iconv supervisor curl tar tzdata  \
#    autoconf dpkg-dev dpkg file g++ gcc libc-dev make php7.4-dev php7.4-pear pkgconf re2c pcre-dev openssl-dev libffi-dev libressl-dev libevent-dev zlib-dev libtool automake
#
#
#RUN php -v

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

# Setup document root
#RUN mkdir -p /var/www
#
## Make sure files/folders needed by the processes are accessable when they run under the nobody user
#RUN chown -R nobody.nobody /var/www && \
#  chown -R nobody.nobody /run
#
## Switch to use a non-root user from here on
#USER root
#
### Add application
#WORKDIR /var/www
#
### Expose the port is reachable on
#EXPOSE 8080

## Let supervisord start & webman
#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
