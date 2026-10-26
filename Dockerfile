# CI builds each supported PHP version by setting PHP_VERSION; the default is the newest
ARG PHP_VERSION=8.5

FROM php:${PHP_VERSION}-fpm-alpine AS base

# the other OCI labels (source, version, revision, ...) are set by docker/metadata-action in CI
LABEL org.opencontainers.image.authors="manash149@gmail.com"

# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# pinned versions are kept up to date by Renovate
COPY --from=mlocati/php-extension-installer:2.12.3 /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:2.10.3 /usr/bin/composer /usr/local/bin/composer

# Upgrade the packages the base image ships with, so each weekly rebuild picks up Alpine security fixes
# without waiting for the official PHP image to be rebuilt.
# Xdebug is installed but not loaded, so pcov stays the coverage driver.
# Turn it on with `php -dzend_extension=xdebug`, or an ini file containing `zend_extension=xdebug`.
RUN apk upgrade --no-cache \
    && php -m \
    && install-php-extensions \
    bcmath pcntl zip opcache pdo_mysql pdo_pgsql pgsql sockets gmp gd exif redis mongodb intl pcov xdebug \
    && rm "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" \
    && apk add --no-cache \
    git \
    openssh-client \
    zip unzip \
    ca-certificates \
    jq rsync make patch \
    bash gettext-envsubst yq-go zstd tzdata \
    mariadb-client postgresql18-client \
    && rm -rf /var/cache/apk/* \
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
    tool laravel laravel/installer laravel; \
    # the Cloud CLI's bundled dependencies need PHP 8.4, although its composer.json allows 8.3
    if php -r 'exit(PHP_VERSION_ID >= 80400 ? 0 : 1);'; then tool cloud laravel/cloud-cli cloud; fi; \
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
    laravel --version && \
    { [ ! -e /usr/local/bin/cloud ] || cloud --version; } && \
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
    curl -V && \
    rm -rf /tmp/*

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
    cd / && rm -rf /tmp/*

RUN echo "add aws cli" && \
    apk add --no-cache aws-cli && \
    aws --version

# GitHub and GitLab CLIs, for releases and API calls from CI jobs
COPY --from=registry.gitlab.com/gitlab-org/cli:v1.124.0 /usr/bin/glab /usr/local/bin/glab

ARG TARGETARCH
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.103.2
# hadolint ignore=DL3003
RUN cd /tmp && \
    curl -fsSLO "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz" && \
    curl -fsSLO "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_checksums.txt" && \
    grep " gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz\$" "gh_${GH_VERSION}_checksums.txt" > gh.sha256 && \
    sha256sum -c gh.sha256 && \
    tar -xzf "gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz" && \
    mv "gh_${GH_VERSION}_linux_${TARGETARCH}/bin/gh" /usr/local/bin/ && \
    rm -rf /tmp/* && \
    gh --version && \
    glab --version && \
    bash --version && \
    envsubst --version && \
    yq --version && \
    zstd --version

CMD ["php", "-a"]

# The -cloud tags: the base image plus deploy and infrastructure CLIs
FROM base AS cloud

ARG TARGETARCH
ENV CHECKPOINT_DISABLE=1 \
    CLOUDSDK_PYTHON=python3 \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 \
    CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK=1 \
    CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true \
    PATH=/opt/google-cloud-sdk/bin:$PATH

# python3 is already there for aws-cli; gcloud needs it too, so ask for it explicitly
RUN apk add --no-cache docker-cli docker-cli-buildx docker-cli-compose python3

COPY --from=registry.k8s.io/kubectl:v1.37.1 /bin/kubectl /usr/local/bin/kubectl
COPY --from=ghcr.io/opentofu/opentofu:1.13.2-minimal /usr/local/bin/tofu /usr/local/bin/tofu
COPY --from=hashicorp/terraform:1.17.0 /bin/terraform /usr/local/bin/terraform

# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION=4.3.1
# hadolint ignore=DL3003
RUN cd /tmp && \
    curl -fsSLO "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" && \
    curl -fsSLO "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz.sha256sum" && \
    sha256sum -c "helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz.sha256sum" && \
    tar -xzf "helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" && \
    mv "linux-${TARGETARCH}/helm" /usr/local/bin/ && \
    rm -rf /tmp/*

# gcloud runs on the image's Python instead of its bundled glibc one.
# bq and gsutil are dropped (`gcloud storage` replaces gsutil); the GKE auth plugin is added for kubectl.
# renovate: datasource=docker depName=gcr.io/google.com/cloudsdktool/google-cloud-cli
ARG GCLOUD_VERSION=590.0.1
RUN if [ "$TARGETARCH" = arm64 ]; then arch=arm; else arch=x86_64; fi && \
    curl -fsSL -o /tmp/gcloud.tar.gz "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-${arch}.tar.gz" && \
    tar -xzf /tmp/gcloud.tar.gz -C /opt && \
    rm -rf /opt/google-cloud-sdk/platform/bundledpythonunix && \
    gcloud components remove bq gsutil --quiet && \
    gcloud components install gke-gcloud-auth-plugin --quiet --no-compile-python && \
    find /opt/google-cloud-sdk -name __pycache__ -type d -prune -exec rm -rf {} + && \
    rm -rf /opt/google-cloud-sdk/.install/.backup /root/.config/gcloud /tmp/*

# renovate: datasource=npm depName=firebase-tools
ARG FIREBASE_VERSION=15.34.1
RUN npm install -g --no-fund --no-audit "firebase-tools@${FIREBASE_VERSION}" && \
    npm cache clean --force && \
    rm -rf /root/.npm /tmp/*

RUN docker --version && \
    docker buildx version && \
    docker compose version && \
    kubectl version --client && \
    helm version && \
    tofu version && \
    terraform version && \
    gcloud version && \
    gke-gcloud-auth-plugin --version && \
    firebase --version && \
    rm -rf /root/.config/gcloud /root/.config/configstore /tmp/*

# a plain `docker build .` produces the base image
FROM base
