FROM alpine:3.7

MAINTAINER Manash Sonowal "manash.sonowal@conversionbug.com"

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
    apk add --update \
    tar \
    gzip \
    curl \
    bash \
    git \
    unzip \
    wget \
    openssh-client \
    openssh \
    sudo

RUN apk --no-cache add \
        php7 \
        php7-apcu \
        php7-ctype \
        php7-curl \
        php7-dom \
        php7-fileinfo \
        php7-ftp \
        php7-gmp \
        php7-iconv \
        php7-json \
        php7-mbstring \
        php7-pdo_mysql \
        php7-mongodb \
        php7-mysqlnd \
        php7-openssl \
        php7-pdo \
        php7-pdo_sqlite \
        php7-pear \
        php7-phar \
        php7-zip \
        php7-posix \
        php7-session \
        php7-simplexml \
        php7-sqlite3 \
        php7-tokenizer \
        php7-xml \
        php7-xmlreader \
        php7-xmlwriter \
        php7-zlib \
        php7-xdebug

#RUN apk add --no-cache php7-pear php7-dev gcc musl-dev make

# Install Xdebug
#RUN pecl install xdebug
 
RUN ls /usr/lib/php7/modules -l

RUN php --ini

# Enable Xdebug Copy xdebug configuration for remote debugging
COPY ./xdebug.ini /etc/php7/conf.d/xdebug.ini

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
    /usr/local/bin/composer global require symfony/phpunit-bridge

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
    ln -sn /root/.composer/vendor/bin/phpcs /usr/local/bin/phpunit-bridge

RUN parallel-lint -V
RUN var-dump-check
RUN phpunit --version
RUN phpcov -V
RUN phpcs --version

RUN echo "Install NODE AND YARN"

RUN apk add nodejs
RUN apk add yarn

RUN node -v
RUN npm -v
RUN yarn -v







