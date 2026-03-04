# Ruby on Rails Stack Profile

## Package Manager
- Bundler (Gemfile, Gemfile.lock)
- `bundle install`, `bundle update`

## Build & Run
- Server: `bin/rails server` or `bin/dev` (with Procfile.dev)
- Console: `bin/rails console`
- Routes: `bin/rails routes`

## Testing
- Frameworks: RSpec (preferred) or Minitest
- Run: `bundle exec rspec` or `bin/rails test`
- Single file: `bundle exec rspec spec/models/user_spec.rb`
- Single test: `bundle exec rspec spec/models/user_spec.rb:42`
- System tests: `bundle exec rspec spec/system/` (Capybara + Selenium)
- Factories: FactoryBot — check `spec/factories/`
- Fixtures: `test/fixtures/` (Minitest style)
- Coverage: SimpleCov — check `coverage/` after run
- Convention: `spec/` mirrors `app/` structure

## Linting & Formatting
- Linter: `rubocop`, `rubocop -a` (auto-fix safe cops)
- JSON output: `rubocop --format json`
- Config: `.rubocop.yml`
- ERB linting: `erb_lint` if available

## Security Scanners
- Brakeman — Rails-specific SAST (SQLi, XSS, mass assignment, command injection)
  Run: `brakeman -f json --quiet`
- bundler-audit — known CVEs in gems
  Run: `bundle audit check --format json`
- Semgrep — has Ruby/Rails rules
- Gitleaks / Trivy — secrets + dependency CVEs

## Common Vulnerabilities
- Mass assignment: use `strong_parameters`, never `permit!`
- SQL injection: use ActiveRecord query interface, never raw SQL with interpolation
- XSS: Rails escapes by default, watch for `raw`, `html_safe`, `sanitize`
- CSRF: verify `protect_from_forgery` in ApplicationController
- Insecure direct object references: always scope queries to current user
- Session fixation: `reset_session` on login
- File upload: validate content type, don't trust extension, use ActiveStorage
- Open redirect: validate redirect URLs against whitelist
- Secrets: Rails credentials (`bin/rails credentials:edit`), never ENV in code

## Database
- ORM: ActiveRecord
- Migrations: `bin/rails generate migration`, `bin/rails db:migrate`
- Rollback: `bin/rails db:rollback`
- Schema: `db/schema.rb` (check into git)
- Seeds: `db/seeds.rb`
- Indexes: add for foreign keys, frequently queried columns, unique constraints
- N+1: use `includes`, `preload`, `eager_load` — detect with `bullet` gem

## Dependencies
- Lockfile: Gemfile.lock (always commit)
- Audit: `bundle audit`, `bundler-audit`
- Outdated: `bundle outdated`

## DevOps
- Docker: Ruby image, `bundle install` in build, multi-stage for smaller image
- CI: `bundle install` → `rubocop` → `brakeman` → `rspec` → deploy
- Assets: `bin/rails assets:precompile` (for Sprockets/Propshaft)
- Background jobs: Sidekiq, GoodJob, or SolidQueue — check Gemfile
- Caching: Redis or Memcached — check config/environments/production.rb
- Deploy: Kamal, Capistrano, or container-based

## Architecture Patterns
- Service objects: `app/services/` — single responsibility, `.call` interface
- Form objects: `app/forms/` — for complex multi-model forms
- Query objects: `app/queries/` — complex database queries
- Concerns: `app/models/concerns/`, `app/controllers/concerns/`
- Serializers: ActiveModelSerializers, Blueprinter, or jbuilder
- API: `module Api::V1` namespace, token auth or Devise+Doorkeeper
- Background: jobs in `app/jobs/`, idempotent, retriable

## Code Review Focus
- N+1 queries: check for loops with associations
- Missing indexes on foreign keys
- Callbacks: avoid complex chains, prefer service objects
- Fat controllers: business logic should be in models/services
- Scoping: always `current_user.things` not `Thing.find(params[:id])`
- Migrations: reversible? data migration separate from schema migration?
