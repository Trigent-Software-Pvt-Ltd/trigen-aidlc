---
owner: Architecture Guild
last-reviewed: 2026-02-05
scope: Legacy ASP.NET MVC applications (.NET Framework 4.6.1-4.7.2)
version-range: net461-net472
detection-markers:
  - "TargetFrameworkVersion" with "v4.6" or "v4.7" in .csproj
  - "Global.asax.cs" with Container.Init()
  - "ContainerConfig.cs" with SimpleInjector
  - "Areas/" folder structure
  - "web.config" (not appsettings.json)
  - "OWIN Startup.cs" with app.Use middleware
  - No "Controllers/" at root (uses Areas pattern)
template-source: Legacy monolith (pre-template era)
---

# Application Profile: .NET Framework MVC

Trigent-specific patterns for **legacy** ASP.NET MVC applications running on .NET Framework 4.6.1-4.7.2. These are mature monolithic applications predating the modern template repository.

> **For new applications**, use the [Web API v10](dotnet-webapi-v10-profile.md), [Function App v10](dotnet-function-v10-profile.md), or [Mixed Solution](dotnet-mixed-solution-profile.md) profiles instead.

## Characteristics

- **Legacy .NET Framework** (4.6.1 or 4.7.2)
- ASP.NET MVC 5 with OWIN middleware (not ASP.NET Core)
- SimpleInjector DI container
- Entity Framework 6 + Dapper (dual data access)
- Manual object translators (no AutoMapper/Mapster)
- Areas-based routing for modular organization
- Azure App Configuration + web.config transforms
- Background services using IHostedService pattern

---

## Project Structure

```
{service-name}/
├── src/
│   ├── ApiClient/                    # API client libraries
│   ├── BusinessLogic/                # Business logic layer (domain modules)
│   │   ├── Trigent.BusinessLogic.{Domain}/
│   │   └── ... (multiple domain modules)
│   ├── Core/                         # Core interfaces, domain models
│   │   ├── Trigent.Core.Common/
│   │   ├── Trigent.Core.Interfaces/
│   │   ├── Trigent.Core.Interfaces.Providers/
│   │   └── Trigent.Core.Interfaces.Repositories/
│   ├── Deployment.v2/                # Background services
│   │   └── Trigent.Deployment.v2.{Service}/
│   ├── Providers/                    # External integration providers
│   │   └── Trigent.Providers.{Provider}/
│   ├── Services/                     # REST API services
│   └── Web/                          # MVC web application
│       └── Trigent.Web/
│           ├── Areas/                # MVC Areas
│           ├── App_Code/             # Startup, BaseController
│           ├── ContainerConfig.cs    # DI configuration
│           ├── Global.asax.cs        # Application startup
│           └── web.config
├── test/
│   ├── unit/
│   ├── integration/
│   └── Trigent.Monolith.Specs/        # BDD specs
└── k8s/
```

---

## Dependency Injection

### Container: SimpleInjector

SimpleInjector is configured in `ContainerConfig.cs` and initialized in `Global.asax.cs`.

### Container Configuration

```csharp
// In ContainerConfig.cs
public static class ContainerConfig
{
    public static Container Container { get; private set; }

    public static void Init(IConfiguration appConfig, IConfiguration azureConfig)
    {
        Container = new Container();
        Container.Options.DefaultScopedLifestyle = new AsyncScopedLifestyle();

        // Singleton registrations
        Container.RegisterSingleton<IMediator, Mediator>();
        Container.RegisterSingleton<IFeatureFlagProvider>(() =>
            new LaunchDarklyFeatureFlagProvider(azureConfig));

        // Scoped registrations
        Container.Register<IRepositoryFactory, RepositoryFactory>(Lifestyle.Scoped);

        // Repository factory pattern
        Container.Register(() => Container.GetInstance<IRepositoryFactory>()
            .GetStudentRepository(), Lifestyle.Scoped);

        // MediatR handlers
        var assemblies = GetAssemblies();
        Container.Register(typeof(IRequestHandler<,>), assemblies, Lifestyle.Scoped);
        Container.RegisterCollection(typeof(INotificationHandler<>), assemblies);

        // Collection registration for polymorphic dependencies
        Container.RegisterCollection<IScreeningProvider>(new List<Type> {
            typeof(CustomAlertScreeningProvider),
            typeof(OffenderScreeningProvider)
        });

        // Conditional registration
        Container.RegisterConditional(typeof(ISystemDatabaseProvider),
            typeof(EFSystemDatabaseProvider),
            Lifestyle.Singleton,
            c => c.Consumer?.ImplementationType == typeof(EFSystemLoggingProvider));

        Container.RegisterConditional(typeof(ISystemDatabaseProvider),
            typeof(DapperSystemDatabaseProvider),
            Lifestyle.Scoped,
            c => c.Consumer?.ImplementationType != typeof(EFSystemLoggingProvider));

        Container.Verify();
    }
}
```

