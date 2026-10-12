# Dependency Analysis & Decoupling Guidance

When decomposing a Feature into Stories and Epics, identify dependencies between work items. The key distinction is **blocking vs non-blocking** dependencies.

## Blocking Dependencies

A **blocking dependency** means work **cannot start** until the dependency is complete. The dependent work would fail, produce incorrect results, or be impossible without the blocker finishing first.

**Indicators of blocking dependencies:**
- "We need X to exist before we can build Y"
- "Y calls/uses/imports X directly"
- "Y's tests would fail without X"
- "We can't deploy Y without X in place"

**Examples:**
| Blocked Story | Blocks On | Why Blocking |
|---------------|-----------|--------------|
| "Implement order API" | "Create order domain model" | API has nothing to expose without the model |
| "Add payment processing" | "Set up payment gateway integration" | Can't process payments without gateway |
| "Build user dashboard" | "Implement authentication" | Dashboard requires authenticated user |
| "Run E2E tests" | "Deploy to staging" | Tests need running environment |

## Non-Blocking Dependencies

A **non-blocking dependency** means work **can proceed in parallel** but will need integration later. The dependent work can use stubs, mocks, or interfaces while the dependency is built.

**Indicators of non-blocking dependencies:**
- "We'll need to integrate with X eventually"
- "Y can use a mock/stub for X initially"
- "Y and X will share data but can be built separately"
- "Y references X but we can define the interface first"

**Examples:**
| Story | Related To | Why Non-Blocking |
|-------|------------|------------------|
| "Build checkout UI" | "Implement payment API" | UI can use mock API responses |
| "Create reporting service" | "Build analytics events" | Service can be built with sample data |
| "Design email templates" | "Implement notification service" | Templates can be designed independently |
| "Write API documentation" | "Implement API endpoints" | Docs can be drafted from specs |

## Environment-Specific Dependencies (Critical)

A common mistake is treating **infrastructure/cloud setup** as blocking for **development work**. Ask: "Can development proceed with a local or mock environment?"

**The Pattern:**
- Cloud/production infrastructure → **Non-blocking for development**
- Cloud/production infrastructure → **Blocking for deployment/release**

**Examples:**

| Development Story | Infrastructure Story | Dependency Type | Rationale |
|-------------------|---------------------|-----------------|-----------|
| "Create migrations" | "Set up Azure Postgres" | **Non-blocking** | Dev uses local Postgres or Docker |
| "Implement data access layer" | "Set up Azure Postgres" | **Non-blocking** | Dev uses local DB with same schema |
| "Build queue consumer" | "Provision Azure Service Bus" | **Non-blocking** | Dev uses local RabbitMQ or in-memory queue |
| "Implement file uploads" | "Create Azure Blob Storage" | **Non-blocking** | Dev uses local filesystem or MinIO |
| "Deploy to staging" | "Set up Azure Postgres" | **Blocking** | Deployment requires actual cloud infra |
| "Run E2E tests in CI" | "Provision test environment" | **Blocking** | CI pipeline needs real environment |

**Key Questions:**
- Can developers run this locally without the cloud resource?
- Is there a local equivalent (Docker, emulator, mock)?
- Does this story's **definition of done** require the cloud resource, or just the code?

**Common Local Alternatives:**

| Cloud Resource | Local Alternative |
|----------------|-------------------|
| Azure/AWS Postgres | Docker postgres, local install |
| Azure Service Bus | RabbitMQ, in-memory queue |
| Azure Blob Storage | Local filesystem, MinIO |
| AWS S3 | LocalStack, MinIO |
| Azure Key Vault | Environment variables, local secrets file |
| Cloud Redis | Docker redis, local install |
| External APIs | WireMock, mock server, VCR recordings |

**When Infrastructure IS Blocking:**
- Deployment/release stories (need actual infrastructure)
- Performance testing (need production-like environment)
- Integration testing with actual cloud services
- Security compliance validation
- Stories that require cloud-specific features with no local equivalent

## Dependency Analysis Questions

Ask these questions when analyzing stories to surface dependencies:

**Environment Dependencies (ask first!):**
- Can this story be developed and tested locally without cloud infrastructure?
- Is there a local alternative (Docker, emulator, mock) for the cloud resource?
- Does this story's **definition of done** require production infrastructure, or just working code?
- Is this dependency only blocking for **deployment**, not for **development**?

**Technical Dependencies:**
- Does this story require code/APIs from another story to function?
- Does this story define data structures that other stories consume?
- Does this story require infrastructure that another story provisions?

