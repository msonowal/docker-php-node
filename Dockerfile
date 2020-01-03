FROM php:7.4-fpm-alpine

LABEL maintainer="manash.sonowal@conversionbug.com"

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/msonowal/docker-php7.1-node-8.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.description="Docker For PHP/Laravel Developers - Docker image with PHP 7.4 and NodeJS and Yarn with additional PHP extensions on official PHP Alpine flavour" \
      org.label-schema.url="https://github.com/msonowal/docker-php7.1-node-8"

RUN echo $PHP_INI_DIR
# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN php -m \
  && apk add --no-cache \
      pcre-dev ${PHPIZE_DEPS} \
      gmp \
      gmp-dev \
      freetype libjpeg-turbo freetype-dev libjpeg-turbo-dev \
      libzip zip libpng-dev zlib-dev libzip-dev \
      git \
  && docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
  && docker-php-ext-install -j$(nproc) gd \
#   && docker-php-ext-configure zip --with-libzip \
  && docker-php-ext-install zip \
  && pecl install redis-5.1.1 \
#   && pecl install zip-1.15.5 \
  && pecl install xdebug-2.9.0 \
  && docker-php-ext-enable xdebug redis \
  && docker-php-ext-install bcmath pcntl opcache pdo_mysql sockets sockets gmp \
  && apk del --no-cache freetype-dev libjpeg-turbo-dev pcre-dev libzip-dev libpng-dev ${PHPIZE_DEPS}

# inspired from here
# https://stackoverflow.com/a/48444443/1125961

# Use the default production configuration
# RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# Enable Xdebug Copy xdebug configuration for remote debugging
# COPY ./xdebug.ini "$PHP_INI_DIR/conf.d/xdebug.ini"
RUN ls "$PHP_INI_DIR" -lha && \
    ls "$PHP_INI_DIR/conf.d" -lha && \
    php --ini && \
    php -v &&\
    php -m && \
    php -i

RUN echo "---> Installing Composer" && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    echo "---> Cleaning up" && \
    rm -rf /tmp/* && \
    composer -V

RUN composer global require hirak/prestissimo && \
    composer global require jakub-onderka/php-parallel-lint \
    jakub-onderka/php-var-dump-check \
    phpunit/phpunit phpunit/phpcov \
    phpmd/phpmd squizlabs/php_codesniffer \
    symfony/phpunit-bridge \
    laravel/envoy && \
#     phpstan/phpstan && \
#     nunomaduro/phpinsights && \
#     sebastian/phpcpd && \
    # composer config --global cache-dir /opt/data/cache/composer/cache-dir && \
    # composer config --global cache-vcs-dir /opt/data/cache/composer/cache-vcs-dir && \
    # composer config --global cache-repo-dir /opt/data/cache/composer/cache-repo-dir && \
    ln -sn /root/.composer/vendor/bin/parallel-lint /usr/local/bin/parallel-lint && \
    ln -sn /root/.composer/vendor/bin/var-dump-check /usr/local/bin/var-dump-check && \
    ln -sn /root/.composer/vendor/bin/phpunit /usr/local/bin/phpunit && \
    ln -sn /root/.composer/vendor/bin/phpcov /usr/local/bin/phpcov && \
    ln -sn /root/.composer/vendor/bin/phpmd /usr/local/bin/phpmd && \
    ln -sn /root/.composer/vendor/bin/phpcs /usr/local/bin/phpcs && \
    ln -sn /root/.composer/vendor/bin/phpunit-bridge /usr/local/bin/phpunit-bridge && \
    ln -sn /root/.composer/vendor/bin/envoy /usr/local/bin/envoy
#     ln -sn /root/.composer/vendor/bin/phpstan /usr/local/bin/phpstan && \
#     ln -sn /root/.composer/vendor/bin/phpinsights /usr/local/bin/phpinsights && \
#     ln -sn /root/.composer/vendor/bin/phpcpd /usr/local/bin/phpcpd

#RUN wget https://github.com/phpDocumentor/phpDocumentor2/releases/download/v2.9.0/phpDocumentor.phar
#RUN echo -e "#!/bin/bash\n\nphp /phpDocumentor.phar \$@" >> /usr/local/bin/phpdoc && \
#    chmod +x /usr/local/bin/phpdoc

RUN parallel-lint -V && \
    var-dump-check && \
    phpunit --version && \
    phpcov -V && \
    phpcs --version
#RUN apk add --no-cache nodejs nodejs-npm yarn

ENV YARN_VERSION 1.21.1
ADD https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v${YARN_VERSION}.tar.gz /opt/yarn.tar.gz

RUN echo "Install NODE AND YARN" && \
   apk add --no-cache nodejs && \
   yarnDirectory=/opt && \
   mkdir -p "$yarnDirectory" && \
   tar -xzf /opt/yarn.tar.gz -C "$yarnDirectory" && \
   ls -l "$yarnDirectory" && \
   mv "$yarnDirectory/yarn-v${YARN_VERSION}" "$yarnDirectory/yarn" && \
   ln -s "$yarnDirectory/yarn/bin/yarn" /usr/local/bin/ && \
   rm /opt/yarn.tar.gz && \
   node -v && \
   yarn -v && \
   curl -V
#RUN npm -v
#RUN npx -v

CMD ["php", "-a"]