### Application Startup (Global.asax.cs)

```csharp
protected void Application_Start()
{
    // Load configuration from Azure App Configuration
    var builder = new ConfigurationBuilder();
    var creds = new DefaultAzureCredential();
    var endpoint = Environment.GetEnvironmentVariable("R6_AZURE_APPCONFIG_ENDPOINT");

    builder.AddAzureAppConfiguration(options =>
    {
        options.Connect(new Uri(endpoint), creds)
            .ConfigureKeyVault(kv => kv.SetCredential(creds));
    });

    var azureConfig = builder.Build();
    var appConfig = new ConfigurationBuilder()
        .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
        .AddJsonFile("appsettings.json", optional: true)
        .Build();

    // Initialize DI container
    ContainerConfig.Init(appConfig, azureConfig);

    // Set MVC dependency resolver
    DependencyResolver.SetResolver(
        new SimpleInjectorDependencyResolver(ContainerConfig.Container));

    // Standard MVC setup
    AreaRegistration.RegisterAllAreas();
    FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
    RouteConfig.RegisterRoutes(RouteTable.Routes);
}
```

---

## Web Application Patterns

### Base Controller

```csharp
// In App_Code/BaseController.cs
[Authorize]
[KioskSecurity]
[RequireSSL]
[PortalSecurity]
[NoCache]
[DisableCors]
[InteropFilter]
public class BaseController : Controller
{
    protected readonly ISystemLoggingProvider _loggingProvider;
    protected long ClientId => GetClientIdFromClaims();

    protected override void OnException(ExceptionContext filterContext)
    {
        _loggingProvider.LogException(filterContext.Exception, ClientId);
        base.OnException(filterContext);
    }

    protected JsonResult JsonUtc(object data)
    {
        return new JsonUtcResult { Data = data };
    }
}
```

### Areas-Based Organization

Controllers are organized into MVC Areas for modular separation:

```
Web/
├── Areas/
│   ├── Admin/
│   │   ├── Controllers/
│   │   ├── Models/
│   │   └── Views/
│   ├── Visitors/
│   ├── Students/
│   ├── Staff/
│   ├── Kiosk/
│   └── ... (domain-specific areas)
```

### OWIN Authentication Middleware

```csharp
// In App_Code/Startup.cs
public class Startup
{
    public void Configuration(IAppBuilder app)
    {
        // SignalR with Redis backplane
        var redisConfig = new RedisScaleoutConfiguration(redisConnectionString, "SignalR");
        GlobalHost.DependencyResolver.UseStackExchangeRedis(redisConfig);
        app.MapSignalR();

        // Auth0 OpenID Connect
        app.UseOpenIdConnectAuthentication(new OpenIdConnectAuthenticationOptions
        {
            AuthenticationType = "Auth0",
            Authority = $"https://{auth0Domain}/",
            ClientId = auth0ClientId,
            ResponseType = OpenIdConnectResponseType.Code,
            Scope = "openid profile email"
        });

        // JWT Bearer for API clients
        app.UseJwtBearerAuthentication(new JwtBearerAuthenticationOptions
        {
            AuthenticationMode = AuthenticationMode.Active,
            TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = $"https://{auth0Domain}/"
            }
        });

        // Custom middleware
        app.Use<ClaimsMiddleware>();
        app.Use<InteroperabilityMiddleware>();
        app.Use<XssMiddleware>();
    }
}
```

---

## Business Logic Layer

### Manager Pattern

Managers encapsulate business logic and coordinate between repositories and MediatR:

```csharp
public class BaseSignInOutManager : BaseManager
{
    protected readonly IFeatureSettingsProvider _featureSettingsProvider;
    protected readonly IAlertNotificationProvider _alertNotificationProvider;
    protected readonly IPeopleRepository _peopleRepository;

    public BaseSignInOutManager(
        BaseRequest baseRequest,
        IMediator mediator,
        IFeatureSettingsProvider featureSettingsProvider,
        IPeopleRepository peopleRepository)
        : base(baseRequest, mediator)
    {
        _featureSettingsProvider = featureSettingsProvider;
        _peopleRepository = peopleRepository;
    }

    public async Task<List<ScreeningResultViewModel>> ScreenPersonForKiosk(
        long personId,
        PersonPersona personaType)
    {
        var person = _peopleRepository.GetPerson(ClientId, personId);
        // Business logic...
        return await Mediator.Send(new ScreenPersonRequest(person, personaType));
    }
}
```

### MediatR Handlers

