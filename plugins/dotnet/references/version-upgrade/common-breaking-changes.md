# Common Breaking Changes in .NET Upgrades

A checklist of breaking-change areas to investigate when upgrading .NET versions.
Use this as a review guide alongside the target-version guidance file.

---

## ASP.NET Core Hosting Model

- [ ] **Minimal APIs vs Controller-based:** .NET 6+ introduced minimal APIs. Check if `Startup.cs` / `Program.cs` patterns need updating.
- [ ] **`WebApplication.CreateBuilder` pattern:** Newer projects use this instead of `IHostBuilder`. Verify the startup pattern is compatible with the target version.
- [ ] **Request pipeline ordering:** Middleware registration order changes can affect behaviour. Review any custom middleware.
- [ ] **`IApplicationBuilder` vs `WebApplication`:** Verify extension methods called on the app builder are compatible.

---

## Minimal APIs

- [ ] Route groups and filters changed between .NET 6, 7, and 8.
- [ ] `IResult` implementations may have new members or changed behaviour.
- [ ] OpenAPI metadata attributes changed between versions (especially `.NET 9+` with native OpenAPI).

---

## Authentication and Authorization Middleware

- [ ] `AddAuthentication` / `AddAuthorization` configuration syntax is stable but verify JwtBearer options.
- [ ] Policy-based authorization: policy names, requirement handlers, and claim mappings should be tested.
- [ ] `[Authorize]` attribute behaviour with new ASP.NET Core versions — verify scope-based policies still apply.
- [ ] **Never change auth configuration without explicit testing** — silent failures can result in open endpoints.

---

## Configuration Binding

- [ ] `IConfiguration.Bind` strictness changed in .NET 8 (`BinderOptions.ErrorOnUnknownConfiguration`).
- [ ] `ConfigurationBinder` source generators introduced in .NET 8 — may change behaviour if opted in.
- [ ] `options.Validate(...)` now throws at startup in some configurations rather than at first use.
- [ ] Verify all `appsettings.json` keys have matching configuration models.

---

## Nullable Reference Types

- [ ] Enabling `<Nullable>enable</Nullable>` (already standard in Trigent projects) causes warnings on legacy code.
- [ ] Newly upgraded projects with `TreatWarningsAsErrors` will fail to build if nullable warnings exist.
- [ ] EF Core and Npgsql models: nullable columns must now be declared as nullable properties (`string?`).
- [ ] Check all model binding, DTO classes, and domain entities for nullability correctness.

---

## Trimming and AOT

- [ ] Trimming (`<PublishTrimmed>true</PublishTrimmed>`) removes unused code at publish time.
- [ ] AOT compilation (`<PublishAot>true</PublishAot>`) requires trim-compatible code.
- [ ] Reflection-heavy code (Newtonsoft.Json, some DI patterns, MediatR auto-discovery) is not trim-safe by default.
- [ ] **Do not enable trimming or AOT as part of a TFM upgrade** — treat as a separate initiative.
- [ ] Check if any existing `PublishTrimmed`/`PublishAot` settings need package compatibility updates.

---

## System.Text.Json Behaviour

- [ ] Default serialisation settings change between .NET versions (e.g., `JsonSerializerDefaults.Web` was introduced in .NET 5).
- [ ] Enum serialisation: by default, enums are serialised as integers; `JsonStringEnumConverter` must be explicit.
- [ ] Property naming: default is camelCase with `JsonSerializerDefaults.Web`.
- [ ] `[JsonPropertyName]` attributes are required for any case-sensitive property mapping.
- [ ] Check API contract tests to verify JSON output has not changed between versions.

---

## EF Core Behaviour

- [ ] **Query translation:** New optimisations may cause previously-working LINQ queries to translate differently.
- [ ] **Lazy loading:** Check whether lazy loading proxies are enabled and compatible with the new version.
- [ ] **Owned entities and JSON columns:** Changed significantly in EF Core 7-10.
- [ ] **`SaveChanges` behaviour:** Verify tracked entities behave as expected.
- [ ] **Connection resiliency:** Retry policies may have changed defaults.
- [ ] Run `dotnet ef migrations list` and verify no pending migrations are unexpected.

---

## Npgsql Behaviour

