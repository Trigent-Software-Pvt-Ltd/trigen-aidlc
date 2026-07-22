# SRE Principles & Best Practices

## Core SRE Philosophy (Google SRE)

SRE is what happens when you ask a software engineer to design an operations function. The goal is to sustainably achieve the appropriate level of reliability for each service.

### The Fundamental Tension
- Product teams want to move fast and ship features
- SRE teams want to maintain stability
- **Resolution**: Error budgets — the remaining reliability "budget" above the SLO target defines how much risk is acceptable

---

## Service Level Framework

### SLI (Service Level Indicator)
A carefully defined quantitative measure of some aspect of the service.

**Good SLIs for PSW/Trigent:**
- **Availability**: % of requests that return a successful response (non-5xx)
- **Latency**: % of requests served within X ms (e.g., p95 < 500ms)
- **Error Rate**: % of requests that result in an error
- **Throughput**: Requests processed per second
- **Freshness**: Age of most recent successful data sync

### SLO (Service Level Objective)
A target value or range of values for an SLI. Example:
- 99.9% of requests return 2xx within 500ms, measured over 28 days

### SLA (Service Level Agreement)
An SLO with consequences — typically a contractual commitment to customers.

### Error Budget
```
Error Budget = 1 - SLO
Example: 99.9% SLO → 0.1% error budget
         = 0.1% × 28 days × 24h × 60min = 43.2 minutes/month
```

**Error budget policy:**
- Budget > 50%: Move fast, deploy frequently
- Budget < 50%: Increase testing rigor, slow release cadence
- Budget exhausted: Freeze non-essential releases, focus on reliability

---

## DORA Metrics (Key SRE Health Indicators)

| Metric | Elite | High | Medium | Low |
|--------|-------|------|--------|-----|
| Deployment Frequency | Multiple/day | Daily-weekly | Weekly-monthly | Monthly+ |
| Lead Time for Changes | < 1 hour | 1 day - 1 week | 1 week - 1 month | > 1 month |
| MTTR (Mean Time to Restore) | < 1 hour | < 1 day | 1 day - 1 week | > 1 week |
| Change Failure Rate | 0-15% | 16-30% | 16-30% | 46-60% |

Track these per-stack in Jira/GitLab dashboards.

---

## Toil

**Definition (Google SRE):** Work that is:
1. Manual
2. Repetitive
3. Automatable
4. Tactical (reactive, not proactive)
5. Devoid of enduring value
6. Scales linearly with service growth

**Target:** Toil should be < 50% of each SRE's time. Identify and eliminate.

**Examples of toil in Trigent/PSW context:**
- Manually restarting failed ECS tasks
- Manually re-running failed GitLab pipelines due to flaky runners
- Manually rotating secrets in Key Vault
- Manually updating firewall rules in `sql-database.tf`
- Manually checking Azure/AWS health dashboards during incidents

**Toil reduction approach:**
1. Identify and track toil items in Jira
2. Quantify: hours/week, frequency, manual steps
3. Prioritize: high-frequency + automatable = highest value
4. Automate: scripts, runbooks, self-healing, Terraform, CI/CD

---

## Blameless Postmortem Principles

1. **Blame the system, not the person** — A person makes a mistake because the system allowed it
2. **Focus on contributing factors** — Not "who broke it" but "what conditions enabled the failure"
3. **5 Whys** — Drill into root cause iteratively
4. **Psychological safety** — Engineers must feel safe reporting mistakes
5. **Action items over shame** — Every postmortem ends with concrete improvements
6. **Share widely** — Postmortems published to the whole engineering org (learning opportunity)

### 5 Whys Template
```
Why did X happen?      → Because Y
Why did Y happen?      → Because Z
Why did Z happen?      → Because A
Why did A happen?      → Because B
Why did B happen?      → [Root cause: missing monitoring / process gap / config drift / etc.]
```

---

## AI-Augmented SRE Practices

### AI in Incident Response
- **Automated triage**: AI classifies severity from alert context and symptom description
- **Parallel health checks**: AI orchestrates simultaneous checks across AWS, Azure, GitLab
- **Hypothesis generation**: AI generates ranked root cause hypotheses from symptoms + telemetry
- **Runbook surfacing**: AI finds the relevant runbook section for the detected failure pattern
- **Timeline reconstruction**: AI assembles incident timeline from logs, alerts, and Jira comments

### AI in Postmortems
- **Timeline extraction**: AI parses CI logs, CloudWatch events, deployment history into a timeline
- **Contributing factor analysis**: AI applies 5-Whys framework to the timeline automatically
- **Action item generation**: AI proposes concrete, measurable action items with owners
- **Cross-incident pattern detection**: AI identifies recurring failure patterns across postmortems

### AI in Toil Reduction
- **Toil quantification**: AI analyzes Jira tickets and pipeline logs to measure repetitive work
- **Automation recommendations**: AI proposes specific scripts or Terraform changes to eliminate toil
- **Self-healing runbooks**: AI writes runbooks that can be executed autonomously by future AI agents

### AI in SLO Management
- **SLI candidate identification**: AI analyzes service behavior to recommend what to measure
- **Burn rate alerting**: AI calculates multi-window burn rate alerts from SLO target
- **Error budget forecasting**: AI predicts budget exhaustion based on current error rate trends

---

## Reliability Patterns for AWS/Azure

### Circuit Breaker
Prevent cascade failures by failing fast when a downstream service is unavailable.

### Bulkhead
Isolate components so a failure in one doesn't drain resources from others (ECS task limits, connection pool limits).

### Retry with Exponential Backoff
Avoid thundering herd. Always include jitter.
```
delay = base_delay * (2 ^ attempt) + random(0, base_delay)
```

### Health Checks
- **Liveness**: Is the process running?
- **Readiness**: Is the process ready to serve traffic?
- **Startup**: Has the application finished initializing?

### Graceful Degradation
When a dependency fails, serve a degraded experience rather than an error.
- Example: If Redis is unavailable, fall back to direct DB queries (with rate limiting)

### Chaos Engineering
Proactively inject failures to test resilience:
- Kill an ECS task randomly
- Block a Service Bus subscription
- Throttle Redis connections
- Simulate AZ failure

---

## Observability: The Three Pillars

### 1. Metrics
- Quantitative, time-series data
- Tools: CloudWatch (AWS), Azure Monitor
- Key metrics per service: request rate, error rate, latency, saturation

### 2. Logs
- Discrete events with context
- Tools: CloudWatch Logs, Azure Log Analytics
- Structured logging (JSON) > unstructured

### 3. Traces
- Request lifecycle across services
- Tools: AWS X-Ray, Azure Application Insights
- Critical for microservices and event-driven architectures (Service Bus)

### USE Method (for resources)
- **U**tilization: % time resource is busy
- **S**aturation: Amount of work queued
- **E**rrors: Error events

### RED Method (for services)
- **R**ate: Requests per second
- **E**rrors: Failed requests per second
- **D**uration: Response time distribution
