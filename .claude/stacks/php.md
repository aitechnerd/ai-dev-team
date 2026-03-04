# PHP Stack Profile

## Package Manager
- Composer (composer.json, composer.lock)
- `composer install`, `composer update`
- Autoload: PSR-4 via `vendor/autoload.php`

## Build & Run
- Dev server: `php artisan serve` (Laravel), `symfony serve` (Symfony)
- Console: `php artisan tinker` (Laravel), `bin/console` (Symfony)
- Routes: `php artisan route:list` (Laravel)
- Check for framework: `artisan` → Laravel, `bin/console` → Symfony, `wp-config.php` → WordPress

## Testing
- Framework: PHPUnit (standard), Pest (Laravel modern alternative)
- Run: `./vendor/bin/phpunit`, `php artisan test` (Laravel), `./vendor/bin/pest`
- Single file: `./vendor/bin/phpunit tests/Feature/AuthTest.php`
- Single test: `./vendor/bin/phpunit --filter test_user_can_login`
- Coverage: `./vendor/bin/phpunit --coverage-html coverage/`
- Mocking: Mockery, PHPUnit mocks, or Laravel fakes
- Laravel factories: `database/factories/`, `Model::factory()->create()`
- Convention: `tests/Unit/`, `tests/Feature/` (Laravel), `tests/` (generic)

## Linting & Formatting
- Static analysis: PHPStan (`phpstan analyse`), Psalm, or Phan
- Formatter: PHP-CS-Fixer (`php-cs-fixer fix`), Pint (`./vendor/bin/pint` for Laravel)
- JSON output: `phpstan analyse --error-format=json --no-progress`
- Config: `phpstan.neon`, `.php-cs-fixer.dist.php`, `pint.json`
- Strict level: PHPStan level 0-9, aim for level 6+

## Security Scanners
- PHPStan — static analysis catches type errors, dead code, logic bugs
  Run: `phpstan analyse --error-format=json`
- Composer audit — known CVEs in dependencies (built-in since Composer 2.4)
  Run: `composer audit --format=json`
- Semgrep — has PHP rules for SAST
- Gitleaks / Trivy — secrets + dependency CVEs
- RIPS (commercial) — PHP-specific SAST
- Snyk — dependency scanning

## Common Vulnerabilities
- SQL injection: use prepared statements, never concatenate user input into queries
  Laravel: Eloquent and query builder are safe, watch for `DB::raw()`, `whereRaw()`
- XSS: Blade auto-escapes `{{ }}`, watch for `{!! !!}` (raw output)
  Symfony: Twig auto-escapes, watch for `|raw` filter
- CSRF: Laravel includes middleware by default, verify `@csrf` in forms
- Mass assignment: use `$fillable` or `$guarded` on models, never `$guarded = []`
- File upload: validate MIME type server-side, don't trust extension, use storage disk
- Deserialization: `unserialize()` with user data = RCE, use `json_decode()` instead
- Command injection: `exec()`, `system()`, `shell_exec()`, `passthru()` with user input
- Path traversal: validate file paths, use `storage_path()` helpers
- Session fixation: `session()->regenerate()` on login
- Debug mode: ensure `APP_DEBUG=false` in production
- Secrets: use `.env` files, never commit, use `config()` helper not `env()` in code
- Type juggling: `==` vs `===`, PHP loose comparison quirks

## Database
- ORM: Eloquent (Laravel), Doctrine (Symfony)
- Migrations: `php artisan make:migration`, `php artisan migrate`
- Rollback: `php artisan migrate:rollback`
- Seeders: `php artisan db:seed`
- Indexes: add for foreign keys, frequently queried columns, unique constraints
- N+1: use `with()` eager loading, detect with Laravel Debugbar or Telescope
- Raw queries: avoid, but if needed use bindings: `DB::select('...', [$param])`

## Dependencies
- Lockfile: composer.lock (always commit)
- Audit: `composer audit`
- Outdated: `composer outdated`
- PHP version: check `require.php` in composer.json

## DevOps
- Docker: `php:8.x-fpm` + nginx, or `php:8.x-apache` for simpler setup
  Multi-stage: composer install in builder, copy vendor to runtime
- CI: `composer install` → `phpstan` → `phpunit` → deploy
- Process: php-fpm behind nginx, or Laravel Octane (Swoole/RoadRunner)
- Queue: `php artisan queue:work` (Redis, SQS, database driver)
- Scheduler: `php artisan schedule:run` via cron
- Cache: Redis or Memcached, `php artisan config:cache`, `php artisan route:cache`
- Deploy: Forge, Vapor (serverless), Deployer, or container-based
- Opcache: enable in production for performance

## Architecture Patterns
- Laravel: Service classes in `app/Services/`, Actions in `app/Actions/`
- Form Requests: `app/Http/Requests/` for validation
- Resources/Transformers: `app/Http/Resources/` for API responses
- Events/Listeners: decouple with `app/Events/`, `app/Listeners/`
- Jobs: `app/Jobs/` for async work, implement `ShouldQueue`
- Policies: `app/Policies/` for authorization logic
- Repositories: optional pattern for complex query logic
- Symfony: Services autowired, Controllers thin, Commands for CLI
- API: versioned routes (`/api/v1/`), API Resources, Sanctum/Passport for auth

## Code Review Focus
- Mass assignment: check `$fillable`/`$guarded` on every model
- N+1 queries: loops touching relationships without `with()`
- Raw queries: `DB::raw()`, `whereRaw()` — are bindings used?
- Authorization: `$this->authorize()` or Policy checks on every action
- Validation: FormRequest or inline `$request->validate()` — is it thorough?
- Error handling: `try/catch` around external calls, proper HTTP status codes
- Type declarations: return types and parameter types on methods
- Fat controllers: logic should be in services/actions, not controllers
- ENV usage: `env()` only in config files, `config()` everywhere else
- Debug artifacts: `dd()`, `dump()`, `var_dump()` left in code
