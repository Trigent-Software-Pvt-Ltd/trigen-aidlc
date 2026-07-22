---
owner: Architecture Guild
last-reviewed: 2026-02-05
scope: Azure Functions V4 (.NET 6/7/8/9) In-Process Model
version-range: net6.0, net7.0, net8.0, net9.0
detection-markers:
  - "host.json"
  - "[FunctionName]" attribute (in-process model)
  - "FunctionsStartup" class with [assembly: FunctionsStartup]
  - "IFunctionsHostBuilder" in Configure method
  - "Microsoft.Azure.Functions.Extensions" package
  - "No Controllers/ directory"
---

# Application Profile: Azure Function App (Legacy - .NET 6-9)

Trigent-specific patterns for **existing** Azure Function applications on .NET 6-9 using the in-process hosting model. Based on patterns from the azure-functions repository.

> **For new applications on .NET 10+**, use the [Function App v10 Profile](dotnet-function-v10-profile.md) instead, which uses the isolated worker model.

## Characteristics

- **In-process hosting model** (functions run in same process as host)
- Event-driven, serverless compute
- Triggered by HTTP, Service Bus, Timer, Blob, Durable orchestration
- Microsoft DI via `IFunctionsHostBuilder`
- MediatR for CQRS pattern
- Deployed as containerized applications to Kubernetes (not consumption plan)

---

## Project Structure

### Multi-Function Repository

```
azure-functions/
├── src/
│   ├── Trigent.Azure.Functions.Core/       # Shared utilities, base classes
│   ├── Trigent.Azure.Functions.Email/      # Email processing function
│   ├── Trigent.Azure.Functions.SMS/        # SMS processing function
│   ├── Trigent.Azure.Functions.Screening/  # Background screening
│   ├── Trigent.Azure.Functions.*TopicEvents/  # Event-driven functions (9 variants)
│   │   ├── BuildingTopicEvents/
│   │   ├── ClientTopicEvents/
│   │   ├── ContactTopicEvents/
│   │   └── ... (more topic handlers)
│   ├── Trigent.Azure.Functions.AutoSignOut/
│   ├── Trigent.Azure.Functions.InstantAlert/
│   └── Trigent.Azure.Functions.EventWriteback/
├── Trigent.Azure.Functions.Data/           # Shared data access layer
├── Trigent.Azure.Functions.BusinessLogic/  # Shared business logic
├── Trigent.Legacy/                         # Legacy submodule (being decoupled)
├── test/
│   └── Trigent.Azure.Functions.UnitTests/
└── Trigent.Azure.sln
```

### Single Function Project Structure

```
Trigent.Azure.Functions.{Name}/
├── Functions/
│   ├── {TriggerName}Definition.cs      # Function trigger definition
│   └── {TriggerName}Function.cs        # Function implementation
├── Settings/
│   └── {Name}Settings.cs               # Strongly-typed settings
├── Startup.cs                          # FunctionsStartup DI configuration
├── host.json                           # Function host configuration
├── local.settings.json                 # Local development settings
└── {Name}.csproj
```

### Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Function Definition | `{TriggerName}Definition.cs` | `RegularDefinition.cs` |
| Function Class | `{TriggerName}Function.cs` | `BuildingCreatedFunction.cs` |
| Settings | `{Name}Settings.cs` | `EmailSettings.cs` |
| Manager | `I{Name}Manager` / `{Name}Manager` | `IVisitorManager` |
| Repository | `I{Entity}Repository` | `IVisitorEventRepository` |
| Processor | `I{Name}Processor` | `IAutoSignOutProcessor` |

---

## Dependency Injection

### Container: Microsoft DI via FunctionsStartup

Function Apps use **Microsoft DI** (not SimpleInjector) via `IFunctionsHostBuilder`.

### Startup Pattern

