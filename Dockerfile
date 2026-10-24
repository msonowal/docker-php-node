FROM php:8.5-fpm-alpine

# the other OCI labels (source, version, revision, ...) are set by docker/metadata-action in CI
LABEL org.opencontainers.image.authors="manash149@gmail.com"

# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# pinned versions are kept up to date by Renovate
COPY --from=mlocati/php-extension-installer:2.12.3 /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:2.10.3 /usr/bin/composer /usr/local/bin/composer

# Xdebug is installed but not loaded, so pcov stays the coverage driver.
# Turn it on with `php -dzend_extension=xdebug`, or an ini file containing `zend_extension=xdebug`.
RUN php -m \
    && install-php-extensions \
    bcmath pcntl zip opcache pdo_mysql pdo_pgsql pgsql sockets gmp gd exif redis mongodb intl pcov xdebug \
    && rm "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" \
    && apk add --no-cache \
    git \
    openssh-client \
    zip unzip \
    ca-certificates \
    jq rsync make patch \
    mariadb-client postgresql18-client \
    && php -m

# inspired from here
# https://stackoverflow.com/a/48444443/1125961

RUN ls "$PHP_INI_DIR" -lha && \
    ls "$PHP_INI_DIR/conf.d" -lha && \
    php --ini && \
    php -v &&\
    php -i

# CI jobs run Composer as root; this also keeps global plugins like composer-normalize enabled
ENV COMPOSER_ALLOW_SUPERUSER=1

# Each tool is its own Composer project under /opt/tools, so their dependencies can't conflict
RUN set -eu; \
    tool() { \
        dir=/opt/tools/$1; package=$2; shift 2; \
        mkdir -p "$dir"; \
        composer --working-dir="$dir" require --no-interaction --no-progress --optimize-autoloader "$package"; \
        for bin in "$@"; do ln -s "$dir/vendor/bin/$bin" /usr/local/bin/; done; \
    }; \
    tool phpunit phpunit/phpunit phpunit; \
    tool phpcov phpunit/phpcov phpcov; \
    tool phpstan phpstan/phpstan phpstan; \
    tool pint laravel/pint pint; \
    tool php-cs-fixer friendsofphp/php-cs-fixer php-cs-fixer; \
    tool phpcs squizlabs/php_codesniffer phpcs phpcbf; \
    tool phpmd phpmd/phpmd phpmd; \
    tool phpcpd systemsdk/phpcpd phpcpd; \
    tool composer-unused icanhazstring/composer-unused composer-unused; \
    tool composer-require-checker maglnet/composer-require-checker composer-require-checker; \
    tool envoy laravel/envoy envoy; \
    tool vapor laravel/vapor-cli vapor; \
    composer global config --no-plugins allow-plugins.ergebnis/composer-normalize true; \
    composer global require --no-interaction --no-progress ergebnis/composer-normalize; \
    globalBin=$(composer global config bin-dir --absolute 2>/dev/null); \
    for bin in phpunit phpcov phpmd phpcs phpstan pint envoy vapor; do ln -s "/usr/local/bin/$bin" "$globalBin/"; done; \
    composer clear-cache; \
    rm -rf /tmp/*

COPY --chmod=0755 bin/security-checker /usr/local/bin/security-checker

RUN phpunit --version && \
    phpcov --version && \
    phpstan --version && \
    pint --version && \
    php-cs-fixer --version && \
    phpcs --version && \
    phpcbf --version && \
    phpmd --version && \
    phpcpd --version && \
    composer-unused --version && \
    composer-require-checker --version && \
    composer normalize --help > /dev/null && \
    security-checker --help > /dev/null && \
    envoy -v && \
    vapor --version && \
    php -r 'exit(extension_loaded("pcov") && !extension_loaded("xdebug") ? 0 : 1);' && \
    php -dzend_extension=xdebug -r 'exit(extension_loaded("xdebug") ? 0 : 1);'

# Corepack provides yarn and pnpm at whatever version a project pins in package.json "packageManager".
# Projects that pin nothing get Yarn 1, installed last so it stays the default.
# renovate: datasource=npm depName=corepack
ARG COREPACK_VERSION=0.36.0
# renovate: datasource=npm depName=@yarnpkg/cli-dist
ARG YARN_BERRY_VERSION=4.18.1
# renovate: datasource=npm depName=pnpm
ARG PNPM_VERSION=12.15.0
ARG YARN_CLASSIC_VERSION=1.22.22
ENV COREPACK_HOME=/opt/corepack \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0

RUN echo "Install Node.js and Corepack" && \
    apk add --no-cache nodejs npm && \
    npm install -g "corepack@${COREPACK_VERSION}" && \
    corepack install -g "yarn@${YARN_BERRY_VERSION}" "pnpm@${PNPM_VERSION}" && \
    corepack install -g "yarn@${YARN_CLASSIC_VERSION}" && \
    pnpm --version && \
    chmod -R a+rX "$COREPACK_HOME" && \
    npm cache clean --force && \
    node -v && \
    npm -v && \
    yarn -v && \
    curl -V

# Yarn 1 outside a project, the pinned Yarn 4 inside one, and pnpm for a non-root user, all offline
# hadolint ignore=DL3003
RUN cd /tmp && \
    test "$(yarn -v)" = "$YARN_CLASSIC_VERSION" && \
    mkdir berry && cd berry && \
    echo "{\"packageManager\": \"yarn@${YARN_BERRY_VERSION}\"}" > package.json && \
    test "$(COREPACK_ENABLE_NETWORK=0 yarn -v)" = "$YARN_BERRY_VERSION" && \
    adduser -D corepack-test && \
    su corepack-test -s /bin/sh -c 'cd /tmp && COREPACK_ENABLE_NETWORK=0 pnpm --version' && \
    deluser --remove-home corepack-test && \
    cd / && rm -rf /tmp/berry

RUN echo "add aws cli" && \
    apk add --no-cache aws-cli && \
    aws --version

CMD ["php", "-a"]
