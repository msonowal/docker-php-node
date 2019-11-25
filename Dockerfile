FROM alpine:3.9

LABEL maintainer="manash.sonowal@conversionbug.com"

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/msonowal/docker-php7.1-node-8.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.description="Docker For PHP/Laravel Developers - Docker image with PHP CLI 7.3 and NodeJS and Yarn with additional PHP extensions, and Alpine 3.8" \
      org.label-schema.url="https://github.com/msonowal/docker-php7.1-node-8"

ENV \
    # When using Composer, disable the warning about running commands as root/super user
    COMPOSER_ALLOW_SUPERUSER=1 \
    # Persistent runtime dependencies
    DEPS="php7.3 \
        php7.3-phar \
        php7.3-bcmath \
        php7.3-bz2 \
        php7.3-calendar \
        php7.3-curl \
        php7.3-ctype \
        php7.3-dom \
        php7.3-exif \
        php7.3-fileinfo \
        php7.3-ftp \
        php7.3-gmp \
        php7.3-gd \
        php7.3-iconv \
        php7.3-json \
        php7.3-mbstring \
        php7.3-mysqlnd \
        php7.3-mongodb \
        php7.3-opcache \
        php7.3-openssl \
        php7.3-pdo \
        php7.3-pdo_sqlite \
        php7.3-pdo_mysql \
        php7.3-pear \
        php7.3-posix \
        php7.3-session \
        php7.3-shmop \
        php7.3-simplexml \
        php7.3-sockets \
        php7.3-sqlite3 \
        php7.3-sysvsem \
        php7.3-sysvshm \
        php7.3-sysvmsg \
        php7.3-tokenizer \
        php7.3-xml \
        php7.3-xmlreader \
        php7.3-xmlwriter \
        php7.3-xdebug \
        php7.3-zip \
        php7.3-zlib \
        php7.3-pcntl \
        curl \
        tar \
        gzip \
        bash \
        git \
        unzip \
        wget \
        rsync \
        openssh-client \
        openssh \
        sudo \
        libpng-dev \
        ca-certificates"

# PHP.earth Alpine repository for better developer experience
ADD https://repos.php.earth/alpine/phpearth.rsa.pub /etc/apk/keys/phpearth.rsa.pub

RUN set -x \
    && echo "https://repos.php.earth/alpine/v3.9" >> /etc/apk/repositories \
    && apk add --no-cache $DEPS && \
    unset DEPS

# Enable Xdebug Copy xdebug configuration for remote debugging
COPY ./xdebug.ini /etc/php7.3/conf.d/xdebug.ini
RUN ls /usr/lib/php/7.3 -l && \
    php --ini && \
    php -v

RUN echo "---> Installing Composer" && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    echo "---> Cleaning up" && \
    rm -rf /tmp/* && \
    composer -V

RUN /usr/local/bin/composer global require jakub-onderka/php-parallel-lint && \
    /usr/local/bin/composer global require jakub-onderka/php-var-dump-check && \
    /usr/local/bin/composer global require hirak/prestissimo && \
    /usr/local/bin/composer global require phpunit/phpunit && \
    /usr/local/bin/composer global require phpunit/phpcov && \
    /usr/local/bin/composer global require phpmd/phpmd && \
    /usr/local/bin/composer global require squizlabs/php_codesniffer && \
    /usr/local/bin/composer global require symfony/phpunit-bridge && \
    /usr/local/bin/composer global require laravel/envoy && \
    /usr/local/bin/composer config --global cache-dir /opt/data/cache/composer/cache-dir && \
    /usr/local/bin/composer config --global cache-vcs-dir /opt/data/cache/composer/cache-vcs-dir && \
    /usr/local/bin/composer config --global cache-repo-dir /opt/data/cache/composer/cache-repo-dir && \

#RUN wget https://github.com/phpDocumentor/phpDocumentor2/releases/download/v2.9.0/phpDocumentor.phar

#RUN echo -e "#!/bin/bash\n\nphp /phpDocumentor.phar \$@" >> /usr/local/bin/phpdoc && \
#    chmod +x /usr/local/bin/phpdoc

    ln -sn /root/.composer/vendor/bin/parallel-lint /usr/local/bin/parallel-lint && \
    ln -sn /root/.composer/vendor/bin/var-dump-check /usr/local/bin/var-dump-check && \
    ln -sn /root/.composer/vendor/bin/phpunit /usr/local/bin/phpunit && \
    ln -sn /root/.composer/vendor/bin/phpcov /usr/local/bin/phpcov && \
    ln -sn /root/.composer/vendor/bin/phpmd /usr/local/bin/phpmd && \
    ln -sn /root/.composer/vendor/bin/phpcs /usr/local/bin/phpcs && \
    ln -sn /root/.composer/vendor/bin/phpcs /usr/local/bin/phpunit-bridge && \
    ln -sn /root/.composer/vendor/bin/envoy /usr/local/bin/envoy

RUN parallel-lint -V && \
    var-dump-check && \
    phpunit --version && \
    phpcov -V && \
    phpcs --version && \
    
    echo "Install NODE AND YARN" && \
    apk add --no-cache nodejs
#RUN apk add --no-cache nodejs nodejs-npm yarn

ENV YARN_VERSION 1.19.1
ADD https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v${YARN_VERSION}.tar.gz /opt/yarn.tar.gz

RUN yarnDirectory=/opt && \
   mkdir -p "$yarnDirectory" && \
   tar -xzf /opt/yarn.tar.gz -C "$yarnDirectory" && \
   ls -l "$yarnDirectory" && \
   mv "$yarnDirectory/yarn-v${YARN_VERSION}" "$yarnDirectory/yarn" && \
  ln -s "$yarnDirectory/yarn/bin/yarn" /usr/local/bin/ && \
  rm /opt/yarn.tar.gz

RUN ls -l /opt && \
    ls -l /opt/yarn && \
    node -v && \
    yarn -v && \
    curl -V
#RUN npm -v
#RUN npx -v

CMD ["php", "-a"]