```csharp
[assembly: FunctionsStartup(typeof(Trigent.Azure.Functions.Email.Startup))]

namespace Trigent.Azure.Functions.Email
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            // Configuration binding with Options pattern
            builder.Services.AddOptions<EmailSettings>()
                .Configure<IConfiguration>((settings, configuration) =>
                {
                    configuration.Bind(settings);
                });

            var settingOptions = builder.Services.BuildServiceProvider()
                .GetRequiredService<IOptions<EmailSettings>>();

            // MediatR registration
            builder.Services.AddMediatR(cfg =>
            {
                cfg.RegisterServicesFromAssembly(typeof(GetOrCreatePersonRequest).Assembly);
                cfg.RegisterServicesFromAssembly(typeof(PerformVisitorSignOutRequest).Assembly);
            });

            // Singleton services (connection pooling)
            builder.Services.AddSingleton<IConnectionMultiplexer>(
                x => ConnectionMultiplexer.Connect(settingOptions.Value.CacheConnectionString));

            builder.Services.AddSingleton<ICacheProvider>(
                x => new CacheProvider(x.GetRequiredService<IConnectionMultiplexer>()));

            // Transient services (per-invocation)
            builder.Services.AddTransient<ILoggingProvider>(
                x => new SerilogLoggingProvider());

            builder.Services.AddTransient<IDatabaseConnectionProvider>(
                x => new DatabaseConnectionProvider(
                    x.GetRequiredService<ICacheProvider>(),
                    settingOptions.Value.Environment,
                    settingOptions.Value.SystemConnectionString));

            // Repository factory pattern
            builder.Services.AddTransient<IRepositoryFactory>(
                x => new RepositoryFactory(x.GetRequiredService<IDatabaseConnectionProvider>()));

            // Dynamic repository registration
            builder.Services.AddTransient(GetRepositoryInstance<IVisitorEventRepository, VisitorContext>);
            builder.Services.AddScoped<IConnectionStringRepository>(
                x => new ConnectionStringRepository(settingOptions.Value.SystemConnectionString));

            // Business logic managers
            builder.Services.AddTransient<ISystemManager, SystemManager>();
            builder.Services.AddTransient<IVisitorManager, VisitorManager>();

            // Logging configuration
            builder.ConfigureSerilog("Email", settingOptions.Value.Environment);
            builder.Services.AddLogging(f => f.AddSerilog());
        }

        private static TRepository GetRepositoryInstance<TRepository, TContext>(IServiceProvider serviceProvider)
            where TRepository : IDataRepository
            where TContext : DbContext, new()
        {
            var repositoryFactory = serviceProvider.GetRequiredService<IRepositoryFactory>();
            return (TRepository)repositoryFactory.Get<TRepository, TContext>("");
        }
    }
}
```

### Lifetime Guidelines

| Component | Lifetime | Rationale |
|-----------|----------|-----------|
| `IConnectionMultiplexer` (Redis) | Singleton | Thread-safe, connection pooling |
| `ICacheProvider` | Singleton | Wraps Redis connection |
| Service Bus clients | Singleton | Connection reuse |
| HTTP Client Factory | Singleton | Socket management |
| `IDatabaseConnectionProvider` | Transient | Connection string resolution |
| `IRepositoryFactory` | Transient | Creates scoped repositories |
| Repositories | Transient/Scoped | Per-invocation data access |
| Managers/Processors | Transient | Per-invocation business logic |
| MediatR Handlers | Transient | Stateless event handling |
| `ILoggingProvider` | Transient | Per-invocation logging context |

---

## Configuration

### Settings Classes (Options Pattern)

```csharp
// Base settings shared across functions
public class BaseSettings
{
    public string SystemConnectionString { get; set; }
    public string Environment { get; set; }
    public string CacheConnectionString { get; set; }
    public string LogApiKey { get; set; }
}

// Function-specific settings
public class EmailSettings : BaseSettings
{
    public string SendGridApiKey { get; set; }
    public string DatadogApiKey { get; set; }
    public string AzureStorageConnectionString { get; set; }
    public string AzureQueueConnectionString { get; set; }
    public string MaxAttempts { get; set; }
    public string DefaultEmailPoolName { get; set; }
}

// Topic event settings
public class BuildingTopicSettings : BaseSettings
{
    public string AzureBuildingTopicConnectionString { get; set; }
    public string BuildingTopicName { get; set; }
    public string BuildingCreatedSubscriptionName { get; set; }
}
```

### Environment Variable Binding

