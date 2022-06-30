FROM alpine:3.16
LABEL Maintainer="Tim de Pater <code@trafex.nl>" \
      Description="Lightweight container with PHP 8.1 based on Alpine Linux."

# 本地编译 替换为国内镜像
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# Install packages and remove default server definition
RUN apk update && \
    apk --no-cache add  \
    php81  \
    php81-opcache  \
    php81-mysqli  \
    php81-pdo  \
    php81-pcntl  \
    php81-pecl-event  \
    php81-pdo_mysql  \
    php81-pdo_sqlite  \
    php81-json  \
    php81-ftp  \
    php81-exif  \
    php81-posix  \
    php81-openssl  \
    php81-curl \
    php81-zip  \
    php81-zlib  \
    php81-xml  \
    php81-phar  \
    php81-intl  \
    php81-dom  \
    php81-xmlreader  \
    php81-ctype  \
    php81-session  \
    php81-fileinfo  \
    php81-tokenizer  \
    php81-simplexml  \
    php81-xmlwriter  \
    php81-pecl-amqp \
    php81-sockets  \
    php81-redis  \
    php81-bcmath  \
    php81-calendar  \
    php81-mbstring  \
    php81-gd  \
    php81-iconv  \
    supervisor  \
    curl  \
    tar  \
    tzdata \
    gnu-libiconv

#RUN apk add --no-cache --repository https://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv

# libiconv load
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN ln -s /usr/bin/php81 /usr/bin/php

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && composer self-update

# Configure PHP-FPM
COPY config/php.ini /etc/php81/conf.d/custom.ini

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
