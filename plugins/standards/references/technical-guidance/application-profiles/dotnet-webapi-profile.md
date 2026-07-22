---
owner: Architecture Guild
last-reviewed: 2026-02-05
scope: ASP.NET Core Web API applications (.NET 6/7/8/9)
version-range: net6.0, net7.0, net8.0, net9.0
detection-markers:
  - "Controllers/"
  - "Startup.cs"
  - "ContainerConfiguration returns Container" (SimpleInjector)
  - "container.Register<" or "container.RegisterInstance" syntax
---

# Application Profile: .NET Web API (Legacy - .NET 6-9)

Trigent-specific patterns for **existing** ASP.NET Core Web API applications on .NET 6-9. Extends dotnet.md with concrete implementation standards.

> **For new applications on .NET 10+**, use the [Web API v10 Profile](dotnet-webapi-v10-profile.md) instead.

## Characteristics

- RESTful API serving JSON responses
- Multi-tenant (client-based isolation)
- Deployed as containerized applications to Kubernetes
- Uses Azure cloud services (Cosmos DB, Service Bus, App Configuration)

---

## Project Structure

### Standard Structure

```
{service-name}/
├── src/
│   ├── Trigent.{Service}.Api/                    # Web API entry point
│   ├── Trigent.{Service}.Api.BusinessLogic/      # Core business logic & data access
│   ├── Trigent.{Service}.Api.Shared/             # Shared models, abstractions, validators
│   └── Trigent.{Service}.Api.Client/             # REST client library (optional)
├── test/
│   ├── Trigent.{Service}.Api.UnitTests/
│   └── Trigent.{Service}.Api.IntegrationTests/
├── k8s/
├── Dockerfile
└── .gitlab-ci.yml
```

### Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Controllers | `{Entity}Controller.cs` | `UserController.cs` |
| Handlers | `{Action}{Entity}RequestHandler.cs` | `CreateUserRequestHandler.cs` |
| Requests | `{Action}{Entity}Request.cs` | `CreateUserRequest.cs` |
| Repositories | `{Entity}Repository.cs` | `UserRepository.cs` |
| Managers | `{Entity}Manager.cs` | `UserManager.cs` |
| Input Models | `{Entity}InputModel.cs` | `UserInputModel.cs` |
| Output Models | `{Entity}OutputModel.cs` | `UserOutputModel.cs` |

---

## Dependency Injection

### Container: SimpleInjector

Most Web APIs use **SimpleInjector** (not Microsoft DI). Check for `ContainerConfiguration.cs`.

### Registration Pattern

```csharp
public static class ContainerConfiguration
{
    public static Container Initialize(IConfiguration configuration)
    {
        var container = new Container();
        container.Options.DefaultScopedLifestyle = new AsyncScopedLifestyle();

        // Scoped registrations
        container.Register<IUserRepository, UserRepository>(Lifestyle.Scoped);
        container.Register<IUserManager, UserManager>(Lifestyle.Scoped);

        // MediatR auto-discovery
        container.RegisterMediatR(typeof(SomeHandler).Assembly);

        // Singletons
        container.RegisterInstance(cosmosClient);

        return container;
    }
}
```

### Lifestyle Conventions

Prefer `Scoped` as the default lifetime. Use `Singleton` only when there's a specific reason (e.g. thread-safe, stateless clients with connection pooling). Evaluate lifetime on a case-by-case basis rather than applying blanket rules.

---

## Business Logic: MediatR CQRS

### Request Flow

```
Controller → Manager → MediatR.Send(Request) → Handler.Execute() → Repository → Response
```

### Request Class

```csharp
public class CreateUserRequest : IRequest<BaseResult<UserOutputModel>>
{
    public UserInputModel InputModel { get; }
    public Guid ClientId { get; }

    public CreateUserRequest(UserInputModel inputModel, Guid clientId)
    {
        InputModel = inputModel;
        ClientId = clientId;
    }
}
```

### Handler Class

```csharp
public class CreateUserRequestHandler
    : BaseRequestHandler<CreateUserRequest, BaseResult<UserOutputModel>>
{
    private readonly IUserRepository _repository;
    private readonly ILogger<CreateUserRequestHandler> _logger;

    public override async Task<BaseResult<UserOutputModel>> Execute(CreateUserRequest request)
    {
        if (request.InputModel == null)
            throw new BadRequestException("Input model is required");

        var entity = request.InputModel.Adapt<User>();
        entity.ClientId = request.ClientId;

        var created = await _repository.Add(entity);
        return new BaseResult<UserOutputModel>(created.Adapt<UserOutputModel>());
    }
}
```

