# Risk-based governance

One risk vocabulary used consistently across **design → implementation → review → release**, so
higher-risk work gets proportionate rigor — and so a numeric readiness/confidence score can never wave
through a failed mandatory gate.

## Risk factors (any present ⇒ raise the class)
- **Authentication / authorization** (permission ceilings, tenancy, role checks)
- **PII / sensitive data**
- **Financial or regulated** operations
- **Production infrastructure** changes
- **Destructive** changes (data deletion, irreversible migrations)
- **External integrations** (third-party APIs, connectors)
- **AI-generated code & dependency risk** (look-alike/hallucinated packages, large unseen diffs)

## Levels
- **LOW** — localized, reversible, no factor above → standard review; standard gear.
- **MED** — one factor, bounded blast radius → an explicit reviewer pass on the factor; Standard gear.
- **HIGH** — authz/PII/financial/prod/destructive/external, or wide blast radius → **specialist review**
  (security/a11y/perf as relevant, `execution-rigor.md` §6), an **ADR** for the decision, and often the
  **Deep** gear. HIGH-risk authz + external-integration changes always get a security pass.

## Where it's applied
- **Design** — classify the feature; a cross-cutting/shared-contract HIGH decision becomes an **ADR**.
- **Implementation plan** — each unit carries a risk class (`implementation-plan.md`).
- **Work items** — HIGH-risk tickets are labelled so (the work-item template marks authz/integration HIGH).
- **Review** — risk selects the specialist passes and the reviewer depth.
- **Release / completion** — `verification-checklist.md` + the guardrail gates.

## The override rule (ties to ENH-002 enforced gates)
**A readiness or confidence score must never override a failed mandatory security or compliance gate.**
In `enforced` governance the protected gates (publish, secret scan) cannot be downgraded regardless of
score (`guardrails.md`). A high `/aidlc-verify` confidence with a failing security check is **not**
ready — the failed gate wins.
