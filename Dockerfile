FROM php:8.1-fpm-alpine

LABEL maintainer="manash149@gmail.com"

LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-url="https://github.com/msonowal/docker-php-node.git" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.description="Docker For PHP/Laravel Developers - Docker image with PHP 8.1 and NodeJS LTS and Yarn with additional PHP extensions on official PHP Alpine flavour to use with Gitlab and other CI enviornments Fully tested" \
    org.label-schema.url="https://github.com/msonowal/docker-php-node"

#WORKDIR /var/www/html
# RUN echo $PHP_INI_DIR
# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

RUN php -m \
    && install-php-extensions \
    bcmath pcntl zip opcache pdo_mysql sockets gmp gd exif redis mongodb intl pcov \
    && apk add --no-cache \
    git \
    openssh-client \
    zip unzip \
    ca-certificates \
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

RUN composer global require \
    phpunit/phpunit phpunit/phpcov \
    phpmd/phpmd squizlabs/php_codesniffer \
    symfony/phpunit-bridge \
    laravel/envoy \
    laravel/vapor-cli \
    laravel/pint \
    phpstan/phpstan && \
    ln -sn /root/.composer/vendor/bin/phpunit /usr/local/bin/phpunit && \
    ln -sn /root/.composer/vendor/bin/phpcov /usr/local/bin/phpcov && \
    ln -sn /root/.composer/vendor/bin/phpmd /usr/local/bin/phpmd && \
    ln -sn /root/.composer/vendor/bin/phpcs /usr/local/bin/phpcs && \
    ln -sn /root/.composer/vendor/bin/phpunit-bridge /usr/local/bin/phpunit-bridge && \
    ln -sn /root/.composer/vendor/bin/envoy /usr/local/bin/envoy && \
    ln -sn /root/.composer/vendor/bin/phpstan /usr/local/bin/phpstan && \
    ln -sn /root/.composer/vendor/bin/vapor /usr/local/bin/vapor && \
    ln -sn /root/.composer/vendor/bin/pint /usr/local/bin/pint && \
    wget https://phar.phpunit.de/phpcpd.phar && \
    mv phpcpd.phar /usr/local/bin/phpcpd && \
    chmod +x /usr/local/bin/phpcpd && \
    wget https://github.com/fabpot/local-php-security-checker/releases/download/v2.0.6/local-php-security-checker_2.0.6_linux_amd64 && \
    mv local-php-security-checker_2.0.6_linux_amd64 /usr/local/bin/security-checker && \
    chmod +x /usr/local/bin/security-checker

RUN phpunit --version && \
    phpcov --version && \
    phpcs --version && \
    phpcpd --version && \
    envoy -v
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

RUN echo "add aws cli" && \
    apk add --no-cache aws-cli && \
    aws --version

CMD ["php", "-a"]
