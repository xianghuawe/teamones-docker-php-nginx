FROM alpine:3.16
LABEL Maintainer="Tim de Pater <code@trafex.nl>" \
      Description="Lightweight container with PHP 8.0 based on Alpine Linux."

# 本地编译 替换为国内镜像
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# Install packages and remove default server definition
RUN apk update && \
    apk --no-cache add  \
    php8  \
    php8-opcache  \
    php8-mysqli  \
    php8-pdo  \
    php8-pcntl  \
    php8-pecl-event  \
    php8-pdo_mysql  \
    php8-pdo_sqlite  \
    php8-json  \
    php8-ftp  \
    php8-exif  \
    php8-posix  \
    php8-openssl  \
    php8-curl \
    php8-zip  \
    php8-zlib  \
    php8-xml  \
    php8-phar  \
    php8-intl  \
    php8-dom  \
    php8-xmlreader  \
    php8-ctype  \
    php8-session  \
    php8-fileinfo  \
    php8-tokenizer  \
    php8-simplexml  \
    php8-xmlwriter  \
    php8-pecl-amqp \
    php8-sockets  \
    php8-redis  \
    php8-bcmath  \
    php8-calendar  \
    php8-mbstring  \
    php8-gd  \
    php8-iconv  \
    supervisor  \
    curl  \
    bash  \
    tzdata \
    gnu-libiconv

#RUN apk add --no-cache --repository https://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv

# libiconv load
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && composer self-update

# Configure PHP-FPM
COPY config/php.ini /etc/php8/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /run

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /app

RUN chown nobody /app/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
