<p align="center">
  <img src="https://raw.githubusercontent.com/msonowal/docker-php-node/main/.github/assets/banner.svg" alt="docker-php-node: PHP 8.5, Node.js 24 LTS and Composer 2 on Alpine" width="100%">
</p>

<p align="center">
  <a href="https://github.com/msonowal/docker-php-node/actions/workflows/docker-image.yml"><img src="https://github.com/msonowal/docker-php-node/actions/workflows/docker-image.yml/badge.svg?branch=main" alt="Build status"></a>
  <a href="https://hub.docker.com/r/msonowal/docker-php-node"><img src="https://img.shields.io/docker/pulls/msonowal/docker-php-node?logo=docker&logoColor=white" alt="Docker pulls"></a>
  <a href="https://hub.docker.com/r/msonowal/docker-php-node/tags"><img src="https://img.shields.io/docker/image-size/msonowal/docker-php-node/latest?arch=amd64&logo=docker&logoColor=white&label=image%20size" alt="Image size"></a>
  <img src="https://img.shields.io/badge/PHP-8.2%20%7C%208.3%20%7C%208.4%20%7C%208.5-777BB4?logo=php&logoColor=white" alt="PHP 8.2, 8.3, 8.4, 8.5">
  <img src="https://img.shields.io/badge/Node.js-24%20LTS-5FA04E?logo=nodedotjs&logoColor=white" alt="Node.js 24 LTS">
  <img src="https://img.shields.io/badge/platform-amd64%20%7C%20arm64-1D63ED" alt="Platforms: amd64, arm64">
  <a href="https://github.com/msonowal/docker-php-node/pkgs/container/docker-php-node"><img src="https://img.shields.io/badge/ghcr.io-available-24292f?logo=github" alt="Available on GHCR"></a>
  <a href="https://github.com/msonowal/docker-php-node/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>
</p>

A ready-to-go image for **building and testing PHP / Laravel apps** in CI (GitLab CI, GitHub Actions, Bitbucket, …) and locally. PHP, Composer, Node.js, npm, Yarn and the usual QA tools are already installed, so jobs can start on `composer install` instead of on setup.

Built on the official `php:<version>-fpm-alpine` image, for `linux/amd64` and `linux/arm64`.

## Quick start

```bash
docker run --rm -it -v "$PWD":/app -w /app msonowal/docker-php-node:php85 sh
```

Also published to GitHub Container Registry:

```bash
docker pull ghcr.io/msonowal/docker-php-node:php85
```

### GitLab CI

```yaml
image: msonowal/docker-php-node:php85

test:
  script:
    - composer install --no-interaction --prefer-dist
    - npm ci && npm run build
    - vendor/bin/phpunit
```

### GitHub Actions

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container: ghcr.io/msonowal/docker-php-node:php85
    steps:
      - uses: actions/checkout@v7
      - run: composer install --no-interaction --prefer-dist
      - run: npm ci && npm run build
      - run: vendor/bin/phpunit
