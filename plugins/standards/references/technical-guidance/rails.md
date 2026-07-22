---
owner: Ruby Chapter
last-reviewed: 2026-02-05
scope: Ruby on Rails projects
detection-markers:
  - Gemfile
  - config/routes.rb
  - bin/rails
  - config/application.rb
  - "*.rb"
---

# Rails Project-Type Technical Guidance

Architectural standards for Ruby on Rails projects. These extend the Global Technical Guidance.

## How to Use This Guidance

- Applies when project contains Rails markers (Gemfile, config/routes.rb, bin/rails)
- Extends Global Guidance; does not replace it
- Project-level guidance in the Intent doc may override specific standards
- Deviations require an ADR documenting the rationale

---

## New Project Setup

For **greenfield** repositories, always initialize from the Trigent Rails API template project rather than from scratch. The template scaffolds the correct project structure, gem configuration, CI/CD pipeline, and tooling required by these standards.

**Template:** https://gitlab.com/trigent1/project-templates/rails-api

Create the repository from the template before writing any code. If a repo already exists but was not initialized from the template, treat it as brownfield and match its existing patterns.

---

## Ruby & Rails Version

| Standard | Requirement |
|----------|-------------|
| Ruby version | 3.3+ for new projects; 3.1+ minimum for existing |
| Rails version | 8.1+ for new projects; 7.0+ minimum for existing |
| LTS policy | Prefer latest stable release; upgrade within 6 months of new major/minor |
| Version files | `.ruby-version` and `.tool-versions` required at repo root |

### Version File

Include `.ruby-version` in repo root:

```
3.3.8
```

---

## Project Structure

### Standard Rails Layout

| Standard | Requirement |
|----------|-------------|
| App type | Full-stack or API-only (`config.api_only = true`) |
| Service layer | Business logic in `app/services/`; controllers delegate to services |
| Naming | Snake_case for files and directories; PascalCase for classes |
| Shared code | Extract to engines or gems; avoid file-level sharing across apps |

### Recommended Structure

```
app/
  controllers/        # Thin controllers; delegate to services
  models/             # ActiveRecord models, concerns, validations
  services/           # Business logic (command/query pattern)
  workers/            # Sidekiq background jobs
  serializers/        # API response serialization
  forms/              # Form objects (complex validations)
  presenters/         # View presenters (full-stack apps)
  mailers/            # Email delivery
  graphql/            # GraphQL schema, types, mutations (if applicable)
config/
  initializers/       # Framework and gem configuration
db/
  migrate/            # ActiveRecord migrations
lib/
  # Shared utilities, custom libraries
spec/                 # RSpec test suite
docs/
  adr/                # Architecture Decision Records
```

### Large Application Structure

For monolithic applications that outgrow standard Rails layout:

```
app/
  controllers/
    admin/            # Admin-scoped controllers
    api/
      v1/             # API v1 controllers (legacy)
      v2/             # API v2 controllers (current)
  models/
    concerns/         # Shared model behaviours
  services/
    <domain>/         # Group services by domain
engines/
  <feature>/          # Rails engines for modular features
```

---

## Rails Conventions

### Controller Style

| Standard | Requirement |
|----------|-------------|
| Responsibility | Thin controllers; delegate business logic to service objects |
| Actions | Stick to RESTful actions (index, show, create, update, destroy) |
| Strong params | Always use strong parameters; never pass raw params to models |
| Callbacks | Avoid `before_action` for business logic; use only for auth/setup |

### Model Patterns

| Standard | Requirement |
|----------|-------------|
| Concerns | Extract shared behaviour into concerns; keep models focused |
| Scopes | Use scopes for reusable query logic; name descriptively |
| Validations | Validate at model level; use form objects for complex multi-model validation |
| Callbacks | Minimise callbacks; prefer service objects for side effects |
| Enums | Use Rails enums for state fields with limited values |

### State Machines

| Standard | Requirement |
|----------|-------------|
| Default | ActiveRecord enums with scopes for simple state fields |
| Complex workflows | AASM when transitions require guards, callbacks, or event-driven logic |
| Guards | Use guard clauses for transition preconditions |

Use ActiveRecord enums for straightforward status fields (e.g., `draft`, `published`, `archived`). Reach for AASM only when you need named events, guard conditions, or transition callbacks that go beyond what a simple enum update provides.

### Audit Logging

| Standard | Requirement |
|----------|-------------|
| Gem | PaperTrail for change tracking |
| Scope | Track all user-facing model changes |
| Association tracking | Use `paper_trail-association_tracking` for nested associations |

### Multi-Tenancy (when applicable)

