FROM php:7.4-fpm-alpine

LABEL maintainer="manash149@gmail.com"

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/msonowal/docker-php-node.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.description="Docker For PHP/Laravel Developers - Docker image with PHP 7.4 and NodeJS and Yarn with additional PHP extensions on official PHP Alpine flavour to use with Gitlab and other CI enviornments" \
      org.label-schema.url="https://github.com/msonowal/docker-php-node"

#RUN echo $PHP_INI_DIR
# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync

RUN php -m \
  && install-php-extensions bcmath pcntl zip opcache pdo_mysql sockets gmp gd exif xdebug redis intl pcov \
  && apk add --no-cache \
  openssh-client \
  git \
  && php -m

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
    php -i

# php composer-setup.php --version=1.10.16

RUN echo "---> Installing Composer" && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    echo "---> Cleaning up" && \
    rm -rf /tmp/* && \
    composer -V

# RUN composer global require hirak/prestissimo && \
RUN composer global require \
    #php-parallel-lint/php-parallel-lint \
    #php-parallel-lint/php-console-highlighter \
    #jakub-onderka/php-var-dump-check \
    phpunit/phpunit phpunit/phpcov \
    phpmd/phpmd squizlabs/php_codesniffer \
    symfony/phpunit-bridge \
    laravel/envoy \
    laravel/vapor-cli \
    phpstan/phpstan \
    nunomaduro/phpinsights && \
    # ln -sn /root/.composer/vendor/bin/parallel-lint /usr/local/bin/parallel-lint && \
    #ln -sn /root/.composer/vendor/bin/php-parallel-lint /usr/local/bin/php-parallel-lint && \
    #ln -sn /root/.composer/vendor/bin/var-dump-check /usr/local/bin/var-dump-check && \
    ln -sn /root/.composer/vendor/bin/phpunit /usr/local/bin/phpunit && \
    ln -sn /root/.composer/vendor/bin/phpcov /usr/local/bin/phpcov && \
    ln -sn /root/.composer/vendor/bin/phpmd /usr/local/bin/phpmd && \
    ln -sn /root/.composer/vendor/bin/phpcs /usr/local/bin/phpcs && \
    ln -sn /root/.composer/vendor/bin/phpunit-bridge /usr/local/bin/phpunit-bridge && \
    ln -sn /root/.composer/vendor/bin/envoy /usr/local/bin/envoy && \
    ln -sn /root/.composer/vendor/bin/phpstan /usr/local/bin/phpstan && \
    ln -sn /root/.composer/vendor/bin/vapor /usr/local/bin/vapor && \
    wget https://phar.phpunit.de/phpcpd.phar && \
    mv phpcpd.phar /usr/local/bin/phpcpd && \
    chmod +x /usr/local/bin/phpcpd && \
    wget https://github.com/fabpot/local-php-security-checker/releases/download/v2.0.6/local-php-security-checker_2.0.6_linux_amd64 && \
    mv local-php-security-checker_2.0.6_linux_amd64 /usr/local/bin/security-checker && \
    chmod +x /usr/local/bin/security-checker

RUN phpunit --version && \
    phpcov --version && \
    phpcs --version && \
    phpcpd --version
    #php-parallel-lint -V && \
    #var-dump-check && \
#RUN apk add --no-cache nodejs nodejs-npm yarn

ENV YARN_VERSION 1.22.19
ADD https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v${YARN_VERSION}.tar.gz /opt/yarn.tar.gz

RUN echo "Install NODE AND YARN" && \
   apk add --no-cache nodejs npm && \
   yarnDirectory=/opt && \
   mkdir -p "$yarnDirectory" && \
   tar -xzf /opt/yarn.tar.gz -C "$yarnDirectory" && \
  #  ls -l "$yarnDirectory" && \
   mv "$yarnDirectory/yarn-v${YARN_VERSION}" "$yarnDirectory/yarn" && \
   ln -s "$yarnDirectory/yarn/bin/yarn" /usr/local/bin/ && \
   rm /opt/yarn.tar.gz && \
   node -v && \
   yarn -v && \
   npm -v && \
   curl -V

CMD ["php", "-a"]