```

## Tags

| Tag | PHP | Upstream PHP status |
| --- | --- | --- |
| `php85`, `latest`, `edge`, `main` | 8.5 | Active support |
| `php85-cloud`, `latest-cloud` | 8.5 | Same, plus deploy and infrastructure CLIs (see [Cloud tags](#cloud-tags)) |
| `php84` | 8.4 | Active support |
| `php83` | 8.3 | Security fixes only |
| `php82` | 8.2 | Security fixes only (until Dec 2026) |
| `php81` | 8.1 | End of life, image no longer rebuilt |
| `php8`, `php80` | 8.0 | End of life, image no longer rebuilt |
| `php74`, `php73`, `php72`, `php71` | 7.x | End of life, image no longer rebuilt |

`php82` to `php85` are all built from `main` and rebuilt every week, to pick up base image and package security fixes. `nightly` and `nightly-cloud` point at the latest weekly build of `php85`. Pin a `phpXY` tag in CI rather than `latest`, so a new PHP release doesn't change your build without warning.

`php85` builds are also tagged `sha-<commit>`. Browse all tags on [Docker Hub](https://hub.docker.com/r/msonowal/docker-php-node/tags) or [GHCR](https://github.com/msonowal/docker-php-node/pkgs/container/docker-php-node).

## What's included

`php82` to `php85` all ship this set. Each Composer tool is the newest release that supports the tag's PHP version. The frozen `php81` and older tags still ship Yarn 1 without Corepack, the original `phpcpd` and `local-php-security-checker`, and no Xdebug or PostgreSQL support.

**PHP** with the development `php.ini`, plus these extensions on top of the official image's defaults:
`bcmath` `exif` `gd` `gmp` `intl` `mongodb` `opcache` `pcntl` `pcov` `pdo_mysql` `pdo_pgsql` `pgsql` `redis` `sockets` `zip`, and Xdebug (installed, off by default)

**JavaScript:** Node.js 24 LTS (from Alpine's packages), npm, and [Corepack](https://github.com/nodejs/corepack) for Yarn and pnpm. See [Yarn and pnpm](#yarn-and-pnpm).

**Composer 2**, plus these tools on `PATH`. Each is installed in its own directory under `/opt/tools`, so their dependencies can't conflict.

| Tool | Command |
| --- | --- |
| [PHPUnit](https://phpunit.de) | `phpunit` |
| [phpcov](https://github.com/sebastianbergmann/phpcov) | `phpcov` |
| [PHPStan](https://phpstan.org) | `phpstan` |
| [Laravel Pint](https://laravel.com/docs/pint) | `pint` |
| [PHP CS Fixer](https://cs.symfony.com) | `php-cs-fixer` |
| [PHP_CodeSniffer](https://github.com/PHPCSStandards/PHP_CodeSniffer) | `phpcs`, `phpcbf` |
| [PHPMD](https://phpmd.org) | `phpmd` |
| [phpcpd](https://github.com/systemsdk/phpcpd) (maintained fork) | `phpcpd` |
| [composer-normalize](https://github.com/ergebnis/composer-normalize) | `composer normalize` |
| [composer-unused](https://github.com/composer-unused/composer-unused) | `composer-unused` |
| [ComposerRequireChecker](https://github.com/maglnet/ComposerRequireChecker) | `composer-require-checker` |
| `composer audit` | `security-checker` (see below) |
| [Laravel Envoy](https://laravel.com/docs/envoy) | `envoy` |
| [Laravel Vapor CLI](https://docs.vapor.build) | `vapor` |
| [Laravel installer](https://laravel.com/docs/installation) | `laravel` |
| [Laravel Cloud CLI](https://github.com/laravel/cloud-cli) (PHP 8.4 and newer) | `cloud` |

**Also:** AWS CLI v2, [GitHub CLI](https://cli.github.com) (`gh`), [GitLab CLI](https://gitlab.com/gitlab-org/cli) (`glab`), MariaDB / MySQL client, PostgreSQL 18 client, git, openssh-client, curl, bash, jq, [yq](https://github.com/mikefarah/yq), envsubst, rsync, make, patch, zstd, tzdata, zip / unzip

**Code coverage** uses `pcov`. Xdebug is installed but not loaded. Turn it on for a single command with `php -dzend_extension=xdebug`, or for a whole job (as root) with:

```bash
echo "zend_extension=xdebug" > "$PHP_INI_DIR/conf.d/xdebug.ini"
```

**`security-checker`** now runs `composer audit --locked`, because [local-php-security-checker](https://github.com/fabpot/local-php-security-checker) is archived. It still accepts the old `--path`, `--format=json`, `--no-dev` and `--disable-exit-code` options, and exits non-zero when `composer.lock` has a package with a known advisory.

## Yarn and pnpm

`yarn` and `pnpm` come from Corepack, which uses whatever version the project pins in `package.json`:

```json
{ "packageManager": "yarn@4.18.1" }
```

- A project that pins nothing gets **Yarn 1.22.22**, as before.
- The Yarn 4 and pnpm versions pinned in the [Dockerfile](Dockerfile) are pre-installed (currently 4.18.1 and 12.15.0), so projects pinned to them work offline. Any other pinned version is downloaded on first use.
- Non-root users can't write to `/opt/corepack`. If such a job needs a version that isn't pre-installed, set `COREPACK_HOME=$HOME/.cache/corepack`.

Yarn 4 keeps its cache outside the project by default. GitLab CI can only cache paths inside the project, so point both Yarn versions at one folder there:

```yaml
variables:
  YARN_ENABLE_GLOBAL_CACHE: "false" # Yarn 4: use YARN_CACHE_FOLDER
  YARN_CACHE_FOLDER: .yarn-cache # Yarn 1 and Yarn 4

