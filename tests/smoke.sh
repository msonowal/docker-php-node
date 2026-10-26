#!/bin/sh
# Smoke test for a built image. CI runs it inside every image before publishing it:
#   docker run --rm -v "$PWD/tests:/tests:ro" <image> sh /tests/smoke.sh <PHP version> [base|cloud]
set -eu

php_version=$1
variant=${2:-base}

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

run() {
    echo "+ $*"
    "$@" > /dev/null || fail "$*"
}

actual=$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;')
[ "$actual" = "$php_version" ] || fail "expected PHP $php_version, got $actual"

modules=$(php -m)
for ext in bcmath exif gd gmp intl mongodb pcntl pcov pdo_mysql pdo_pgsql pgsql redis sockets zip 'Zend OPcache'; do
    printf '%s\n' "$modules" | grep -qixF "$ext" || fail "extension $ext is not loaded"
done
php -r 'exit(extension_loaded("xdebug") ? 1 : 0);' || fail "xdebug is loaded by default"
run php -dzend_extension=xdebug -r 'exit(extension_loaded("xdebug") ? 0 : 1);'

run composer --version
run composer normalize --help
run phpunit --version
run phpcov --version
run phpstan --version
run pint --version
run php-cs-fixer --version
run phpcs --version
run phpcbf --version
run phpmd --version
run phpcpd --version
run composer-unused --version
run composer-require-checker --version
run security-checker --help
run envoy -v
run vapor --version
run laravel --version
run cloud --version
run node --version
run npm --version
run yarn --version
run pnpm --version
run gh --version
run glab --version
run aws --version
run mariadb --version
run psql --version
run git --version
run jq --version
run yq --version
run envsubst --version
run bash --version

if [ "$variant" = cloud ]; then
    run docker --version
    run docker buildx version
    run docker compose version
    run kubectl version --client
    run helm version
    run tofu version
    run terraform version
    run gcloud version
    run gke-gcloud-auth-plugin --version
    run firebase --version
fi

# A small project: install from Packagist, run its tests with pcov coverage, install from npm
cp -R /tests/fixture /tmp/fixture
cd /tmp/fixture
run composer install --no-interaction --no-progress
report=$(phpunit --bootstrap vendor/autoload.php --coverage-filter src --coverage-text tests) || {
    printf '%s\n' "$report"
    fail "phpunit"
}
printf '%s\n' "$report" | grep -q 'Lines:' || {
    printf '%s\n' "$report"
    fail "phpunit printed no coverage report"
}
run npm ci --no-audit --no-fund
run node -e 'require("picocolors")'

echo "OK: PHP $actual, $variant"
