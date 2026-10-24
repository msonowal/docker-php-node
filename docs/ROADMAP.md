# Roadmap

Planned improvements to the image and its build, from research done in October 2026. Phases 2 and 3 are implemented on the `feat/modern-tooling` branch, for `php85` only; Phase 1 is deferred.

## Findings that shaped this plan

- **The weekly rebuild silently stopped on 2026-06-03.** GitHub disables scheduled workflows in a public repo after 60 days without activity, and the last commit before 2026-10-24 was 2026-03-31. `latest` went about 20 weeks without base-image security fixes. Three of the 12 scheduled runs before that failed unnoticed.
- **`php81`–`php84` never get scheduled rebuilds**, because cron only runs on the default branch.
- **Branch pushes publish image tags** (`push: "**"`), so every feature branch leaves a tag on both registries.
- **The `php84` image description label still says "PHP 8.3".**
- **`phpcpd` and `local-php-security-checker` are archived upstream**, and the `phpunit-bridge` symlink is broken.
- **Yarn Berry projects that only set `"packageManager": "yarn@4…"` fail**, because Alpine's Node package ships without Corepack.

## Phase 1: build pipeline (deferred)

- [ ] Build every PHP version from `main` with one Dockerfile and a version matrix (`BASE_IMAGE` and `EXTRA_EXTENSIONS` build args). Only `php85` gets `latest`. Freeze the `php81`–`php84` branches. This is how jakzal/phpqa, thecodingmachine and serversideup work.
- [ ] Publish only from `main` and git tags. Pull requests build and test without pushing.
- [ ] Smoke-test each per-platform digest on its native runner before the merge job tags it: PHP version, extensions, every tool runs, and a fixture project passes `composer install`, `phpunit` and `npm ci`.
- [ ] Make the weekly rebuild reliable: schedule it off the top of the hour, and use `no-cache` on scheduled runs so `apk` and Composer layers refresh.
- [ ] Add a concurrency group that never cancels a `main` run mid-merge.

## Phase 2: image contents

- [x] Replace the Yarn 1 tarball with Corepack (pinned, from npm). Yarn 1.22.22 stays the default; Yarn 4 and pnpm are pre-cached, so pinned projects work offline.
- [x] Install each Composer tool in its own directory under `/opt/tools`, so tool dependencies can't conflict.
- [x] Replace `phpcpd` with `systemsdk/phpcpd`.
- [x] Replace `local-php-security-checker` with `composer audit`, behind a `security-checker` wrapper so existing CI jobs keep working.
- [x] Remove `symfony/phpunit-bridge` and the obsolete `xdebug.ini`.
- [x] Add `pdo_pgsql`/`pgsql`, `postgresql-client`, `mariadb-client`, `jq`, `rsync`, `make`, `patch`.
- [x] Ship Xdebug installed but disabled; pcov stays the coverage driver.
- [x] Add PHP-CS-Fixer, `composer-normalize`, `composer-unused`, `composer-require-checker`, and a `phpcbf` link.

## Phase 3: dependency updates and supply chain

- [x] Renovate, with regex managers for versions pinned in the Dockerfile. Automerge stays off until Phase 1's tests exist.
- [x] Pin every GitHub Action by commit SHA, and pin Composer and `install-php-extensions` by version.
- [x] Trivy vulnerability scan, uploaded to code scanning, non-blocking.
- [x] SBOM attestations, plus a cosign keyless signature on each registry's multi-arch index.
- [x] Lint job: hadolint, actionlint, zizmor.
- [x] OCI labels and index annotations in place of the empty `label-schema` labels.
- [x] Add a LICENSE (MIT).
- [x] Sync the README to Docker Hub.

## Later: optional variant tags

- `-browsers`: Chromium and chromedriver for Laravel Dusk, about +650 MB. Pest 4 browser tests need Playwright, which supports only Debian and Ubuntu, so that would need a Debian-based variant.
- `-octane`: Swoole, about +25–50 MB.
- Imagick adds about 130 MB, so it belongs in a variant rather than the default image.
- Not planned for the image: Rector (104 MB), Psalm, Infection, Deptrac, Bun. Larastan and Pest need the project's autoloader, so they belong in each project's `require-dev`.