cache:
  paths:
    - .yarn-cache
```

## Cloud tags

`php85-cloud` and `latest-cloud` are the same image plus these CLIs, for deploy and infrastructure jobs. They are about 1 GB larger uncompressed, so use them only in the jobs that need them.

| Tool | Command |
| --- | --- |
| [Docker CLI](https://docs.docker.com/reference/cli/docker/) with buildx and compose | `docker` |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) | `kubectl` |
| [Helm 4](https://helm.sh) | `helm` |
| [OpenTofu](https://opentofu.org) | `tofu` |
| [Terraform](https://developer.hashicorp.com/terraform) | `terraform` |
| [Google Cloud CLI](https://cloud.google.com/sdk/gcloud) with the GKE auth plugin | `gcloud` |
| [Firebase CLI](https://firebase.google.com/docs/cli) | `firebase` |

- The Docker CLI needs a daemon. In GitLab CI, add a `docker:dind` service and set `DOCKER_HOST`.
- gcloud ships without `bq` and `gsutil`; use `gcloud storage` instead of `gsutil`.
- Authenticate gcloud and Firebase with `GOOGLE_APPLICATION_CREDENTIALS`, or with workload identity federation.

## Deploying with Bref

[Bref](https://bref.sh) belongs in your project, not in the image. Add `bref/bref` to `composer.json`, then deploy with [osls](https://github.com/oss-serverless/osls), the open-source Serverless Framework fork that Bref recommends:

```bash
npm install --save-dev osls
npx osls deploy
```

- osls 4 refuses to run when `serverless.yml` pins `frameworkVersion: '3'`. Projects that still pin v3 should install `osls@legacy` instead.
- Serverless Framework v4 needs a Serverless account key even to package, so osls is the simpler choice in CI.

## Verifying images

Every tag built from `main` (`php82` to `php85`, `latest` and the `-cloud` tags) is signed with [cosign](https://github.com/sigstore/cosign) keyless signing, and carry SBOM and SLSA provenance attestations.

```bash
cosign verify ghcr.io/msonowal/docker-php-node:php85 \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity https://github.com/msonowal/docker-php-node/.github/workflows/docker-image.yml@refs/heads/main

docker buildx imagetools inspect ghcr.io/msonowal/docker-php-node:php85 --format '{{ json .SBOM }}'
```

## Building locally

```bash
docker build -t docker-php-node .

# another PHP version, or the -cloud variant
docker build --build-arg PHP_VERSION=8.3 -t docker-php-node:php83 .
docker build --target cloud -t docker-php-node:cloud .

# the smoke test CI runs in every image
docker run --rm -v "$PWD/tests:/tests:ro" docker-php-node:php83 sh /tests/smoke.sh 8.3
```

CI builds every PHP version for `linux/amd64` and `linux/arm64`, each natively on its own GitHub-hosted runner, then merges them into multi-arch tags. See [`.github/workflows/docker-image.yml`](.github/workflows/docker-image.yml).

Every run also does the following:
- Lints the Dockerfile, workflow and scripts with hadolint, actionlint, zizmor and shellcheck.
- Runs [`tests/smoke.sh`](tests/smoke.sh) in each image before pushing it. The test checks the PHP version, extensions and every tool, then installs and tests a small project with Composer, PHPUnit and npm.
- Scans each published image with Trivy and reports the results to code scanning.

Pull requests build and test every image without publishing anything. Images are published only from `main`.

Renovate keeps the pinned versions up to date. It merges minor and patch updates once CI passes, and leaves major updates for review. Planned work is in [`docs/ROADMAP.md`](docs/ROADMAP.md).