```csharp
public class ScreenPersonRequestHandler
    : IRequestHandler<ScreenPersonRequest, List<ScreeningResultViewModel>>
{
    private readonly IEnumerable<IScreeningProvider> _screeningProviders;

    public ScreenPersonRequestHandler(
        IEnumerable<IScreeningProvider> screeningProviders)
    {
        _screeningProviders = screeningProviders;
    }

    public async Task<List<ScreeningResultViewModel>> Handle(
        ScreenPersonRequest request,
        CancellationToken cancellationToken)
    {
        var results = new List<ScreeningResultViewModel>();
        foreach (var provider in _screeningProviders)
        {
            var result = await provider.Screen(request.Person);
            results.Add(result);
        }
        return results;
    }
}
```

---

## Data Access Layer

### Dual Provider Pattern (EF6 + Dapper)

Entity Framework 6 for complex queries and Dapper for performance-critical paths:

```csharp
// Entity Framework 6 DbContext
[DbConfigurationType("Trigent.Core.Security.EFConfiguration, Trigent.Core.Security")]
public class SystemDatabaseProvider : DbContext, ISystemDatabaseProvider
{
    public DbSet<Client> Clients { get; set; }
    public DbSet<ClientUser> ClientUsers { get; set; }
    public DbSet<Person> People { get; set; }
    // 50+ DbSets...

    protected override void OnModelCreating(DbModelBuilder modelBuilder)
    {
        modelBuilder.Configurations.AddFromAssembly(
            typeof(SystemDatabaseProvider).Assembly);
    }
}
```

### Repository Factory

```csharp
public interface IRepositoryFactory
{
    IStudentRepository GetStudentRepository();
    IStaffRepository GetStaffRepository();
    IVisitorRepository GetVisitorRepository();
    // ... domain repositories
}

public class RepositoryFactory : IRepositoryFactory
{
    private readonly ISystemDatabaseProvider _systemDb;
    private readonly IClientDatabaseProvider _clientDb;

    public IStudentRepository GetStudentRepository()
        => new StudentRepository(_systemDb, _clientDb);
}
```

### Repository Pattern

```csharp
public interface IBaseRepository : IDataRepository
{
    Person GetPerson(long clientId, long personId);
    Person CreatePerson(Person person);
    Person SavePerson(Person person);

    // EAV (Entity-Attribute-Value) pattern for custom fields
    IEnumerable<T> GetFields<T>(long clientId, long buildingId, bool showDisabled);
    void SaveFieldValue(long clientId, long entityId, string fieldName, object value);
}
```

---

## Object Mapping

### Manual Translators (No AutoMapper/Mapster)

```csharp
public static class PersonTranslator
{
    public static PersonViewModel DomainToViewModel(Person person)
    {
        return new PersonViewModel
        {
            Id = person.Id,
            FirstName = person.FirstName,
            LastName = person.LastName,
            DateOfBirth = person.DateOfBirth,
            Email = person.Email,
            // ... manual property mapping
        };
    }

    public static Person ViewModelToDomain(PersonViewModel viewModel)
    {
        return new Person
        {
            Id = viewModel.Id,
            FirstName = viewModel.FirstName,
            LastName = viewModel.LastName,
            // ... manual property mapping
        };
    }
}
```

---

## Configuration

### Azure App Configuration + web.config

```csharp
// Configuration loading in Global.asax.cs
var builder = new ConfigurationBuilder();
builder.AddAzureAppConfiguration(options =>
{
    options.Connect(new Uri(endpoint), creds)
        .ConfigureKeyVault(kv => kv.SetCredential(creds));
});
```

### Configuration Provider Pattern

```csharp
public interface IConfigurationProvider
{
    T GetValue<T>(string key);
    string GetConnectionString(string name);
}

public class AzureAppConfigProvider : IConfigurationProvider
{
    private readonly IConfiguration _configuration;

    public T GetValue<T>(string key)
        => _configuration.GetValue<T>(key);
}
```

### Web.config Transforms

Multiple build configurations with SlowCheetah transforms:
- Debug, Release, Staging, Production
- Regional variants: Test_UK, Staging_UK, Production_UK
- Test variants: VmTest, VolTest, EmTest

---

## Background Services

### IHostedService Pattern

Background services run as separate deployments using .NET hosted service pattern:

