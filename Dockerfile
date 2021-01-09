FROM php:7.4.14-cli-alpine
LABEL Maintainer="weijer <weiwei163@foxmail.com>" \
      Description="Webman Lightweight container with PHP 7.4 based on Alpine Linux."

# Add repos
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Add basics first
RUN apk update && apk upgrade && apk add \
	bash curl ca-certificates openssl openssh git nano libxml2-dev tzdata icu-dev openntpd libedit-dev libzip-dev libjpeg-turbo-dev libpng-dev freetype-dev \
	    autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c pcre-dev openssl-dev libffi-dev libressl-dev libevent-dev zlib-dev libtool automake \
        openldap openldap-dev supervisor php-pear php-devel

RUN docker-php-ext-install soap zip pcntl sockets intl exif opcache pdo pdo_mysql mysqli bcmath calendar gd ldap json ftp openssl curl zlib xml phar \
    dom xmlreader ctype session fileinfo tokenizer simplexml xmlwriter mbstring iconv

RUN pecl install -o -f redis \
    && pecl install -o -f event \
    && pecl install -o -f amqp \
    && docker-php-ext-enable redis \
    && docker-php-ext-enable amqp \
    && echo extension=event.so >> /usr/local/etc/php/conf.d/docker-php-ext-sockets.ini \
    && pecl clear-cache

ARG swoole

##
# ---------- env settings ----------
##
ENV SWOOLE_VERSION=${swoole:-"4.5.10"} \
        #  install and remove building packages
        PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c pcre-dev zlib-dev libtool automake"

# update
RUN set -ex \
        && apk update \
        # for swoole extension libaio linux-headers
        && apk add --no-cache libstdc++ openssl git bash \
        && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS libaio-dev openssl-dev \
        # download
        && cd /tmp \
        && curl -SL "https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz" -o swoole.tar.gz \
        && ls -alh \
        # php extension:swoole
        && cd /tmp \
        && mkdir -p swoole \
        && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
        && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-mysqlnd --enable-openssl \
        && make -s -j$(nproc) && make install \
        ) \
        && printf "extension=swoole.so\n\
        swoole.use_shortname = 'Off'\n\
        swoole.enable_coroutine = 'Off'\n\
        " >/usr/local/etc/php/conf.d/swoole.ini \
        # clear
        && php -v \
        && php -m \
        && php --ri swoole \
        # ---------- clear works ----------
        && apk del .build-deps \
        && rm -rf /var/cache/apk/* /tmp/* /usr/share/man

RUN php -m

# Add Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Configure PHP
COPY config/php.ini /usr/local/etc/php/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

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

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