| Standard | Requirement |
|----------|-------------|
| Strategy | Separate database per tenant (Apartment gem) or row-level isolation |
| Job handling | `apartment-sidekiq` for tenant-aware background jobs |
| Tenant switching | Explicit tenant context; never rely on implicit state |

---

## API Patterns — REST

| Standard | Requirement |
|----------|-------------|
| Specification | JSON:API (jsonapi.org) preferred for REST APIs |
| Serialization | `jsonapi.rb` gem for JSON:API compliance |
| Versioning | URL path versioning (`/api/v1/`, `/api/v2/`) via engines or namespaced controllers |
| Authentication | JWT via Auth0; Bearer token in Authorization header |
| Error responses | JSON:API error format with appropriate HTTP status codes |
| Pagination | Cursor-based or page-based; include pagination links in response |

### REST Controller Pattern

```ruby
module Api
  module V2
    class OrdersController < BaseController
      def index
        orders = OrderService.list(current_user, filter_params)
        render jsonapi: orders
      end

      def create
        result = OrderService.create(current_user, order_params)
        if result.success?
          render jsonapi: result.order, status: :created
        else
          render jsonapi_errors: result.errors, status: :unprocessable_entity
        end
      end
    end
  end
end
```

---

## API Patterns — GraphQL

| Standard | Requirement |
|----------|-------------|
| Framework | `graphql-ruby` gem |
| Schema | Single schema at `/graphql` endpoint |
| Complexity limits | `max_complexity: 200`, `max_depth: 15` |
| Authentication | JWT via Auth0; permissions extracted into context |
| Authorization | Custom permission classes per operation |
| Documentation | GraphiQL in development; graphql-docs for static documentation |
| Batch loading | Use GraphQL::Dataloader to prevent N+1 queries |

### GraphQL Authorization Pattern

```ruby
module Queries
  class CustomForms < GraphQL::Schema::Resolver
    type [Types::CustomFormType], null: false

    def resolve
      unless Permissions::ListForms.new(context[:permissions]).permitted?
        raise GraphQL::ExecutionError, "Not authorised"
      end

      CustomForm.accessible_by(context[:current_user])
    end
  end
end
```

---

## Database

| Standard | Requirement |
|----------|-------------|
| Preferred engine | MySQL 8.0+ (unless PostgreSQL is a better fit for specific requirements) |
| Adapter | `mysql2` gem |
| Encoding | `utf8mb4` for full Unicode support |
| Migrations | Always reversible; follow safe migration strategies (see below) |
| Schema format | `schema.rb` |
| Multi-database | ActiveRecord multi-database support for read replicas or domain separation |
| Indexing | Index all foreign keys and frequently queried columns |

### Safe Migration Strategies

Migrations must be safe to run against production databases with zero downtime:

| Requirement | Approach |
|-------------|----------|
| Column additions | Add columns as nullable first; backfill data; then add constraints |
| Column removals | Ignore column in app code first (`ignored_columns`); remove in a later migration |
| Column renames | Add new column → backfill → update app code → remove old column |
| Index additions | Use `algorithm: :concurrently` (PostgreSQL) or equivalent non-blocking approach |
| Large table changes | Batch updates; avoid locking entire tables |
| Data migrations | Separate from schema migrations; run as one-off tasks or background jobs |

Use `strong_migrations` gem to catch unsafe migrations in CI.

### When to Prefer PostgreSQL

- Full-text search requirements (PostgreSQL `tsvector` outperforms MySQL full-text)
- JSON querying requirements (PostgreSQL `jsonb` operators)
- Advanced data types (arrays, ranges, hstore)
- PostGIS for geospatial data

Document the database choice rationale in an ADR.

---

## Gem Management

### Gem Standards

| Standard | Requirement |
|----------|-------------|
| Gemfile organization | Group by purpose (core, api, auth, testing, development) |
| Version pinning | Pin major+minor (`~> x.y`); avoid floating versions |
| Security scanning | `bundler-audit` in CI |
| License compliance | `licensed` gem for license checking |
| Vulnerability scanning | Run `bundle audit check --update` in CI |

### Preferred Gems

| Purpose | Recommended |
|---------|-------------|
| Background jobs | Sidekiq (Pro where licensed) |
| State machines | ActiveRecord enums (default); AASM for complex workflows |
| Search/filtering | Ransack |
| Audit trail | PaperTrail |
| Feature flags | LaunchDarkly |
| JSON serialization (REST) | jsonapi.rb |
| GraphQL | graphql-ruby |
| Authentication | Auth0 (JWT) |
| PDF generation | Grover |
| Excel export | caxlsx |
| HTTP client | Faraday or Net::HTTP |
| JSON | Oj (performance) or stdlib JSON |
| Logging | Rails logger with structured output (Lograge) |

