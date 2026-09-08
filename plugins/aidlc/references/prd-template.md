# AI-DLC PRD — the source specification

The PRD is the **product-facing source of truth** the rest of AI-DLC decomposes: it establishes
**WHAT, WHY, the boundaries, and the observable behavior** — not HOW. Design decides HOW; Stories are
the smallest AI-executable units. The pipeline is:

> **Intent → PRD → Design → Epics/Stories + AC → Implementation Plan → Code → Test → Review → metrics**

In AI-native delivery **specification quality is the bottleneck**, so a PRD must be precise enough
that a *fresh* Claude session can convert it into epics, stories, code, and tests **without inventing
decisions**. That is why Acceptance Criteria, Business Rules, Roles/Permissions, State Lifecycle,
Data/Integration behavior, and Edge/Failure cases are **mandatory**, not deferred to story time.

## Two rules that keep it from bloating

1. **Scale depth, not structure.** Every PRD has the same section set below. For a small feature a
   section may be two sentences; for a large one it expands. Do **not** drop sections — right-size
   them. (This is the ceremony gear applied to the PRD: Quick ≈ a Feature Brief with AC; Standard ≈ a
   compact PRD; Deep ≈ the full PRD.)
2. **A PRD is not a design.** Never turn it into an API spec, DB schema, class design, architecture
   doc, test-case list, task breakdown, or prompt script. Those come *after* the PRD. If you're
   writing endpoint shapes or table columns, you've gone too far — that's `/aidlc-design`.

## Machine-readable requirements (traceability)

Write each functional requirement as an addressable block so the chain
**PRD → Requirement → Story → Code/PR → Test → metric** can be traced:

```
FR-<AREA>-<NNN> — <short title>
Priority: P0 | P1 | P2 · Actor: <role> · Risk: LOW | MED | HIGH · Depends on: <IDs>
Requirement: <one sentence, independently testable>
Acceptance Criteria: AC-<...> (positive), AC-<...> (negative), AC-<...> (permission)
```

Business rules are `BR-NNN`, acceptance criteria `AC-<FR>-NN`. **Authorization logic and external
integrations are HIGH risk** — mark them so, so downstream review/security gates fire.

## Section set (all PRDs — depth scales)

1. **Document Context** — capability, product, owner, status, version, related designs/specs.
2. **Executive Summary** — what we're building, why now, one-paragraph outcome.
3. **Problem / Opportunity** — current state, pain, evidence/impact.
4. **Goals, Outcomes & Non-Goals** — goals; explicit non-goals; product principles/constraints.
5. **Personas & Jobs-to-be-Done** — primary + secondary personas, each with its job/need. State what
   the user should *not* need to know (avoids "non-technical" hand-waving).
6. **User Journey / Primary Flow** — happy-path flow, entry point, exit condition.
7. **Functional Requirements** — `FR-*`, P0/P1/P2, each independently testable (machine-readable block).
8. **Acceptance Criteria** — per FR: positive, **negative**, and **permission** scenarios (Given/When/
   Then where it helps). Mandatory — a requirement without AC is not ready.
9. **Business Rules & Domain Rules** — `BR-*`: invariants, ownership rules, state rules.
10. **Roles, Permissions & Security** — who can do what (a matrix), tenant isolation, authorization
    boundaries, sensitive operations. Enforcement expectations (e.g. server-side, not UI-only).
11. **States & Lifecycle** — states, allowed transitions, and the trigger for each. Mark which
    transitions are in scope for this PRD.
12. **Data & Integration Requirements** — inputs, outputs, systems involved, read/write/sync behavior.
    **What data, not API design.** Be explicit about read-vs-ingest boundaries.
13. **Edge Cases & Exception Handling** — failure scenarios, partial success, recovery behavior.
    Specify expected *system behavior*, not every UI string.
14. **Non-Functional Requirements** — performance, scalability, reliability, security, observability,
    compliance where applicable.
15. **UX / Design References** — Figma/prototype, screen IDs, key interaction rules. Don't duplicate
    the full design spec.
16. **Success Metrics** — adoption, efficiency, quality, business outcome, guardrail metrics.
17. **Scope & Release Phasing** — MVP, later, explicitly deferred.
18. **Dependencies & Assumptions** — upstream, downstream, external assumptions.
19. **Risks & Mitigations** — product, technical, security, delivery.
20. **Open Questions / Decisions Required** — question, owner, proposed answer, status. Never silently
    invent a decision — record it here with a proposed default.
21. **Definition of Ready** — design available, AC complete, dependencies resolved, no open blockers →
    ready for story decomposition. The gate between PRD and `/aidlc-elaborate`.

## How the gears size the PRD

- **Quick** — a **Feature Brief with acceptance criteria** (`feature-brief.md`): sections 2–8 in
  miniature, AC still mandatory (incl. negative + permission), the rest folded in or omitted if truly
  N/A. One feature.
- **Standard (default)** — a **compact PRD**: all 21 sections present, most a few lines; full `FR/AC/
  BR` for this feature's P0s; roles/lifecycle/edge cases stated even if short. One sprint-sized
  feature or a small initiative.
- **Deep** — the **full PRD**: every section developed, cross-feature FRs, complete AC/BR matrices,
  full roles and lifecycle. Multi-team / regulated / high-blast-radius.

## Where the PRD sits vs Feature Briefs

An initiative-level PRD covers several features; each shippable slice becomes a **Feature Brief** that
carries its own `FR/AC/BR` slice. So: **one PRD → several Feature Briefs → Epics/Sprints/Stories+AC.**
The PRD is product-facing and stable; briefs are the build-facing slices. Keep AC in both — the PRD at
FR level, the brief/story at story level.
