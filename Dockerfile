FROM alpine:3.8

MAINTAINER Manash Sonowal "manash.sonowal@conversionbug.com"

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/msonowal/docker-php7.1-node-8.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.description="Docker For PHP/Laravel Developers - Docker image with PHP CLI 7.1 and NodeJS and Yarn with additional PHP extensions, and Alpine 3.8" \
      org.label-schema.url="https://github.com/msonowal/docker-php7.1-node-8"

ENV \
    # When using Composer, disable the warning about running commands as root/super user
    COMPOSER_ALLOW_SUPERUSER=1 \
    # Persistent runtime dependencies
    DEPS="php7.1 \
        php7.1-phar \
        php7.1-bcmath \
        php7.1-bz2 \
        php7.1-calendar \
        php7.1-curl \
        php7.1-ctype \
        php7.1-dom \
        php7.1-exif \
        php7.1-fileinfo \
        php7.1-ftp \
        php7.1-gmp \
        php7.1-iconv \
        php7.1-json \
        php7.1-mbstring \
        php7.1-mysqlnd \
        php7.1-mongodb \
        php7.1-opcache \
        php7.1-openssl \
        php7.1-pdo \
        php7.1-pdo_sqlite \
        php7.1-pdo_mysql \
        php7.1-pear \
        php7.1-posix \
        php7.1-session \
        php7.1-shmop \
        php7.1-simplexml \
        php7.1-sockets \
        php7.1-sqlite3 \
        php7.1-sysvsem \
        php7.1-sysvshm \
        php7.1-sysvmsg \
        php7.1-tokenizer \
        php7.1-xml \
        php7.1-xmlreader \
        php7.1-xmlwriter \
        php7.1-xdebug \
        php7.1-zip \
        php7.1-zlib \
        curl \
        tar \
        gzip \
        bash \
        git \
        unzip \
        wget \
        openssh-client \
        openssh \
        sudo \
        libpng-dev \
        ca-certificates"

# PHP.earth Alpine repository for better developer experience
ADD https://repos.php.earth/alpine/phpearth.rsa.pub /etc/apk/keys/phpearth.rsa.pub

RUN set -x \
    && echo "https://repos.php.earth/alpine/v3.8" >> /etc/apk/repositories \
    && apk add --no-cache $DEPS

 
RUN ls /usr/lib/php/7.1 -l

RUN php --ini

# Enable Xdebug Copy xdebug configuration for remote debugging
COPY ./xdebug.ini /etc/php7.1/conf.d/xdebug.ini

RUN php -v

RUN echo "---> Installing Composer" && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    echo "---> Cleaning up" && \
    rm -rf /tmp/*

RUN composer -V

RUN /usr/local/bin/composer global require jakub-onderka/php-parallel-lint && \
    /usr/local/bin/composer global require jakub-onderka/php-var-dump-check && \
    /usr/local/bin/composer global require hirak/prestissimo && \
    /usr/local/bin/composer global require phpunit/phpunit && \
    /usr/local/bin/composer global require phpunit/phpcov && \
    /usr/local/bin/composer global require phpmd/phpmd && \
    /usr/local/bin/composer global require squizlabs/php_codesniffer && \
    /usr/local/bin/composer global require symfony/phpunit-bridge && \
    /usr/local/bin/composer global require laravel/envoy

RUN /usr/local/bin/composer config --global cache-dir /opt/data/cache/composer/cache-dir
RUN /usr/local/bin/composer config --global cache-vcs-dir /opt/data/cache/composer/cache-vcs-dir
RUN /usr/local/bin/composer config --global cache-repo-dir /opt/data/cache/composer/cache-repo-dir

#RUN wget https://github.com/phpDocumentor/phpDocumentor2/releases/download/v2.9.0/phpDocumentor.phar

#RUN echo -e "#!/bin/bash\n\nphp /phpDocumentor.phar \$@" >> /usr/local/bin/phpdoc && \
#    chmod +x /usr/local/bin/phpdoc

RUN ln -sn /root/.composer/vendor/bin/parallel-lint /usr/local/bin/parallel-lint && \
    ln -sn /root/.composer/vendor/bin/var-dump-check /usr/local/bin/var-dump-check && \
    ln -sn /root/.composer/vendor/bin/phpunit /usr/local/bin/phpunit && \
    ln -sn /root/.composer/vendor/bin/phpcov /usr/local/bin/phpcov && \
    ln -sn /root/.composer/vendor/bin/phpmd /usr/local/bin/phpmd && \
    ln -sn /root/.composer/vendor/bin/phpcs /usr/local/bin/phpcs && \
    ln -sn /root/.composer/vendor/bin/phpcs /usr/local/bin/phpunit-bridge && \
    ln -sn /root/.composer/vendor/bin/envoy /usr/local/bin/envoy

RUN parallel-lint -V
RUN var-dump-check
RUN phpunit --version
RUN phpcov -V
RUN phpcs --version

RUN echo "Install NODE AND YARN"
RUN apk add --no-cache nodejs nodejs-npm yarn

RUN node -v
RUN npm -v
RUN yarn -v

CMD ["php", "-a"]