Use `%VariableName%` syntax in trigger attributes:

```csharp
[TimerTrigger("%NChronSchedule%")]
[ServiceBusTrigger("%BuildingTopicName%", "%BuildingCreatedSubscriptionName%",
    Connection = "AzureBuildingTopicConnectionString")]
```

### host.json

```json
{
  "version": "2.0",
  "logging": {
    "logLevel": {
      "default": "Information",
      "Trigent": "Debug"
    },
    "applicationInsights": {
      "samplingExcludedTypes": "Request",
      "samplingSettings": {
        "isEnabled": true
      }
    }
  },
  "extensions": {
    "serviceBus": {
      "prefetchCount": 10,
      "messageHandlerOptions": {
        "maxConcurrentCalls": 16
      }
    }
  }
}
```

### local.settings.json (Development Only)

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet",
    "ServiceBusConnection": "Endpoint=sb://...",
    "SystemConnectionString": "Server=...",
    "Environment": "Development",
    "NChronSchedule": "0 */5 * * * *"
  }
}
```

---

## Trigger Types

### Service Bus Topic/Subscription Triggers (Primary Pattern)

```csharp
public class BuildingCreatedDefinition
{
    private readonly BuildingCreatedFunction _function;

    public BuildingCreatedDefinition(BuildingCreatedFunction function)
    {
        _function = function;
    }

    [FunctionName("BuildingCreatedEventFunction")]
    public async Task Run(
        [ServiceBusTrigger("%BuildingTopicName%", "%BuildingCreatedSubscriptionName%",
            Connection = "AzureBuildingTopicConnectionString")]
        Message message,
        ILogger log,
        ExecutionContext context,
        MessageReceiver messageReceiver)
    {
        await _function.ExecuteAsync(message, messageReceiver, log);
    }
}
```

### Service Bus Queue Triggers

```csharp
public class RegularDefinition
{
    private const string QueueName = "email-regular";
    private readonly RegularFunction _function;

    [FunctionName("RegularEmailFunction")]
    public async Task Run(
        [ServiceBusTrigger(QueueName, Connection = "AzureQueueConnectionString")]
        Message message,
        ILogger logger,
        ExecutionContext context,
        MessageReceiver messageReceiver)
    {
        var config = Extensions.GetConfiguration(context);
        string queueConnectionString = config["AzureQueueConnectionString"];
        await _function.ExecuteAsync(message, messageReceiver,
            new MessageSender(queueConnectionString, QueueName));
    }
}
```

### Timer Triggers

```csharp
public class CheckAlertsCleanupFunction
{
    private readonly IVerifiedPersonaScreeningsManager _manager;

    public CheckAlertsCleanupFunction(IVerifiedPersonaScreeningsManager manager)
    {
        _manager = manager;
    }

    [FunctionName("CheckAlertsCleanup")]
    public async Task Run(
        [TimerTrigger("%NChronSchedule%")] TimerInfo timer,
        ILogger log)
    {
        var result = await _manager.RemoveExpiredScreenings();
        if (result?.Success)
        {
            log.LogInformation(result.Message);
        }
    }
}
```

### Durable Functions (Orchestration)

```csharp
// Orchestrator
[FunctionName(nameof(InstantAlertOrchestrator))]
public async Task Run(
    [OrchestrationTrigger] IDurableOrchestrationContext context,
    ILogger log)
{
    var databaseNames = await context.CallActivityAsync<List<string>>(
        "GetClientDatabasesActivity_InstantAlert",
        _settings.SystemConnectionString);

    var tasks = databaseNames.Select(db =>
        context.CallActivityAsync("RefreshInstantAlertsActivity", db));

    await Task.WhenAll(tasks);
}

// Activity
[FunctionName("GetClientDatabasesActivity_InstantAlert")]
public async Task<List<string>> GetClientDatabases(
    [ActivityTrigger] string systemConnectionString,
    ILogger log)
{
    return await _repository.GetClientDatabaseNames(systemConnectionString);
}

