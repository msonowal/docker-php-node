FROM php:7.1-fpm-alpine

LABEL maintainer="manash149@gmail.com"

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/msonowal/docker-php-node.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.description="Docker For PHP/Laravel Developers - Docker image with PHP 7.1 and NodeJS and Yarn with additional PHP extensions on official PHP Alpine flavour" \
      org.label-schema.url="https://github.com/msonowal/docker-php-node"

RUN echo $PHP_INI_DIR
# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync

RUN php -m \
      && install-php-extensions bcmath pcntl zip opcache pdo_mysql sockets gmp gd exif xdebug redis mongodb \
      && apk add --no-cache \
      git \
      openssh-client \
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

RUN echo "---> Installing Composer" && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer self-update --1 && \
    composer -V

RUN composer global require hirak/prestissimo && \
    composer global require \
    phpunit/phpunit phpunit/phpcov \
    jakub-onderka/php-var-dump-check \
    jakub-onderka/php-parallel-lint \
    phpmd/phpmd squizlabs/php_codesniffer \
    symfony/phpunit-bridge \
    laravel/envoy \
    phpstan/phpstan && \
    ln -sn /root/.composer/vendor/bin/parallel-lint /usr/local/bin/parallel-lint && \
    ln -sn /root/.composer/vendor/bin/var-dump-check /usr/local/bin/var-dump-check && \
    ln -sn /root/.composer/vendor/bin/phpunit /usr/local/bin/phpunit && \
    ln -sn /root/.composer/vendor/bin/phpcov /usr/local/bin/phpcov && \
    ln -sn /root/.composer/vendor/bin/phpmd /usr/local/bin/phpmd && \
    ln -sn /root/.composer/vendor/bin/phpcs /usr/local/bin/phpcs && \
    ln -sn /root/.composer/vendor/bin/phpunit-bridge /usr/local/bin/phpunit-bridge && \
    ln -sn /root/.composer/vendor/bin/envoy /usr/local/bin/envoy && \
    ln -sn /root/.composer/vendor/bin/phpstan /usr/local/bin/phpstan && \
    wget https://phar.phpunit.de/phpcpd.phar && \
    mv phpcpd.phar /usr/local/bin/phpcpd && \
    wget https://github.com/fabpot/local-php-security-checker/releases/download/v1.0.0/local-php-security-checker_1.0.0_linux_amd64 && \
    mv local-php-security-checker_1.0.0_linux_amd64 /usr/local/bin/security-checker && \
    chmod +x /usr/local/bin/security-checker
#     ln -sn /root/.composer/vendor/bin/phpinsights /usr/local/bin/phpinsights && \

#RUN wget https://github.com/phpDocumentor/phpDocumentor2/releases/download/v2.9.0/phpDocumentor.phar
#RUN echo -e "#!/bin/bash\n\nphp /phpDocumentor.phar \$@" >> /usr/local/bin/phpdoc && \
#    chmod +x /usr/local/bin/phpdoc

RUN parallel-lint -V && \
    var-dump-check && \
    phpunit --version && \
    phpcov -V && \
    phpcs --version
#RUN apk add --no-cache nodejs nodejs-npm yarn

ENV YARN_VERSION 1.22.5
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
