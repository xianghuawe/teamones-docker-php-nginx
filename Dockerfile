FROM php:7.4-cli-alpine
LABEL Maintainer="Thien Tran <hello@gsviec.com>" \
      Description="Lightweight container with Nginx 1.16 & PHP-FPM 7.4 based on Alpine Linux."

# Add repos
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Add basics first
RUN apk update && apk upgrade && apk add \
	bash curl ca-certificates openssl openssh git nano libxml2-dev tzdata icu-dev openntpd libedit-dev libzip-dev \
        supervisor

RUN docker-php-ext-install pdo_mysql soap zip pcntl sockets intl exif

RUN apk add php7-pecl-redis

# Add Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

#RUN set -xe && \
#        # Download PSR, see https://github.com/jbboehr/php-psr
#        curl -LO https://github.com/jbboehr/php-psr/archive/v${PSR_VERSION}.tar.gz && \
#        tar xzf ${PWD}/v${PSR_VERSION}.tar.gz && \
#        # Download Phalcon
#        curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
#        tar xzf ${PWD}/v${PHALCON_VERSION}.tar.gz && \
#        docker-php-ext-install -j $(getconf _NPROCESSORS_ONLN) \
#            ${PWD}/php-psr-${PSR_VERSION} \
#            ${PWD}/cphalcon-${PHALCON_VERSION}/build/${PHALCON_EXT_PATH} \
#        && \
#        # Remove all temp files
#        rm -r \
#            ${PWD}/v${PSR_VERSION}.tar.gz \
#            ${PWD}/php-psr-${PSR_VERSION} \
#            ${PWD}/v${PHALCON_VERSION}.tar.gz \
#            ${PWD}/cphalcon-${PHALCON_VERSION} \
#        && \
#        php -m

# Configure PHP-FPM
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R www-data.www-data /run

# Setup document root
RUN mkdir -p /var/www

# Make the document root a volume
VOLUME /var/www
#echo " > /usr/local/etc/php/conf.d/phalcon.ini
# Switch to use a non-root user from here on
USER www-data

# Add application
WORKDIR /var/www
COPY --chown=www-data src/ /var/www/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
# CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
