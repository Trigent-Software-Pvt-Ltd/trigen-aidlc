---
owner: Architecture Guild
last-reviewed: 2026-02-05
scope: New .NET 10 applications combining Web API + Azure Functions
version-range: net10.0+
detection-markers:
  - "net10.0" in TargetFramework
  - "Trigent.{Service}.Api/" AND "Trigent.{Service}.Functions/"
  - "ContainerConfiguration extends IServiceCollection" (Microsoft DI)
  - "Both Controllers/ AND host.json"
  - "[Function]" attribute (isolated worker)
template-source: dotnet template (full initialization with both components)
---

# Application Profile: Mixed Solution (Web API + Azure Functions)

Trigent-specific patterns for **new .NET 10 applications** combining Web API and Azure Functions with shared business logic.

> **This profile is for new application development only.** For existing applications on .NET 6-9, use the [Legacy Web API](dotnet-webapi-profile.md) or [Legacy Function App](dotnet-function-app-profile.md) profiles.

> **Related profiles:** This profile shares patterns with [Web API v10](dotnet-webapi-v10-profile.md) and [Function App v10](dotnet-function-v10-profile.md). All three use the same ContainerConfiguration, MediatR, and AutoMapper setup.

## Characteristics

- **New .NET 10 applications only** (use `dotnet` template repository)
- Dual entry points: REST API for synchronous, Functions for async/event-driven
- Shared business logic layer (no duplication)
- Common DI configuration across both entry points
- Deployed as separate services from same codebase

---

## Project Structure

```
{service-name}/
├── src/
│   ├── Api/              # ASP.NET Core Web API
│   ├── Functions/        # Azure Functions (isolated worker)
│   ├── BusinessLogic/    # Shared business logic (MediatR)
│   ├── Data/             # Data access layer
│   ├── Shared/           # DI configuration
│   ├── Contracts/        # DTOs, input/output models
│   └── Client/           # API client library (NuGet)
├── test/
│   ├── UnitTests/
│   ├── IntegrationTests/
│   └── FunctionalTests/
└── k8s/
    ├── base/
    │   ├── deployment.yaml            # API deployment
    │   └── functions-deployment.yaml  # Functions deployment
    └── overlays/
```

### Key Principle: Shared Business Logic

Both API and Functions use the **same** business logic:

```csharp
// API Controller
[HttpPost]
public async Task<IActionResult> Create([FromBody] CreateForecastInput input)
{
    var result = await _forecastManager.Save(clientId, input);
    return result.ProcessBaseValueResult();
}

// Azure Function
[Function("ProcessForecast")]
public async Task Run([ServiceBusTrigger(...)] ServiceBusReceivedMessage message)
{
    var input = message.Body.ToObjectFromJson<CreateForecastInput>();
    await _forecastManager.Save(clientId, input);  // Same method!
}
```

---

## Dependency Injection

### Container: Microsoft DI

Mixed solutions use **Microsoft DI** (not SimpleInjector) for Azure Functions compatibility.

### Shared Container Configuration

```csharp
// In Trigent.{Service}.Shared/ContainerConfiguration.cs
public static class ContainerConfiguration
{
    public static IServiceCollection Configure(
        IServiceCollection services,
        IConfiguration configuration)
    {
        // MediatR (shared handlers)
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(
            typeof(GetForecastsRequestHandler).Assembly));

        // AutoMapper
        services.AddAutoMapper(typeof(ForecastMappingProfile).Assembly);

        // Data access
        services.AddScoped<IForecastRepository, ForecastRepository>();

        // Business logic managers
        services.AddScoped<IForecastManager, ForecastManager>();

        // Feature flags
        services.AddLaunchDarklyClient(configuration);

        return services;
    }
}
```

### API Startup

```csharp
public void ConfigureServices(IServiceCollection services)
{
    // Shared configuration
    ContainerConfiguration.Configure(services, Configuration);

    // API-specific services
    services.AddControllers();
    services.AddApiAuth(Configuration);
}
```

