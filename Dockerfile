FROM alpine:3.9

LABEL maintainer="manash.sonowal@conversionbug.com"

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/msonowal/docker-php7.1-node-8.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.description="Docker For PHP/Laravel Developers - Docker image with PHP CLI 7.2 and NodeJS and Yarn with additional PHP extensions, and Alpine 3.8" \
      org.label-schema.url="https://github.com/msonowal/docker-php7.1-node-8"

ENV \
    # When using Composer, disable the warning about running commands as root/super user
    COMPOSER_ALLOW_SUPERUSER=1 \
    # Persistent runtime dependencies
    DEPS="php7.2 \
        php7.2-phar \
        php7.2-bcmath \
        php7.2-bz2 \
        php7.2-calendar \
        php7.2-curl \
        php7.2-ctype \
        php7.2-dom \
        php7.2-exif \
        php7.2-fileinfo \
        php7.2-ftp \
        php7.2-gmp \
        php7.2-gd \
        php7.2-iconv \
        php7.2-json \
        php7.2-mbstring \
        php7.2-mysqlnd \
        php7.2-mongodb \
        php7.2-opcache \
        php7.2-openssl \
        php7.2-pdo \
        php7.2-pdo_sqlite \
        php7.2-pdo_mysql \
        php7.2-pear \
        php7.2-posix \
        php7.2-session \
        php7.2-shmop \
        php7.2-simplexml \
        php7.2-sockets \
        php7.2-sqlite3 \
        php7.2-sysvsem \
        php7.2-sysvshm \
        php7.2-sysvmsg \
        php7.2-tokenizer \
        php7.2-xml \
        php7.2-xmlreader \
        php7.2-xmlwriter \
        php7.2-xdebug \
        php7.2-zip \
        php7.2-zlib \
        php7.2-pcntl \
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
    && apk add --no-cache $DEPS


RUN ls /usr/lib/php/7.2 -l

RUN php --ini

# Enable Xdebug Copy xdebug configuration for remote debugging
COPY ./xdebug.ini /etc/php7.2/conf.d/xdebug.ini

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
#RUN apk add --no-cache nodejs nodejs-npm yarn
RUN apk add --no-cache nodejs

ENV YARN_VERSION 1.16.0
ADD https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v${YARN_VERSION}.tar.gz /opt/yarn.tar.gz

RUN yarnDirectory=/opt && \
   mkdir -p "$yarnDirectory" && \
   tar -xzf /opt/yarn.tar.gz -C "$yarnDirectory" && \
   ls -l "$yarnDirectory" && \
   mv "$yarnDirectory/yarn-v${YARN_VERSION}" "$yarnDirectory/yarn" && \
  ln -s "$yarnDirectory/yarn/bin/yarn" /usr/local/bin/ && \
  rm /opt/yarn.tar.gz

RUN ls -l /opt

RUN ls -l /opt/yarn 

RUN node -v
#RUN npm -v
#RUN npx -v
RUN yarn -v
RUN curl -V

CMD ["php", "-a"]