[FunctionName("RefreshInstantAlertsActivity")]
public async Task RefreshAlerts(
    [ActivityTrigger] string databaseName,
    ILogger log)
{
    await _manager.RefreshInstantAlerts(databaseName);
}
```

**Use Durable Functions when**:
- Processing takes longer than function timeout (10 min default)
- Need fan-out/fan-in patterns (process multiple items in parallel)
- Require reliable state management across steps
- Need human interaction or external event waiting

---

## Business Logic Patterns

### Manager Pattern

```csharp
public interface IVisitorManager
{
    Task<SignOutResult> PerformSignOut(long clientId, long personId);
}

public class VisitorManager : IVisitorManager
{
    private readonly IMediator _mediator;
    private readonly IVisitorEventRepository _repository;

    public VisitorManager(IMediator mediator, IVisitorEventRepository repository)
    {
        _mediator = mediator;
        _repository = repository;
    }

    public async Task<SignOutResult> PerformSignOut(long clientId, long personId)
    {
        return await _mediator.Send(new PerformVisitorSignOutRequest(clientId, personId));
    }
}
```

### MediatR Request/Handler Pattern

```csharp
// Request
public record PerformVisitorSignOutRequest(long ClientId, long PersonId)
    : IRequest<SignOutResult>;

// Handler
public class PerformVisitorSignOutHandler
    : IRequestHandler<PerformVisitorSignOutRequest, SignOutResult>
{
    private readonly IVisitorEventRepository _repository;

    public PerformVisitorSignOutHandler(IVisitorEventRepository repository)
    {
        _repository = repository;
    }

    public async Task<SignOutResult> Handle(
        PerformVisitorSignOutRequest request,
        CancellationToken cancellationToken)
    {
        var visitor = await _repository.GetActiveVisit(request.ClientId, request.PersonId);
        if (visitor == null)
            return SignOutResult.NotFound();

        visitor.SignOutTime = DateTime.UtcNow;
        await _repository.Update(visitor);

        return SignOutResult.Success(visitor.Id);
    }
}
```

---

## Data Access Patterns

### Repository Factory

```csharp
public interface IRepositoryFactory
{
    TRepository Get<TRepository, TContext>(string databaseName)
        where TRepository : IDataRepository
        where TContext : DbContext;
}

public class RepositoryFactory : IRepositoryFactory
{
    private readonly IDatabaseConnectionProvider _connectionProvider;

    public RepositoryFactory(IDatabaseConnectionProvider connectionProvider)
    {
        _connectionProvider = connectionProvider;
    }

    public TRepository Get<TRepository, TContext>(string databaseName)
        where TRepository : IDataRepository
        where TContext : DbContext
    {
        var connectionString = _connectionProvider.GetConnectionString(databaseName);
        // Create context and repository with connection string
        return (TRepository)Activator.CreateInstance(typeof(TRepository), connectionString);
    }
}
```

### Multi-Tenant DbContext Types

```csharp
// Different contexts for different entity domains
public class VisitorContext : DbContext { }
public class CorporateVisitorContext : DbContext { }
public class StaffContext : DbContext { }
public class EmployeeContext : DbContext { }
public class ContractorContext : DbContext { }
public class VolunteerContext : DbContext { }
public class ClientContext : DbContext { }
public class SystemContext : DbContext { }

// Registration in Startup
builder.Services.AddTransient(GetRepositoryInstance<IVisitorEventRepository, VisitorContext>);
builder.Services.AddTransient(GetRepositoryInstance<IBuildingRepository, ClientContext>);
builder.Services.AddTransient(GetRepositoryInstance<IStaffRepository, StaffContext>);
```

### Database Connection Provider

```csharp
public interface IDatabaseConnectionProvider
{
    string GetConnectionString(string databaseName);
}

public class DatabaseConnectionProvider : IDatabaseConnectionProvider
{
    private readonly ICacheProvider _cacheProvider;
    private readonly string _environment;
    private readonly string _systemConnectionString;

    public DatabaseConnectionProvider(
        ICacheProvider cacheProvider,
        string environment,
        string systemConnectionString)
    {
        _cacheProvider = cacheProvider;
        _environment = environment;
        _systemConnectionString = systemConnectionString;
    }