- [ ] **DateTime UTC enforcement (Npgsql v8+):** `DateTime` with `DateTimeKind.Local` or `DateTimeKind.Unspecified` will throw when writing. All `DateTime` values must be UTC.
- [ ] **Nullable columns:** Nullable PostgreSQL columns must map to nullable C# types (`DateTime?`, `int?`).
- [ ] **Legacy timestamp behaviour:** If using `NpgsqlConnection.GlobalTypeMapper.UseNodaTime()` or legacy timestamp behaviour, this changed in v7+.
- [ ] **Enum types:** PostgreSQL enum type mapping changed. Re-register enums if used.
- [ ] Run all repository integration tests against a real PostgreSQL instance.

---

## Azure Functions Runtime Model

- [ ] **In-process vs isolated worker:** In-process model not supported on .NET 10+.
- [ ] **`[FunctionName]` attribute** (in-process) → **`[Function]` attribute** (isolated worker).
- [ ] **`FunctionsStartup`** → **`HostBuilder` with `ConfigureFunctionsWorkerDefaults()`**.
- [ ] **`IFunctionsHostBuilder`** → **`IServiceCollection`** directly.
- [ ] **Trigger attribute namespaces** changed for isolated worker (e.g., `Microsoft.Azure.Functions.Worker` instead of `Microsoft.Azure.WebJobs`).
- [ ] **Durable Functions:** SDK and patterns differ between in-process and isolated worker.
- [ ] **Service Bus trigger:** `Message` type (WindowsAzure.ServiceBus) → `ServiceBusReceivedMessage` type.

---

## Docker Base Images

- [ ] Update `FROM mcr.microsoft.com/dotnet/sdk:X.Y` in Dockerfiles.
- [ ] Update `FROM mcr.microsoft.com/dotnet/aspnet:X.Y` for Web API runtime stage.
- [ ] Update `FROM mcr.microsoft.com/dotnet/runtime:X.Y` for console/Functions runtime stage.
- [ ] Verify no OS-level package installations in Dockerfile break on the new base image (e.g., Alpine vs Debian differences).
- [ ] Check that the new base image includes required native libraries (e.g., libgdiplus, ICU).

---

## GitLab CI SDK Image Versions

- [ ] Update `image: mcr.microsoft.com/dotnet/sdk:X.Y` in `.gitlab-ci.yml`.
- [ ] Update `DOTNET_VERSION`, `SDK_VERSION`, or `DOTNET_SDK_VERSION` CI variables.
- [ ] Verify test reporting paths are still correct after upgrade.
- [ ] Check that coverage tools (Coverlet) are compatible with the new SDK.

---

## OpenAPI Tooling Changes

- [ ] **Swashbuckle v6 does not work on .NET 9+.** Upgrade to v7.x minimum.
- [ ] **Swashbuckle v7 changed** the `AddSwaggerGen` and `UseSwagger` registration API surface.
- [ ] **`Microsoft.AspNetCore.OpenApi`** ships built-in from .NET 9+. Adding this package can conflict with Swashbuckle's document generation if not configured carefully.
- [ ] NSwag: code generation output may change. Diff generated clients after upgrade.

---

## Scalar Migration Considerations

Scalar is not a drop-in replacement for Swashbuckle. When evaluating:

| Aspect | Swashbuckle | Scalar |
|--------|-------------|--------|
| Document generation | Swashbuckle's own generator | Uses `Microsoft.AspNetCore.OpenApi` built-in |
| UI | Swagger UI | Scalar UI |
| Registration | `AddSwaggerGen` + `UseSwagger` + `UseSwaggerUI` | `AddOpenApi` + `MapOpenApi` + `MapScalarApiReference` |
| Customisation | Rich filter pipeline | Configuration-based |
| Authentication UI | Swagger UI auth forms | Scalar auth forms |
| Code generation | Not built-in | Not built-in (use NSwag or kiota separately) |

- [ ] If Scalar is adopted, remove Swashbuckle packages entirely — do not run both simultaneously.
- [ ] Verify all OpenAPI document customisations (operation filters, schema filters, document filters) are re-implemented using Scalar/built-in mechanisms.
- [ ] Update any API documentation or client generation pipelines that depend on the Swagger UI URL.
