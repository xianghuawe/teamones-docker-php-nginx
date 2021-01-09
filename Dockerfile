FROM php:7.3.26-cli-alpine
LABEL Maintainer="Tim de Pater <code@trafex.nl>" \
      Description="Lightweight container with PHP-FPM 7.3 based on Alpine Linux."

# Install packages and remove default server definition
RUN apk update && \
    apk --no-cache add php7 php7-fpm php7-opcache php7-mysqli php7-pdo php7-pdo_mysql php7-pdo_sqlite php7-json php7-ftp php7-openssl php7-curl \
    php7-zip php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session php7-fileinfo php7-tokenizer php7-simplexml php7-xmlwriter php7-amqp \
    php7-event php7-sockets php7-redis php7-bcmath php7-calendar php7-mbstring php7-gd php7-iconv php7-tokenizer php7-pcntl php7-posix supervisor curl tar tzdata libevent-dev

RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv

# libiconv load
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

ARG swoole

##
# ---------- env settings ----------
##
ENV SWOOLE_VERSION=${swoole:-"4.5.3"} \
        #  install and remove building packages
        PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make php7-dev php7-pear pkgconf re2c pcre-dev zlib-dev libtool automake"

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
        " >/etc/php7/conf.d/swoole.ini \
        # clear
        && php -v \
        && php -m \
        && php --ri swoole \
        # ---------- clear works ----------
        && apk del .build-deps \
        && rm -rf /var/cache/apk/* /tmp/* /usr/share/man

RUN php -m


RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    && composer self-update


# Configure PHP-FPM
COPY config/php.ini /etc/php7/conf.d/custom.ini


# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /run

# Setup document root
RUN mkdir -p /app

# Make the document root a volume
VOLUME /app

# Switch to use a non-root user from here on
USER root

# Add application
WORKDIR /app

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]