```csharp
// In Deployment.v2/{Service}/
public abstract class BaseService : IHostedService
{
    protected readonly ILogger<BaseService> _logger;
    protected readonly IHostApplicationLifetime _lifetime;
    protected readonly IConfiguration _configuration;

    public abstract Task ExecuteAsync(CancellationToken stoppingToken);

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Service starting...");
        return ExecuteAsync(cancellationToken);
    }
}

// Interval-based service
public abstract class BaseIntervalService : BaseService
{
    protected abstract TimeSpan Interval { get; }

    public override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await ProcessAsync();
            await Task.Delay(Interval, stoppingToken);
        }
    }
}

// Queue-based service
public abstract class BaseQueueService : BaseService
{
    private readonly IAzureQueueProvider _queueProvider;

    public override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var message = await _queueProvider.DequeueAsync();
            if (message != null)
                await ProcessMessageAsync(message);
        }
    }
}
```

---

## Provider Ecosystem

### Provider Types

| Category | Examples | Purpose |
|----------|----------|---------|
| Authentication | Auth0IdentityProvider, SAMLProvider | Identity management |
| Screening | OffenderScreeningProvider, CustomAlertScreeningProvider | Background checks |
| Background Check | JDPBackgroundCheckProvider, TXDPSBackgroundCheckProvider | External verification |
| Integration | TrigentLinkProvider, SalesForceProvider | External system sync |
| Infrastructure | AzureStorageProvider, RedisCacheProvider | Cloud services |
| Notification | SendGridEmailProvider, TwilioSMSProvider | Communication |

### Provider Registration

```csharp
// Conditional registration based on consumer
Container.RegisterConditional(typeof(ILoggingProvider),
    typeof(EFSystemLoggingProvider),
    Lifestyle.Singleton,
    c => c.Consumer?.ImplementationType == typeof(RedisCacheProvider));

// Collection registration for multiple implementations
Container.RegisterCollection<IScreeningProvider>(new List<Type> {
    typeof(CustomAlertScreeningProvider),
    typeof(OffenderScreeningProvider),
    typeof(HawaiiScreeningProvider)
});
```

---

## Error Handling

| Exception | Thrown In | Caught In | Maps To |
|-----------|-----------|-----------|---------|
| Custom exceptions | Handler/Manager | Controller | HTTP error response |
| DbEntityValidationException | EF6 | Repository | Validation error |
| Exception | Any | BaseController.OnException | 500 + logging |

---

## Testing Strategy

### Test Organization

| Type | Location | Framework |
|------|----------|-----------|
| Unit | `test/unit/` | xUnit |
| Integration | `test/integration/` | xUnit |
| BDD Specs | `Trigent.Monolith.Specs/` | xUnit + custom attributes |

### Test Patterns

```csharp
public class VisitorManagerTests
{
    private readonly Mock<IVisitorRepository> _repositoryMock;
    private readonly VisitorManager _manager;

    public VisitorManagerTests()
    {
        _repositoryMock = new Mock<IVisitorRepository>();
        _manager = new VisitorManager(_repositoryMock.Object);
    }

    [Fact]
    public async Task GetVisitor_ReturnsVisitor_WhenExists()
    {
        // Arrange
        _repositoryMock.Setup(r => r.GetVisitor(It.IsAny<long>(), It.IsAny<long>()))
            .Returns(new Visitor { Id = 1 });

        // Act
        var result = await _manager.GetVisitor(1, 1);

        // Assert
        Assert.NotNull(result);
    }
}
```

---

## Key Differences from Modern Profiles

| Aspect | .NET Framework MVC | .NET 10+ Profiles |
|--------|-------------------|-------------------|
| Framework | .NET Framework 4.6.1/4.7.2 | .NET 10+ |
| Web Framework | ASP.NET MVC 5 + OWIN | ASP.NET Core |
| DI Container | SimpleInjector | Microsoft DI |
| Configuration | web.config + Azure App Config | appsettings.json + Azure App Config |
| Data Access | EF6 + Dapper | EF Core |
| Object Mapping | Manual translators | AutoMapper |
| Startup | Global.asax.cs | Program.cs |
| Authentication | OWIN middleware | ASP.NET Core middleware |
| Project Structure | Areas-based monolith | Separate projects |

---

## Anti-Patterns to Avoid

| Anti-Pattern | Do This Instead |
|--------------|-----------------|
| Migrating to ASP.NET Core mid-feature | Plan dedicated migration initiative |
| Adding new Areas for small features | Consider if existing Area suffices |
| Direct DB access in controllers | Use Manager → Repository pattern |
| Mixing EF and Dapper queries | Use consistent approach per repository |
| Skipping translator for simple models | Always use translators for consistency |

---

## Migration Considerations

When planning migration to modern .NET:

1. **Assess scope**: Monolith complexity may require incremental migration
2. **Strangler fig pattern**: Extract new features as microservices
3. **Shared kernel**: Keep Core libraries as NetStandard for compatibility
4. **Provider abstraction**: Provider pattern enables gradual replacement
5. **Background services**: Already use IHostedService, minimal migration needed