### Functions Program.cs

```csharp
var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        // Shared configuration
        ContainerConfiguration.Configure(services, context.Configuration);
    })
    .Build();
```

---

## Business Logic Layer

### MediatR CQRS Pattern

All business logic flows through MediatR handlers in the BusinessLogic project:

```csharp
// Request
public record GetForecastsRequest(Guid ClientId) : IRequest<GetForecastsResponse>;
public record GetForecastsResponse(IEnumerable<ForecastOutputModel> Forecasts);

// Handler
public class GetForecastsRequestHandler
    : BaseRequestHandler<GetForecastsRequest, GetForecastsResponse>
{
    private readonly IForecastRepository _repository;
    private readonly IMapper _mapper;

    public override async Task<GetForecastsResponse> Execute(
        GetForecastsRequest request,
        CancellationToken ct)
    {
        var forecasts = await _repository.GetByClientId(request.ClientId);
        var models = _mapper.Map<IEnumerable<ForecastOutputModel>>(forecasts);
        return new GetForecastsResponse(models);
    }
}
```

### Manager Layer

Managers wrap MediatR and provide a clean interface:

```csharp
public interface IForecastManager
{
    Task<IBaseResult<ForecastOutputModel>> GetById(Guid clientId, Guid id);
    Task<IBaseResult<ForecastOutputModel>> Save(Guid clientId, ForecastInputModel input);
    Task<IBaseResult> Delete(Guid clientId, Guid id);
}

public class ForecastManager : BaseManager, IForecastManager
{
    public async Task<IBaseResult<ForecastOutputModel>> Save(
        Guid clientId, ForecastInputModel input)
    {
        return await Mediator.SafelyExecuteAsync(
            new SaveForecastRequest(clientId, input));
    }
}
```

---

## Error Handling

| Exception | Thrown In | Caught In | Maps To |
|-----------|-----------|-----------|---------|
| `BadRequestException` | Handler | Manager | `RequestResult.BadRequest` |
| `EntityNotFoundException` | Handler | Manager | `RequestResult.NotFound` |
| `Exception` | Any | Manager/Controller | `RequestResult.Error` / 500 |

---

## Testing Strategy

### Three-Tier Testing

| Type | Location | What's Real | What's Mocked |
|------|----------|-------------|---------------|
| Unit | `test/UnitTests/` | Business logic only | All dependencies |
| Integration | `test/IntegrationTests/` | Infrastructure (DB or HTTP) | Application layers |
| Functional | `test/FunctionalTests/` | Full stack | External services only |

### Test Naming Convention

```
{Method}_Should_{ExpectedBehavior}_When{Condition}
```

---

## AutoMapper Profiles

```csharp
public class ForecastMappingProfile : Profile
{
    public ForecastMappingProfile()
    {
        CreateMap<Forecast, ForecastOutputModel>();
        CreateMap<ForecastInputModel, Forecast>()
            .ForMember(dest => dest.Id, opt => opt.Ignore())
            .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());
    }
}
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Do This Instead |
|--------------|-----------------|
| Duplicating logic in API and Functions | Use shared BusinessLogic project |
| Different DI configurations | Use shared ContainerConfiguration |
| Direct repository access from controllers | Use Manager layer |
| Separate DTOs for API and Functions | Use shared Contracts project |
| Testing only API or only Functions | Test both entry points |

---

## Key Differences from Single-Component Profiles

| Aspect | Web API Only | Functions Only | Mixed Solution |
|--------|--------------|----------------|----------------|
| Entry Points | Controllers | Functions | Both |
| DI Container | SimpleInjector | MS DI | MS DI (shared) |
| Business Logic | In API project | In Functions project | Separate project |
| Configuration | appsettings.json | local.settings.json | Both + shared keys |
| Deployment | Single K8s deployment | Single deployment | Two deployments |
