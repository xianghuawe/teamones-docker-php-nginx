FROM alpine:3.12
LABEL Maintainer="Tim de Pater <code@trafex.nl>" \
      Description="Lightweight container with Nginx 1.18 & PHP-FPM 7.3 based on Alpine Linux."

# Install packages and remove default server definition
RUN apk --no-cache add php7.4 php7.4-fpm php7.4-opcache php7.4-mysqli php7.4-pdo php7.4-pdo_mysql php7.4-pdo_sqlite php7.4-json php7.4-ftp php7.4-openssl php7.4-curl \
    php7.4-zip php7.4-zlib php7.4-xml php7.4-phar php7.4-intl php7.4-dom php7.4-xmlreader php7.4-ctype php7.4-session php7.4-fileinfo \
    php7.4-sockets php7.4-redis php7.4-bcmath php7.4-calendar php7.4-mbstring php7.4-gd php7.4-dev nginx supervisor curl && \
    rm /etc/nginx/conf.d/default.conf

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/public

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/public && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/public
COPY --chown=nobody src/ /var/www/public/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