    public string GetConnectionString(string databaseName)
    {
        // Resolve connection string from cache or system database
        var cached = _cacheProvider.Get<string>($"connstr:{databaseName}");
        if (cached != null) return cached;

        // Fallback to system database lookup
        return LookupConnectionString(databaseName);
    }
}
```

---

## Message Queue Abstraction

### Queue Function Base Class

```csharp
public abstract class QueueFunction : FunctionAsyncBase
{
    protected IQueueMessageReceiver QueueMessageReceiver { get; private set; }
    protected IQueueMessageSender QueueMessageSender { get; private set; }
    protected bool MessageToBeDeadLettered { get; set; }
    protected string DeadLetterReason { get; set; }

    protected override async Task OnExecuteAsync(Message message)
    {
        QueueMessageReceiver = new QueueMessageReceiver(message, MessageReceiver);
        QueueMessageSender = new QueueMessageSender(QueueMessageReceiver.Clone(), MessageSender);

        try
        {
            var processingTask = OnProcessMessageAsync();

            // Renew lock during long processing
            while (!processingTask.IsCompleted)
            {
                await Task.Delay(TimeSpan.FromSeconds(30));
                await QueueMessageReceiver.RenewAsync();
            }

            await processingTask;

            if (MessageToBeDeadLettered)
            {
                await QueueMessageReceiver.DeadLetterAsync(DeadLetterReason, DeadLetterDescription);
            }
            else
            {
                await QueueMessageReceiver.CompleteAsync();
            }
        }
        catch (Exception ex)
        {
            await QueueMessageReceiver.AbandonAsync();
            throw;
        }
    }

    protected abstract Task OnProcessMessageAsync();
}
```

### Message Types

```csharp
public class EmailQueueMessage
{
    public Guid MessageId { get; set; }
    public string To { get; set; }
    public string Subject { get; set; }
    public string Body { get; set; }
    public int AttemptCount { get; set; }
}

public class SubscriptionMessage<T>
{
    public T Data { get; set; }
    public MessageLabel? Label { get; set; }
}

// Deserialization
Message = Extensions.Deserialize<SubscriptionMessage<BuildingSubscriptionData>>(messageRequest);
```

---

## Logging

### Serilog Configuration

```csharp
public static class SerilogExtensions
{
    public static void ConfigureSerilog(
        this IFunctionsHostBuilder builder,
        string applicationName,
        string environment)
    {
        Log.Logger = new LoggerConfiguration()
            .MinimumLevel.Information()
            .Enrich.FromLogContext()
            .Enrich.WithMachineName()
            .Enrich.WithProcessId()
            .Enrich.WithThreadId()
            .WriteTo.Console()
            .WriteTo.NewRelicLogs(
                endpointUrl: "https://log-api.newrelic.com/log/v1",
                applicationName: applicationName,
                licenseKey: Environment.GetEnvironmentVariable("NEW_RELIC_LICENSE_KEY"))
            .CreateLogger();
    }
}
```

### Datadog Logging Provider

```csharp
builder.Services.AddScoped<ILoggingProvider>(
    x => new DatadogLoggingProvider(
        settingOptions.Value.DatadogApiKey,
        settingOptions.Value.Environment,
        "Email Service"));
```

---

## Error Handling

### Service Bus with Retry

```csharp
try
{
    await _processor.Process(payload);
    // Message auto-completed on success
}
catch (TransientException ex)
{
    _logger.LogWarning(ex, "Transient error, will retry");
    throw; // Rethrow triggers automatic retry
}
catch (PermanentException ex)
{
    _logger.LogError(ex, "Permanent error, dead-lettering");
    MessageToBeDeadLettered = true;
    DeadLetterReason = ex.Message;
}
```

### Max Attempts Tracking

```csharp
if (message.AttemptCount >= int.Parse(_settings.MaxAttempts))
{
    _logger.LogError("Max attempts exceeded for message {MessageId}", message.MessageId);
    MessageToBeDeadLettered = true;
    DeadLetterReason = "Max attempts exceeded";
    return;
}

