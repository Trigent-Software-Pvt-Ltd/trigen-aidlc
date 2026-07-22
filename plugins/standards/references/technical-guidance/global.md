---
owner: Architecture Guild
last-reviewed: 2026-02-04
scope: All projects, all technologies
---

# Global Technical Guidance

Universal architectural standards that apply to all projects regardless of technology stack or implementation approach.

## How to Use This Guidance

- These standards represent organizational best practices
- Deviations are allowed but require an ADR documenting the rationale
- Project-type guidance (Ruby, .NET, etc.) may extend or refine these standards
- Project-level guidance in the Intent doc may override for specific initiatives

---

## Security

### Secrets Management

| Standard | Requirement |
|----------|-------------|
| Secrets storage | Never in code or config files; use vault or cloud secrets manager |
| API keys | Scoped to minimum required permissions; rotated quarterly |

### OWASP Top 10 Mitigations

All projects must address:

- [ ] Injection (SQL, command, LDAP) - Use parameterized queries and input validation
- [ ] Broken authentication - Implement proper session management
- [ ] Sensitive data exposure - Encrypt at rest and in transit
- [ ] XXE - Disable external entity processing
- [ ] Broken access control - Verify authorization on every request
- [ ] Security misconfiguration - Harden defaults, disable unnecessary features
- [ ] XSS - Output encoding, Content Security Policy
- [ ] Insecure deserialization - Validate and sanitize serialized data
- [ ] Using components with known vulnerabilities - Dependency scanning in CI
- [ ] Insufficient logging - Audit trail for security events

---

## Observability

### Logging

| Standard | Requirement |
|----------|-------------|
| Format | Structured JSON (not plaintext) |
| Levels | ERROR, WARN, INFO, DEBUG; INFO default in production |
| PII | Never log PII, credentials, or tokens; mask if unavoidable |

---

## API Design

### REST Conventions

| Standard | Requirement |
|----------|-------------|
| Versioning | URL path versioning (`/v1/`, `/v2/`) |
| Resource naming | Plural nouns, lowercase |
| HTTP methods | GET (read), POST (create), PUT (replace), PATCH (update), DELETE (remove) |
| Status codes | Use appropriate codes; 2xx success, 4xx client error, 5xx server error |

---

## Testing

### Test Pyramid

| Layer | Coverage Target | Scope |
|-------|-----------------|-------|
| Unit tests | 80%+ line coverage | Business logic, domain models |
| Integration tests | Critical paths | Service boundaries, database interactions |
| Contract tests | All external APIs | API compatibility |
| E2E tests | Happy paths only | Critical user journeys |

### Testing Requirements

| Standard | Requirement |
|----------|-------------|
| CI integration | All tests run on every PR |
| Test data | No production data; use factories or fixtures |

---

## Resilience

### Retry Policy

| Standard | Requirement |
|----------|-------------|
| Strategy | Exponential backoff with jitter |
| Max retries | 3 attempts |
| Idempotency | All retried operations must be idempotent |
| Circuit breaker | Required for external service calls |

### Circuit Breaker Settings

| Parameter | Default |
|-----------|---------|
| Failure threshold | 5 failures in 60 seconds |
| Open duration | 30 seconds |
| Half-open requests | 3 |

### Graceful Degradation

| Standard | Requirement |
|----------|-------------|
| Feature flags | Critical features must have kill switches |
| Fallbacks | Define fallback behavior for external dependencies |

---

## Documentation

### Required Documentation

| Artifact | When Required |
|----------|---------------|
| README | All repositories |
| ADRs | Significant architectural decisions |

### ADR Requirements

All ADRs must include:

- Context: What prompted the decision?
- Decision: What was decided?
- Consequences: Trade-offs (positive, negative, risks)
- Alternatives: What other options were considered?

---

## Dependency Management

### Third-Party Libraries

| Standard | Requirement |
|----------|-------------|
| License | Must be compatible (MIT, Apache 2.0, BSD preferred) |
| Maintenance | Prefer actively maintained libraries (commits in last 6 months) |
| Security | No known critical CVEs; automated scanning required |