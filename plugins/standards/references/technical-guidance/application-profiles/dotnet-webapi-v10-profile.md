---
owner: Architecture Guild
last-reviewed: 2026-02-05
scope: ASP.NET Core Web API applications (.NET 10+)
version-range: net10.0+
detection-markers:
  - "net10.0" in TargetFramework
  - "Controllers/"
  - "ContainerConfiguration extends IServiceCollection" (Microsoft DI)
  - "services.AddScoped<" or "services.AddSingleton<" syntax
  - "No host.json or [Function] attributes"
template-source: dotnet template (API-only initialization)
---

# Application Profile: .NET 10 Web API

Trigent-specific patterns for **new** ASP.NET Core Web API applications on .NET 10+. Based on the `dotnet` template repository initialized with API-only option.

> **For existing applications on .NET 6-9**, use the [Legacy Web API Profile](dotnet-webapi-profile.md) instead.

## Characteristics

- **New .NET 10 applications only** (created via `dotnet` template with `init.sh`)
- RESTful API serving JSON responses
- Microsoft DI container (not SimpleInjector)
- Shared patterns with Function App v10 and Mixed Solution profiles
- Multi-tenant (client-based isolation)
- Deployed as containerized applications to Kubernetes

---

## Project Structure

```
{service-name}/
├── src/
│   ├── Api/              # ASP.NET Core Web API
│   ├── BusinessLogic/    # Business logic (MediatR handlers)
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
    └── overlays/
```

---

## Dependency Injection

### Container: Microsoft DI

.NET 10 Web APIs use **Microsoft DI** (not SimpleInjector like legacy Web APIs).

### Container Configuration

```csharp
// In Trigent.{Service}.Shared/ContainerConfiguration.cs
public static class ContainerConfiguration
{
    public static IServiceCollection Configure(
        IServiceCollection services,
        IConfiguration configuration)
    {
        // MediatR
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
    services.AddSwaggerGen();
}
```

---

## Business Logic: MediatR CQRS

### Request Flow

```
Controller → Manager → MediatR.Send(Request) → Handler.Execute() → Repository → Response
```

### Handler Pattern

```csharp
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

### Manager Pattern

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

## Object Mapping (AutoMapper)

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

## Key Differences from Legacy Web API Profile

| Aspect | Legacy (.NET 6-9) | v10 (.NET 10+) |
|--------|-------------------|----------------|
| DI Container | SimpleInjector | Microsoft DI |
| Registration | `container.Register<>()` | `services.AddScoped<>()` |
| Object Mapping | Mapster | AutoMapper |
| Configuration | In API project | Shared `ContainerConfiguration.cs` |
| Project Structure | BusinessLogic in API | Separate BusinessLogic project |

---

## Anti-Patterns to Avoid

| Anti-Pattern | Do This Instead |
|--------------|-----------------|
| Using SimpleInjector | Use Microsoft DI for consistency with template |
| Mapster for mapping | Use AutoMapper (template standard) |
| Business logic in API project | Use separate BusinessLogic project |
| Query without clientId filter | Always filter by clientId |