message.AttemptCount++;
await QueueMessageSender.ResubmitAsync(message);
```

---

## Caching (Redis)

```csharp
// Registration
builder.Services.AddSingleton<IConnectionMultiplexer>(
    x => ConnectionMultiplexer.Connect(settingOptions.Value.CacheConnectionString));

builder.Services.AddSingleton<ICacheProvider>(
    x => new CacheProvider(x.GetRequiredService<IConnectionMultiplexer>()));

// Usage
public class CacheProvider : ICacheProvider
{
    private readonly IConnectionMultiplexer _redis;
    private readonly IDatabase _db;

    public CacheProvider(IConnectionMultiplexer redis)
    {
        _redis = redis;
        _db = redis.GetDatabase();
    }

    public T Get<T>(string key)
    {
        var value = _db.StringGet(key);
        return value.HasValue ? JsonSerializer.Deserialize<T>(value) : default;
    }

    public void Set<T>(string key, T value, TimeSpan? expiry = null)
    {
        _db.StringSet(key, JsonSerializer.Serialize(value), expiry);
    }
}
```

---

## Deployment

### Kubernetes with KEDA Autoscaling

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: email-function-scaledobject
spec:
  scaleTargetRef:
    name: email-functions
  minReplicaCount: 1
  maxReplicaCount: 10
  triggers:
    - type: azure-servicebus
      metadata:
        queueName: email-regular
        messageCount: "5"
        connectionFromEnv: SERVICE_BUS_CONNECTION
```

---

## Testing Strategy

### Unit Tests

```csharp
public class VisitorManagerTests
{
    private readonly Mock<IMediator> _mediatorMock;
    private readonly VisitorManager _manager;

    public VisitorManagerTests()
    {
        _mediatorMock = new Mock<IMediator>();
        _manager = new VisitorManager(_mediatorMock.Object, Mock.Of<IVisitorEventRepository>());
    }

    [Fact]
    public async Task PerformSignOut_SendsCorrectRequest()
    {
        // Arrange
        _mediatorMock.Setup(m => m.Send(It.IsAny<PerformVisitorSignOutRequest>(), default))
            .ReturnsAsync(SignOutResult.Success(1));

        // Act
        var result = await _manager.PerformSignOut(100, 200);

        // Assert
        Assert.True(result.IsSuccess);
        _mediatorMock.Verify(m => m.Send(
            It.Is<PerformVisitorSignOutRequest>(r => r.ClientId == 100 && r.PersonId == 200),
            default));
    }
}
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Do This Instead |
|--------------|-----------------|
| Creating Redis/DB clients per invocation | Use DI with singleton lifetime |
| Large function bodies with business logic | Extract to managers and handlers |
| Swallowing exceptions silently | Log and rethrow for retry or dead-letter |
| Hardcoded connection strings | Use Options pattern and environment variables |
| Not tracking attempt counts | Track attempts, dead-letter after max |
| Blocking synchronous calls | Use async/await throughout |
| Missing lock renewal for long processing | Implement lock renewal loop |

---

## Key Differences from Web API

| Aspect | Web API (Legacy) | Function App (Legacy) |
|--------|------------------|----------------------|
| DI Container | SimpleInjector | Microsoft DI |
| Startup | `Startup.cs` with `Container` | `FunctionsStartup` with `IFunctionsHostBuilder` |
| Configuration | `appsettings.json` | `local.settings.json` + Options pattern |
| Entry Points | Controllers | Functions with trigger attributes |
| Triggers | HTTP only | HTTP, Service Bus, Timer, Durable, Blob |
| Error Handling | Global middleware | Per-function + trigger retry policies |
| Scaling | Kubernetes HPA | KEDA with trigger-specific scaling |

---

## Key Differences from Function App v10

| Aspect | Legacy (.NET 6-9) | v10 (.NET 10+) |
|--------|-------------------|----------------|
| Hosting Model | In-process | Isolated worker |
| Function Attribute | `[FunctionName]` | `[Function]` |
| Startup | `FunctionsStartup` | `HostBuilder` |
| DI Access | `IFunctionsHostBuilder` | `IServiceCollection` directly |
| Configuration | Shared `ContainerConfiguration.cs` | Per-function or shared |
| Business Logic | May be in function project | Separate BusinessLogic project |
