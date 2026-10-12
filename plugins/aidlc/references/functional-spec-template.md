# Functional Specification — template (one document per Feature)

The single BA/PO-authored document that carries the whole requirement. Written prose-first; each fact
has one canonical section; stable ids (`FR-*`, `AC-*`, `TC-*`, `ADR-*`) make it traceable; the governed
numbers live on the separate **Governed Values** page and are referenced by name. Status lives on the
separate **Status** page. See `artifact-consolidation.md`.

## Section order

1. **Header** — Document id (`FI-*`), status line ("Approved — live status on the Status page", linked),
   version, source of truth (upstream), realised-by (Epic/Stories keys), work tracking, stack.
2. **Overview & purpose** — what this builds and why; relationship to any upstream source. Prose.
3. **Problem & context** — the problem; in-scope / out-of-scope (each out-of-scope item with a reason).
4. **Goals & non-goals.**
5. **Stakeholders** — persona · what they need · what they should not need to know.
6. **Decomposition & FR→sprint map** — one Epic by default; a table mapping each Sprint/Story to the
   `FR-*` ids it realises and its risk class (see `risk-governance.md`).
7. **Functional requirements** — a labelled register: `FR | requirement | priority | risk | AC ids`.
   One line per requirement; risk per `risk-governance.md`.
8. **How it works (solution)** — the solution narrative a BA/PO and an engineer can both read, plus the
   one architecture diagram (Mermaid) that earns its place. Code-identifier-free where possible.
9. **Decision log (ADRs)** — each decision a short `## ADR-NN` section (Context / Decision /
   Consequences / Alternatives). Promote to its own page only if cross-feature.
10. **Data sources & lineage** — source system → attributes pulled → canonical mapping → computation →
    UI element → availability this milestone (ground in the source dictionary when one exists; be honest
    about what is measurable vs deferred).
11. **Acceptance criteria** — the authoritative **EARS** criteria with stable `AC-*` ids. The numbers
    they depend on are cited by name from the **Governed Values** page, not restated here.
12. **Test scope** — layered scenarios (per sprint + integration) and the **bidirectional coverage
    matrix** (`AC ↔ TC`, closes both ways).
13. **Non-functional requirements** — the quality bar in words; numeric targets cited from Governed Values.
14. **Business rules** — the invariants the build must hold.
15. **Risks, assumptions & dependencies.**
16. **Open items** — with owner and whether each is a Verify-gate / pre-build / release gate (and whether
    it is a security/compliance gate, which a readiness score can never override — `risk-governance.md`).
17. **Source traceability & first delivery slice.**
18. **Version history.**

## Companion pages (the only two kept separate)

- **Governed Values — <Title>** — the versioned numbers (thresholds/gates/simulation params/retention/
  calendar), each as an immutable version; referenced by id from §11/§13.
- **Status — <Title>** — the phase-status table; the only place phase state lives.

## Rules

- **Single home per fact.** A number lives once on Governed Values; an AC once in §11; a decision once
  in §9. Everywhere else references by id/name. Never duplicate.
- **Keep it readable.** Prose leads; tables/diagrams earn their place; navigable by its headings.
- **Edit with `contentFormat: html`** once it contains a diagram/macro; keep Status and Governed Values
  separate so routine flips don't republish the spec.
