---
owner: .NET Chapter
last-reviewed: 2025-01-29
scope: .NET projects (C#, F#, ASP.NET Core)
detection-markers:
  - "*.csproj"
  - "*.sln"
  - "*.slnx"
  - "*.cs"
  - "*.fsproj"
  - global.json
  - nuget.config
---

# .NET Project-Type Technical Guidance

Architectural standards for .NET projects (C#, F#, ASP.NET Core). These extend the Global Technical Guidance.

## How to Use This Guidance

- Applies when project contains .NET markers (.csproj, .sln, .slnx, .cs files)
- Extends Global Guidance; does not replace it
- Project-level guidance in the Intent doc may override specific standards
- Deviations require an ADR documenting the rationale

---

## New Project Setup

For **greenfield** repositories, always initialize from the Trigent .NET template project rather than from scratch. The template scaffolds the correct project structure, DI configuration, CI/CD pipeline, and tooling required by these standards.

**Template:** https://gitlab.com/trigent1/project-templates/dotnet

Create the repository from the template before writing any code. If a repo already exists but was not initialized from the template, treat it as brownfield and match its existing patterns.

---

## .NET Version & Runtime

| Standard | Requirement |
|----------|-------------|
| .NET version | .NET 10+ for new projects; .NET 8+ minimum for existing |
| LTS policy | Prefer LTS releases for production workloads |
| Target framework | Single TFM preferred; multi-targeting only when distributing libraries |
| C# version | Latest stable (C# 13+ for .NET 10) |

### Version File

Include `global.json` in repo root:

```json
{
  "sdk": {
    "version": "10.0.100",
    "rollForward": "latestMinor"
  }
}
```

### Build Configuration

Centralize common settings in `Directory.Build.props` at repo root:

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>
</Project>
```

---

## Project Structure

### Solution Organization

| Standard | Requirement |
|----------|-------------|
| Solution file | Required at repo root |
| Assembly Name | `<Company>.<Product>.<Layer>` format |
| Root Namespace | `<Company>.<Product>.<Layer>` format |
| Project naming | `<Layer>` format |
| Folder structure | Mirror namespace hierarchy |
| Shared code | Use shared projects or NuGet packages; avoid file linking |

### Recommended Structure

```
src/
  Api/              # ASP.NET Core web API
  Application/      # Application/use case layer
  Domain/           # Domain models and interfaces
  Infrastructure/   # Data access, external services
  Contracts/        # DTOs, shared interfaces
tests/
  UnitTests/        # Isolated business logic tests
  IntegrationTests/ # Database, HTTP, external service tests
  FunctionalTests/  # End-to-end workflow tests
docs/
  adr/              # Architecture Decision Records
```

## ASP.NET Core Conventions

### API Structure

| Standard | Requirement |
|----------|-------------|
| Controller style | Thin controllers; delegate to MediatR handlers or services (managers) |
| Routing | Attribute routing with `[Route("api/[controller]")]` |
| Versioning | URL path versioning (`/api/v1/`) using Asp.Versioning |
| Model binding | Use DTOs; never bind directly to domain entities |

## Dependency Injection

### Registration Patterns

| Standard | Requirement |
|----------|-------------|
| Lifetime | Prefer scoped; singleton only for stateless services |

## CQRS & MediatR

### When to Use

| Pattern | Use When |
|---------|----------|
| MediatR | Complex applications; need separation of concerns |
| Direct services | Simple CRUD; small applications |

### Command/Query Patterns

```csharp
// Commands modify state
public record CreateOrderCommand(Guid UserId, List<OrderItem> Items)
    : IRequest<Result<OrderId>>;

// Queries return data
public record GetOrderQuery(Guid OrderId)
    : IRequest<Result<OrderDto>>;

// Handlers are single-purpose
public class CreateOrderHandler : IRequestHandler<CreateOrderCommand, Result<OrderId>>
{
    public async Task<Result<OrderId>> Handle(
        CreateOrderCommand request,
        CancellationToken cancellationToken)
    {
        // Implementation
    }
}
```

## NuGet Package Management

### Package Standards

| Standard | Requirement |
|----------|-------------|
| Central management | Recommend `Directory.Packages.props` for version consistency |
| Floating versions | Avoid; pin to specific versions |
| Vulnerability scanning | Run `dotnet list package --vulnerable` in CI |

### Preferred Packages

| Purpose | Recommended |
|---------|-------------|
| Validation | FluentValidation |
| Mapping | AutoMapper or Mapster (team preference; manual mapping acceptable) |
| Logging | Serilog |
| HTTP client | Restease or typed HttpClient |
| JSON | System.Text.Json |
| CQRS | MediatR |

---

## Testing

### Testing Framework

| Standard | Requirement |
|----------|-------------|
| Framework | xUnit |
| Assertions | FluentAssertions |
| Mocking | NSubstitute |
| Coverage | Coverlet; 80%+ line coverage |
| Test data | Bogus or AutoFixture |
| Snapshots | Verify for snapshot/approval testing |
| Contracts | PactNet for consumer-driven contract tests |
| DB cleanup | Respawn for test database reset |

### Test Organization

```
tests/
  UnitTests/
    Handlers/
    Managers/
    Services/
  IntegrationTests/
    Tests/
      Api/                    # Controller integration tests
      Client/                 # API client tests
      Repositories/           # Database integration tests
    Fixtures/                 # WebApplicationFactory, DB fixtures
    GeneratedContracts/       # Pact contract files
  FunctionalTests/
    Tests/
      Api/
        Contracts/            # Consumer contract definitions
```

### Testing Patterns

| Test Type | Tools | Database |
|-----------|-------|----------|
| Unit | xUnit, NSubstitute, Bogus | None/mocked |
| Integration (API) | WebApplicationFactory, Verify | Mocked or in-memory |
| Integration (DB) | xUnit, Respawn | Seeded local database |
| Contract (Consumer) | PactNet | None |
| Contract (Provider) | PactNet | Seeded local database |
| Functional | WebApplicationFactory, Verify | Seeded local database |

### Integration Test Requirements

| Requirement | Purpose |
|-------------|---------|
| Isolated test database | Not shared with development or other test runs |
| Database reset mechanism | Respawn, fresh container, or transaction rollback |
| Test fixtures | Configure application for testing via `WebApplicationFactory` |
| Seed data | SQL scripts or code-based seeding for test scenarios |

Infrastructure can be managed by the test framework (Testcontainers) or externally (Docker Compose, Makefile). See project template for working examples.

---

## Async/Await Patterns

### Standards

| Standard | Requirement |
|----------|-------------|
| Async all the way | Never block on async (no `.Result`, `.Wait()`) |
| ConfigureAwait | Use `ConfigureAwait(false)` in libraries |
| Cancellation | Accept and propagate `CancellationToken` |
| Naming | Suffix async methods with `Async` when supporting both sync and async |

### Anti-Patterns to Avoid

```csharp
// BAD: Blocking on async
var result = GetDataAsync().Result;

// BAD: Async void (except event handlers)
public async void ProcessData() { }

// BAD: Unnecessary async/await
public async Task<int> GetValueAsync() => await Task.FromResult(42);

// GOOD: Direct return
public Task<int> GetValueAsync() => Task.FromResult(42);
```