**Data Dependencies:**
- Does this story need data that another story creates or migrates?
- Does this story define schemas that other stories depend on?
- Can this story use test/mock data while waiting for real data?

**Workflow Dependencies:**
- Does this story represent a step in a sequence?
- Can users complete this story's feature without features from other stories?
- Does this story require configuration or setup from another story?

**Integration Dependencies:**
- Does this story integrate with an external service another story sets up?
- Can this story define interfaces/contracts that allow parallel development?
- Will this story need refactoring when integrated with others?

## Dependency Classification Table

Use this table format when documenting dependencies:

```markdown
## Dependencies

| This Story | Depends On | Type | Rationale |
|------------|------------|------|-----------|
| Checkout UI | Payment API | Non-blocking | Can mock API during UI development |
| Order API | Order Model | Blocking | API exposes the model directly |
| Dashboard | Auth System | Blocking | Requires authenticated user context |
| Reports | Analytics | Non-blocking | Can build with sample data |
| Create migrations | Azure Postgres setup | Non-blocking | Dev uses local Postgres in Docker |
| Deploy to staging | Azure Postgres setup | Blocking | Deployment requires actual cloud DB |
```

## Impact on Epic Grouping

Use dependency analysis to inform Epic boundaries:

1. **Stories with many blocking dependencies on each other** → Group in same Epic
2. **Stories with only non-blocking dependencies** → Can be in separate Epics (parallel development)
3. **Stories that block many other stories** → Consider as foundational Epic (build first)
4. **Stories with external dependencies only** → Good candidates for independent Epics

## Impact on Sprint Planning

Within a Epic, sequence Sprints based on blocking dependencies:

```
Sprint 1: Foundation (stories that block others)
    ↓ blocking
Sprint 2: Core features (depend on foundation)
    ↓ blocking
Sprint 3: Polish/integration (depend on core)

Sprint 2a: Independent feature ←── non-blocking (can parallel with Sprint 2)
```

**Parallelization opportunities:**
- Non-blocking dependencies allow Sprints to run in parallel
- Define interfaces/contracts in Sprint 1, implement in parallel Sprints
- Use feature flags to integrate non-blocking work incrementally

---

# Dependency Decoupling

After grouping stories into Epics, review dependencies to enable parallel development. Use a **two-pass approach**:

1. **Epic-level decoupling** (interactive) — Review Epic-to-Epic blockers with user
2. **Story-level easy wins** (batch) — Auto-identify obvious candidates, present for confirmation

> **Don't overwhelm the user.** Epic decoupling is interactive. Story decoupling focuses on easy wins presented as a batch — no per-story questions.

## The Problem: Waterfall Chains

Without decoupling, you can end up with:
```
Epic A (Infrastructure)
    ↓ blocks
Epic B (Data Layer)
    ↓ blocks
Epic C (API)
    ↓ blocks
Epic D (UI)
```

This is a waterfall — each Epic waits for the previous one, eliminating parallelization.

## The Goal: Parallel Epics

With decoupling via contracts/mocks:
```
Epic A (Infrastructure) ──────────────────→ Integration Epic
Epic B (Data Layer)     ─── contract ────→ Integration Epic
Epic C (API)            ─── contract ────→ Integration Epic
Epic D (UI)             ─── uses mocks ──→ Integration Epic
```

All Epics can proceed in parallel; integration happens at the end.

## Pass 1: Epic Dependency Review

After grouping stories into Epics, present the **Epic dependency graph** to the user:

```
Epic Dependencies Identified:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Epic: "API Layer"
  └── Blocked by: "Data Layer" (blocking)
  └── Blocked by: "Infrastructure" (blocking)

Epic: "UI Components"
  └── Blocked by: "API Layer" (blocking)
  └── Blocked by: "Auth System" (blocking)

This creates a chain: Infrastructure → Data → API → UI

Can we decouple any of these to enable parallel development?
```

### Decoupling Strategies

| Strategy | When to Use | What It Creates |
|----------|-------------|-----------------|
| **Contract-First** | API/service boundaries between Epics | Contract definition story + Integration story |
| **Schema-First** | Database/data model dependencies | Schema definition story + Migration story |
| **Mock/Stub** | External service or infrastructure deps | Mock setup story + Real integration story |
| **Interface-First** | Code-level dependencies between Epics | Interface definition + Implementation binding |

### Decoupling Prompt

For each **Epic-to-Epic blocking dependency**, ask:

