# Risky Packages

Packages that require manual care during .NET version upgrades. The `version-upgrade` skill
will flag these packages rather than automatically upgrading them.

---

## Risk Levels

| Level | Meaning |
|-------|---------|
| HIGH | Likely to cause runtime failures or data issues if upgraded without careful review |
| MEDIUM | May have breaking API or behaviour changes; validate after upgrade |
| LOW | Generally stable but check version compatibility |

---

## HIGH Risk

### Npgsql

**Packages:** `Npgsql`, `Npgsql.EntityFrameworkCore.PostgreSQL`

**Why risky:**
- Npgsql v8+ changed default DateTime handling (UTC enforcement). Code that passes `DateTime.Now` (local) will throw.
- Nullable reference type handling changed — queries returning nullable columns behave differently.
- Connection multiplexing configuration changed.
- Must align with the EF Core major version.

**Required action:**
- Run all integration tests against a real PostgreSQL instance.
- Search codebase for `DateTime.Now`, `DateTime.Today`, and `DateTimeKind.Local` usage.
- Review Npgsql release notes for the version range being upgraded.

---

### Microsoft.EntityFrameworkCore.*

**Packages:** `Microsoft.EntityFrameworkCore`, `Microsoft.EntityFrameworkCore.Design`, `Microsoft.EntityFrameworkCore.SqlServer`, all EF Core providers

**Why risky:**
- Major version must match the target runtime (EF Core 10.x for .NET 10).
- EF Core migrations are generated code — regeneration may be needed.
- Query translation behaviour can change between major versions.
- JSON column support and owned entity behaviour has changed in recent versions.

**Required action:**
- Run `dotnet ef migrations list` after upgrade to verify migrations are intact.
- Run all integration and functional tests against a real database.
- Check EF Core 9→10 migration guide for breaking changes.

---

### Microsoft.NET.Sdk.Functions (In-Process Azure Functions)

**Why risky:**
- In-process model is **not supported on .NET 10+**.
- If this package is present and the target is .NET 10+, the application **cannot run**.
- Migration to isolated worker model requires substantial code changes.

**Required action:**
- Do not upgrade to .NET 10 until in-process Functions are migrated to isolated worker.
- Create a separate work item for the isolated worker migration.

---

### Microsoft.Azure.Functions.Worker.*

**Packages:** `Microsoft.Azure.Functions.Worker`, `Microsoft.Azure.Functions.Worker.Sdk`, all Worker extensions

**Why risky:**
- Extension packages must all align with the same Worker SDK major version.
- Mismatched extension versions cause runtime startup failures.
- The `FunctionsWorkerMiddleware` API changed between major versions.

**Required action:**
- Upgrade all `Microsoft.Azure.Functions.Worker.*` packages together.
- Validate with `func start` locally before merging.

---

### MassTransit

**Packages:** `MassTransit`, `MassTransit.RabbitMQ`, `MassTransit.AzureServiceBus`, all transports

**Why risky:**
- v7→v8 and v8→v9 contain breaking changes to consumer registration, retry configuration, and saga state machine patterns.
- Transport packages must align with the MassTransit core version.
- Configuration changes can cause silent message processing failures.

**Required action:**
- Review the MassTransit migration guide for the version range being upgraded.
- Test all consumer types (consumers, sagas, activities) end-to-end.
- Validate dead-letter queue behaviour has not changed.

---

### RabbitMQ.Client

**Why risky:**
- RabbitMQ.Client v7+ has a substantially different API surface.
- Connection factory, channel creation, and consumer patterns changed.
- If used directly (not via MassTransit), requires code changes in addition to version bump.

**Required action:**
- If used via MassTransit, let MassTransit manage the RabbitMQ.Client version.
- If used directly, review v7 migration guide thoroughly.

---

## MEDIUM Risk

### Microsoft.AspNetCore.Authentication.JwtBearer

**Why risky:**
- Ships with the ASP.NET Core runtime; version must match target framework exactly.
- Behaviour changes can affect token validation, claims mapping, and OAuth flows.
- Do not pin to a version different from the target framework version.

**Required action:**
- Remove explicit version pin; let the SDK supply the correct version.
- Test authentication flows in staging before merging.

---

### Swashbuckle.AspNetCore

**Why risky:**
- Swashbuckle v6 does not work on .NET 9+.
- Swashbuckle v7+ required for .NET 9+ but the API changed.
- .NET 10 ships built-in OpenAPI (`Microsoft.AspNetCore.OpenApi`) which conflicts with Swashbuckle's document generation approach.
- Scalar is the recommended modern alternative but requires a different registration approach.

**Required action:**
- On .NET 8: v6.x is fine.
- On .NET 9+: upgrade to v7.x at minimum.
- On .NET 10: evaluate replacing with Scalar + `Microsoft.AspNetCore.OpenApi`.
- Do not auto-replace Swashbuckle with Scalar — this is a UX/API decision.

---

### NSwag.AspNetCore

**Why risky:**
- NSwag generates client code — upgrading may change generated output.
- Changes to generated clients can break consumer codebases.
- Code generation pipeline (MSBuild integration) may need reconfiguration.

**Required action:**
- Run NSwag code generation after upgrade and diff the output.
- If generated clients are distributed as NuGet packages, treat client changes as breaking.

---

### OpenTelemetry.*

**Why risky:**
- OpenTelemetry SDK had breaking changes between 1.x minor versions and particularly between pre-GA and stable releases.
- Exporter packages (OTLP, Jaeger, Zipkin) must align with the core SDK version.
- Metric API changes can cause silent data loss if exporters are mismatched.

**Required action:**
- Upgrade all `OpenTelemetry.*` packages together.
- Validate traces and metrics appear in your observability platform after upgrade.

---

### Newtonsoft.Json

**Why risky:**
- Serialisation behaviour differs from `System.Text.Json`.
- Do not silently swap between Newtonsoft and System.Text.Json — this is a semantic change.
- If both are present, check which one is active for each endpoint.

**Required action:**
- Keep Newtonsoft if already in use — do not replace as part of a TFM upgrade.
- If replacing Newtonsoft with System.Text.Json, treat as a separate work item with thorough serialisation testing.

---

### Microsoft.Extensions.* (when explicitly pinned)

**Why risky:**
- These packages ship with the .NET runtime.
- Pinning to a version that does not match the installed runtime causes assembly binding conflicts.
- Some packages (e.g., `Microsoft.Extensions.Http`) have had subtle behaviour changes.

**Required action:**
- Remove explicit `Version` attributes from these packages and let the SDK manage versions.
- If a specific version is pinned for a bug workaround, document why and review whether it is still needed.

---

## LOW Risk

### Serilog.*

**Why:** Generally stable across .NET upgrades. Sink packages (console, file, seq) may need minor version bumps for .NET compatibility metadata, but rarely change behaviour.

**Action:** Verify sink packages are compatible with the target framework. Run logging in a test environment.

### FluentValidation

**Why:** Generally stable. FluentValidation v11+ changed some rule configuration syntax. FluentValidation.AspNetCore must align with ASP.NET Core version.

**Action:** Run all validation tests. Check for any deprecation warnings.

### MediatR

**Why:** Generally stable. MediatR v12+ changed handler registration to use `RegisterServicesFromAssembly`. If using older registration patterns, update them.

**Action:** Ensure all handlers are registered and tests pass. Check for startup warnings about unregistered handlers.

### Scalar.AspNetCore

**Why:** Modern package, actively maintained. If already present, verify version supports the target framework.

**Action:** Check the Scalar release notes for the version range being upgraded.