---

## Testing

### Testing Framework

| Standard | Requirement |
|----------|-------------|
| Framework | RSpec (`rspec-rails`) |
| Assertions | RSpec built-in matchers + Shoulda Matchers |
| Mocking | RSpec mocks; WebMock for HTTP; VCR for recording external calls |
| Coverage | SimpleCov; 90%+ line coverage |
| Browser testing | Playwright (via `capybara-playwright-driver`) |
| API doc generation | `rspec-openapi` for OpenAPI spec generation (REST APIs) |
| Parallel execution | CI parallelization via `ci-queue` or `parallel_tests` |

### Test Organization

```
spec/
  models/           # Model unit tests
  services/         # Service layer tests
  requests/         # API endpoint tests (REST and GraphQL)
  system/           # Browser integration tests (Playwright)
  workers/          # Background job tests
  lib/              # Library code tests
  graphql/          # GraphQL query and mutation tests (if applicable)
  support/          # Shared contexts, helpers, custom matchers
  factories/        # FactoryBot factories
```

### Testing Patterns

| Test Type | Tools | Database |
|-----------|-------|----------|
| Unit | RSpec, mocks | None/mocked |
| Request (API) | RSpec, rack-test | Test DB with fixtures or factories |
| Integration (DB) | RSpec | Seeded test database |
| System (browser) | RSpec, Capybara, Playwright | Seeded test database |
| Contract | PactRuby (if applicable) | None |

### Integration Test Requirements

| Requirement | Purpose |
|-------------|---------|
| Isolated test database | Not shared with development or other test runs |
| Database cleaner | DatabaseCleaner or transactional fixtures for test isolation |
| Test fixtures/factories | FactoryBot factories preferred over raw fixtures |
| HTTP mocking | WebMock to prevent real HTTP calls in tests; VCR for recording |

---

## Background Jobs

### Standards

| Standard | Requirement |
|----------|-------------|
| Framework | Sidekiq |
| Queue strategy | Priority queues: `high`, `medium`, `low` (default: `low`) |
| Idempotency | All jobs must be idempotent and safe to retry |
| Error handling | Let Sidekiq retry with exponential backoff; use dead-letter queue for investigation |
| Monitoring | Sidekiq Web UI; integrate with observability stack |
| Serialization | Pass IDs, not full objects; load records inside the job |

### Anti-Patterns to Avoid

```ruby
# BAD: Passing full objects (serialization issues on retry)
MyWorker.perform_async(user)

# GOOD: Pass IDs, load inside the job
MyWorker.perform_async(user.id)

# BAD: Non-idempotent job
def perform(order_id)
  Order.find(order_id).charge_customer!
end

# GOOD: Idempotent with guard
def perform(order_id)
  order = Order.find(order_id)
  return if order.charged?
  order.charge_customer!
end
```

---

## Authentication & Authorization

### Authentication

| Standard | Requirement |
|----------|-------------|
| Provider | Auth0 (OAuth2/JWT) |
| Token format | JWT with RS256; verify via JWKS endpoint |
| Session management | Server-side sessions for full-stack apps; stateless JWT for API-only |
| Token storage | Never store tokens in local storage (XSS risk); use HTTP-only cookies for full-stack |

### Authorization

| Standard | Requirement |
|----------|-------------|
| Pattern | Custom RBAC with permission classes per resource/action |
| Scope | Permissions scoped to tenant/organisation |
| Controller integration | Check authorization before data access; fail closed |
| Testing | Every permission path must have test coverage |

---

## Code Quality

### Standards

| Standard | Requirement |
|----------|-------------|
| Linting | RuboCop with `rubocop-rails` (+ `rubocop-graphql` for GraphQL projects) |
| Security | Brakeman static analysis in CI |
| N+1 detection | Bullet gem in development |
| Performance | `rack-mini-profiler` in development |
| Annotations | `annotate` gem to document model schemas |

### Anti-Patterns to Avoid

```ruby
# BAD: Fat controller
def create
  @order = Order.new(order_params)
  @order.calculate_total
  @order.apply_discount(current_user)
  @order.save!
  OrderMailer.confirmation(@order).deliver_later
  redirect_to @order
end

# GOOD: Delegate to service
def create
  result = OrderService.create(order_params, current_user)
  if result.success?
    redirect_to result.order
  else
    render :new, status: :unprocessable_entity
  end
end
```