```
Epic Dependency Review:
━━━━━━━━━━━━━━━━━━━━━━
"API Layer" is blocked by "Data Layer"

Currently this means API Layer cannot start until Data Layer completes.

Can we decouple this?

1. ✅ Define data contracts/schemas upfront
   → Both Epics proceed in parallel
   → Add "Define Data Contracts" story to foundational Epic
   → Add "Integrate Real Data Layer" story at the end

2. ✅ API Layer uses mock data layer
   → API development uses stubs/mocks
   → Add "Replace Mock Data Layer" integration story

3. ❌ Keep blocking - genuine sequential dependency
   → Document why (e.g., "API design depends on data model decisions")

4. 💬 Other approach
   → Describe your solution

Your choice:
```

### When Decoupling Creates Stories

If the user chooses to decouple, add stories to appropriate Epics:

**Foundational Story (add to first Epic or create "Contracts" Epic):**
- "Define [X] Contract/Schema"
- No dependencies, becomes foundation for parallel work

**Integration Story (add to final Epic or create "Integration" Epic):**
- "Integrate [X] with Real Implementation"
- Depends on both the contract and the real implementation
- Runs after parallel Epics complete

### Example: Azure Postgres Scenario

```
Before Decoupling:
━━━━━━━━━━━━━━━━━
Epic: "Application Development"
  └── Blocked by: "Azure Infrastructure" (blocking)

After Decoupling:
━━━━━━━━━━━━━━━━━
Epic: "Azure Infrastructure" (proceeds independently)
Epic: "Application Development" (uses local Postgres, proceeds independently)
Epic: "Integration" (new)
  └── Story: "Deploy to Azure Environment"
  └── Blocked by: Azure Infrastructure, Application Development

Result: Infrastructure and Development proceed in parallel
```

### When NOT to Decouple

Some Epic dependencies are genuinely blocking:

- **Foundational domain models** that define ubiquitous language
- **Security/auth architecture** that all Epics must build on
- **Core platform decisions** (database choice, framework, etc.)
- **Regulatory foundations** that must be built-in

Document why these remain blocking:
```
Kept as blocking: "API Layer" → "Auth System"
Rationale: All API endpoints require auth middleware;
           can't meaningfully develop without it
```

## Pass 2: Story-Level Easy Wins

After Epic decoupling, scan for **obvious story-level decoupling opportunities**. Don't ask about each one — identify candidates automatically and present as a batch.

### Easy Win Patterns

Auto-identify stories matching these patterns:

| Pattern | Example | Auto-Suggestion |
|---------|---------|-----------------|
| **Cloud infra → development** | "Create migrations" → "Azure DB setup" | Use local Docker, non-blocking |
| **API consumer → API provider** | "Build dashboard" → "Implement stats API" | Use mock API responses |
| **UI → backend** | "Design checkout flow" → "Payment service" | Use stub data |
| **Service → external dependency** | "Send notifications" → "Email provider setup" | Use local mock/mailhog |
| **Tests → infrastructure** | "Write integration tests" → "CI/CD setup" | Run locally first |

### Batch Presentation

Present all identified easy wins in one batch:

```
Story-Level Easy Wins Identified:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

I've identified [N] story dependencies that look like easy decoupling wins:

1. "Create migrations" → "Azure Postgres setup"
   Suggestion: Use local Postgres (Docker), change to non-blocking

2. "Build order history UI" → "Order API"
   Suggestion: Use mock API responses, change to non-blocking

3. "Implement email notifications" → "SendGrid setup"
   Suggestion: Use local mailhog/mock, change to non-blocking

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Options:
a) ✅ Apply all suggestions
b) ✅ Apply with exceptions (list which to skip)
c) ❌ Skip story-level decoupling
d) 💬 Review individually (not recommended)

Your choice:
```

### What Makes an "Easy Win"

Easy wins have these characteristics:

- **Obvious local alternative** exists (Docker, mock, stub)
- **Development can proceed** without the real dependency
- **Integration is straightforward** later
- **No architectural decisions** depend on the outcome

Skip these (not easy wins):
- Stories where the dependency outcome affects design decisions
- Tightly coupled domain logic
- Security/auth dependencies
- Anything requiring significant mock complexity

### When User Selects Exceptions

If user says "apply with exceptions":

```
Which suggestions should I skip? (comma-separated numbers)
> 2

Applying suggestions 1 and 3.
Keeping "Build order history UI" → "Order API" as blocking.
```

### Created Stories for Easy Wins

For each applied easy win, automatically add:

- **Integration story** at the end: "Integrate [X] with real [dependency]"
- No separate contract story needed (the real implementation IS the contract)