### Manager Pattern

```csharp
public class UserManager : IUserManager
{
    private readonly IMediator _mediator;

    public async Task<BaseResult<UserOutputModel>> Create(Guid clientId, UserInputModel model)
    {
        return await _mediator.Send(new CreateUserRequest(model, clientId));
    }
}
```

---

## Data Access

### Multi-Tenancy

**All queries MUST filter by tenant identifier** (typically `clientId`):

```csharp
// Cosmos DB
var query = new QueryDefinition(
    "SELECT * FROM c WHERE c.clientId = @clientId AND c.isDeleted = false")
    .WithParameter("@clientId", clientId.ToString());

// EF Core
var users = await _context.Users
    .Where(u => u.ClientId == clientId && !u.IsDeleted)
    .ToListAsync();
```

### Soft Deletes

Use soft deletes - **never hard delete data**:

```csharp
public async Task Delete(Guid clientId, Guid id)
{
    var entity = await GetById(clientId, id);
    entity.IsDeleted = true;
    entity.DeletedAt = DateTime.UtcNow;
    await Update(entity);
}
```

---

## Error Handling

### Standard Exceptions

| Exception | HTTP Status | Use Case |
|-----------|-------------|----------|
| `BadRequestException` | 400 | Invalid input, validation failures |
| `NotFoundException` | 404 | Resource not found |
| `UnauthorizedException` | 401 | Authentication required |
| `ForbiddenException` | 403 | Insufficient permissions |
| `ConflictException` | 409 | Resource conflict |

### Global Exception Middleware

```csharp
context.Response.StatusCode = exception switch
{
    BadRequestException => StatusCodes.Status400BadRequest,
    NotFoundException => StatusCodes.Status404NotFound,
    UnauthorizedException => StatusCodes.Status401Unauthorized,
    ForbiddenException => StatusCodes.Status403Forbidden,
    ConflictException => StatusCodes.Status409Conflict,
    _ => StatusCodes.Status500InternalServerError
};
```

---

## Authentication & Authorization

### Scope-Based Policies

```csharp
public static class Scopes
{
    public const string ReadUsers = "read:users";
    public const string WriteUsers = "write:users";
    public const string DeleteUsers = "delete:users";
}

[HttpGet]
[Authorize(Scopes.ReadUsers)]
public async Task<IActionResult> GetAll([FromRoute] Guid clientId) { }

[HttpPost]
[Authorize(Scopes.WriteUsers)]
public async Task<IActionResult> Create([FromRoute] Guid clientId, [FromBody] UserInputModel model) { }
```

---

## API Design

### Route Pattern

```
/v{version}/clients/{clientId:guid}/{resource}
/v{version}/clients/{clientId:guid}/{resource}/{id:guid}
```

### Response Handling

```csharp
[HttpGet("{id:guid}")]
public async Task<IActionResult> GetById(Guid clientId, Guid id)
{
    var result = await _manager.GetById(clientId, id);
    return result.ProcessBaseValueResult();
}
```

---

## Object Mapping (Mapster)

```csharp
public static class UserMappings
{
    public static void Configure()
    {
        TypeAdapterConfig<User, UserOutputModel>
            .NewConfig()
            .Map(dest => dest.FullName, src => $"{src.FirstName} {src.LastName}");
    }
}

// Usage
var outputModel = entity.Adapt<UserOutputModel>();
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Do This Instead |
|--------------|-----------------|
| Query without clientId filter | Always filter by clientId |
| Hard delete data | Use soft deletes |
| Business logic in controllers | Delegate to managers/handlers |
| Using `Singleton` for stateful services | Use `Scoped` lifestyle |

---

## Adding New Features

### New Entity Checklist

- [ ] Entity class in `BusinessLogic/Entities/`
- [ ] Repository interface and implementation
- [ ] Manager interface and implementation
- [ ] Input/Output models in `Shared/Models/`
- [ ] Request and Handler classes
- [ ] Controller in `Api/Controllers/V2/`
- [ ] Mapster mappings
- [ ] DI registration
- [ ] Unit tests
