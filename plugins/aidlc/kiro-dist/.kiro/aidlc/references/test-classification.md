# Test Classification Reference

Rules for classifying test scenarios by layer during AI-DLC Mob Elaboration.

## Sprint Type → Test Layer Mapping

| Sprint Type | Required Layers | E2E Note |
|-----------|----------------|----------|
| `backend` | Unit + API + E2E | E2E scenarios use `requires_browser: false` |
| `frontend` | Unit + UI + E2E | E2E scenarios use `requires_browser: true` |
| `fullstack` | Unit + API + UI + E2E | All layers included |

### Determining Sprint Type

Classify a Sprint by examining its tasks:
- Tasks touching controllers, services, repositories, APIs, or data layers only → `backend`
- Tasks touching components, views, templates, or client-side logic only → `frontend`
- Tasks spanning both server-side and client-side concerns → `fullstack`

When in doubt, prefer `fullstack` over under-classifying.

## Test Layer Definitions

| Layer | Purpose | Scope | Tools (examples) |
|-------|---------|-------|-----------------|
| **Unit** | Validate individual functions, methods, or classes in isolation | Single class or function | xUnit, Jest, RSpec |
| **API** | Validate HTTP endpoints, request/response contracts, status codes | Controller + service (no browser) | Supertest, RestSharp, RSpec request specs |
| **UI** | Validate component rendering, user interactions, visual state | Component tree (no real backend) | Cypress Component, React Testing Library |
| **E2E** | Validate complete user journeys through the full stack | Browser + backend + DB | Playwright, Cypress |
| **Integration** | Validate cross-Sprint or cross-Epic interactions within an Epic | Multiple components/services together | Any framework |

## No-Gap Rule

Every Acceptance Criterion (AC) in a Task must be covered by at least one test scenario. When generating scenarios:

1. List all ACs from all Tasks in the Sprint
2. Ensure each AC maps to at least one scenario in the appropriate layer(s)
3. Flag any AC without coverage — it is a gap that must be resolved

## No-Overlap Rule

Each scenario belongs to exactly one test layer. When a scenario could fit multiple layers, assign it to the **lowest** layer that can reliably test it:

- Can it be tested with a unit test in isolation? → **Unit**
- Does it require a real HTTP call but no browser? → **API**
- Does it require rendering but no real backend? → **UI**
- Does it require a real browser and real backend together? → **E2E**

Avoid duplicating the same scenario across layers — this creates maintenance burden without adding coverage.

## E2E Scenario Classification

For E2E scenarios, always specify the `requires_browser` flag:

| `requires_browser` | When to use |
|-------------------|-------------|
| `false` | API-level E2E (full stack but no browser — e.g., Playwright API mode, integration test against live env) |
| `true` | Browser-based E2E (requires a real browser — e.g., Playwright browser mode, Cypress) |

Backend sprints should only produce E2E scenarios with `requires_browser: false`.
Frontend and fullstack sprints may produce both.

## Scenario Format

When generating test scenarios, use this table format:

```markdown
| Scenario | Layer | Priority | Notes |
|----------|-------|----------|-------|
| Given a valid user submits login form, the session is created | Unit | High | |
| POST /api/auth/login returns 200 with token on valid credentials | API | High | |
| Login button is disabled while request is in flight | UI | Medium | |
| User can log in and reach the dashboard | E2E | High | requires_browser: true |
```

### Priority Guidelines

| Priority | When to assign |
|----------|---------------|
| **High** | Core happy path, security-critical, or data-integrity scenario |
| **Medium** | Important edge case or error condition |
| **Low** | Nice-to-have, cosmetic, or low-risk edge case |

## Epic-Level Integration Scenarios

In addition to per-Sprint scenarios, generate one set of **integration scenarios** per Epic. These cover:
- Interactions between Sprints within the same Epic (e.g., data produced by Sprint 1 consumed by Sprint 2)
- Cross-cutting concerns that span multiple Sprints (e.g., audit logging, authorization checks)
- End-to-end flows that only make sense when multiple Sprints are complete

Use `Integration` as the layer value for these scenarios.
