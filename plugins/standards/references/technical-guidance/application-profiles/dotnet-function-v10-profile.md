---
owner: Architecture Guild
last-reviewed: 2026-02-05
scope: Azure Functions (.NET 10+ isolated worker)
version-range: net10.0+
detection-markers:
  - "net10.0" in TargetFramework
  - "host.json"
  - "[Function]" attribute (isolated worker)
  - "ConfigureFunctionsWorkerDefaults()"
  - "ContainerConfiguration extends IServiceCollection" (Microsoft DI)
  - "No Controllers/ directory"
template-source: dotnet template (Functions-only initialization)
---

# Application Profile: .NET 10 Function App

Trigent-specific patterns for **new** Azure Function applications on .NET 10+ using the isolated worker model. Based on the `dotnet` template repository initialized with Functions-only option.

> **For existing applications on .NET 6-9**, use the [Legacy Function App Profile](dotnet-function-app-profile.md) instead.

## Characteristics

- **New .NET 10 applications only** (created via `dotnet` template with `init.sh`)
- Event-driven, serverless compute (isolated worker model)
- Microsoft DI container
- Shared patterns with Web API v10 and Mixed Solution profiles
- Triggered by HTTP, Service Bus, Timer, Blob, or other Azure events
- Deployed as containerized applications to Kubernetes

---

## Project Structure

```
{service-name}/
├── src/
│   ├── Functions/        # Azure Functions (isolated worker)
│   ├── BusinessLogic/    # Business logic (MediatR handlers)
│   ├── Data/             # Data access layer
│   ├── Shared/           # DI configuration
│   └── Contracts/        # DTOs, input/output models
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

.NET 10 Function Apps use the same DI configuration as Web API v10 and Mixed Solution.

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

### Functions Program.cs

```csharp
var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureAppConfiguration((context, builder) =>
    {
        builder.AddAzureAppConfiguration(options =>
        {
            options.Connect(new Uri(appConfigEndpoint), new DefaultAzureCredential())
                   .ConfigureKeyVault(kv => kv.SetCredential(new DefaultAzureCredential()));
        });
    })
    .ConfigureServices((context, services) =>
    {
        // Shared configuration
        ContainerConfiguration.Configure(services, context.Configuration);
    })
    .Build();

host.Run();
```

---

## Trigger Types

### HTTP Triggers (Isolated Worker)

```csharp
public class ForecastFunction
{
    private readonly IForecastManager _manager;

    [Function("CreateForecast")]
    public async Task<HttpResponseData> CreateForecast(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "forecasts")]
        HttpRequestData req)
    {
        var input = await req.ReadFromJsonAsync<ForecastInputModel>();
        var clientId = ExtractClientId(req);

        var result = await _manager.Save(clientId, input);

        var response = req.CreateResponse(
            result.IsSuccessful ? HttpStatusCode.Created : HttpStatusCode.BadRequest);
        await response.WriteAsJsonAsync(result.Value);
        return response;
    }
}
```

### Service Bus Triggers

```csharp
public class ForecastProcessorFunction
{
    private readonly IForecastManager _manager;
    private readonly ILogger<ForecastProcessorFunction> _logger;

    [Function("ProcessForecastMessage")]
    public async Task Run(
        [ServiceBusTrigger("forecasts-topic", "processor-subscription",
            Connection = "ServiceBusConnection")]
        ServiceBusReceivedMessage message)
    {
        _logger.LogInformation("Processing forecast message {MessageId}", message.MessageId);

        var payload = message.Body.ToObjectFromJson<ForecastMessage>();
        await _manager.Save(payload.ClientId, payload.Input);
    }
}
```

### Timer Triggers

```csharp
[Function("DailyCleanup")]
public async Task Run(
    [TimerTrigger("0 0 2 * * *")] TimerInfo timer)
{
    _logger.LogInformation("Cleanup started at {Time}", DateTime.UtcNow);
    // Cleanup logic via manager
}
```

---

## Business Logic: MediatR CQRS

Uses the **same patterns** as Web API v10 - business logic in separate BusinessLogic project:

```csharp
// Handler in BusinessLogic project
public class SaveForecastRequestHandler
    : BaseRequestHandler<SaveForecastRequest, IBaseResult<ForecastOutputModel>>
{
    private readonly IForecastRepository _repository;
    private readonly IMapper _mapper;

    public override async Task<IBaseResult<ForecastOutputModel>> Execute(
        SaveForecastRequest request,
        CancellationToken ct)
    {
        var entity = _mapper.Map<Forecast>(request.Input);
        entity.ClientId = request.ClientId;

        var saved = await _repository.Add(entity);
        return new BaseResult<ForecastOutputModel>(_mapper.Map<ForecastOutputModel>(saved));
    }
}
```

---

## Object Mapping (AutoMapper)

Same configuration as Web API v10:

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
| `Exception` | Any | Manager/Function | `RequestResult.Error` / retry |

### Service Bus Error Handling

Service Bus triggers have built-in retry:

```csharp
try
{
    await _manager.Process(payload);
    // Message auto-completed on success
}
catch (TransientException ex)
{
    _logger.LogWarning(ex, "Transient error, will retry");
    throw; // Rethrow triggers retry
}
```

---

## Deployment

### Kubernetes with KEDA Autoscaling

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: {service}-scaledobject
spec:
  scaleTargetRef:
    name: {service}-functions
  minReplicaCount: 1
  maxReplicaCount: 10
  triggers:
    - type: azure-servicebus
      metadata:
        topicName: my-topic
        subscriptionName: my-subscription
```

---

## Testing Strategy

### Three-Tier Testing

| Type | Location | What's Real | What's Mocked |
|------|----------|-------------|---------------|
| Unit | `test/UnitTests/` | Business logic only | All dependencies |
| Integration | `test/IntegrationTests/` | Infrastructure (DB or HTTP) | Application layers |
| Functional | `test/FunctionalTests/` | Full stack | External services only |

---

## Key Differences from Legacy Function App Profile

| Aspect | Legacy (.NET 6-9) | v10 (.NET 10+) |
|--------|-------------------|----------------|
| Worker Model | In-process | Isolated worker |
| Startup | `FunctionsStartup` | `HostBuilder` |
| Function Attribute | `[FunctionName]` | `[Function]` |
| Configuration | In Functions project | Shared `ContainerConfiguration.cs` |
| Business Logic | In Functions project | Separate BusinessLogic project |
| Object Mapping | Various | AutoMapper |

---

## Anti-Patterns to Avoid

| Anti-Pattern | Do This Instead |
|--------------|-----------------|
| Using in-process model | Use isolated worker model |
| Business logic in Function classes | Use separate BusinessLogic project |
| Different DI than Web API v10 | Use shared ContainerConfiguration |
