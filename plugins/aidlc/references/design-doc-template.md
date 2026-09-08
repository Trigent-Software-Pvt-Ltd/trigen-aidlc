# AI-DLC Design Document — the solution specification

The Design Document establishes **HOW** a feature is built — the counterpart to the PRD's **WHAT/WHY**.
It must be a **shared artifact**: a plain-language solution overview a **BA/PO can validate**, then
enough technical detail that engineers can build without inventing decisions, and enough traceability
that every requirement maps to code and tests.

> A design note is **not** two lines. Even at the light gear, a design produces this structured
> document — sections are short for a small feature, fuller for a large one. **Scale depth, not
> structure.**

## What it is / isn't

- **Is:** architecture, data model, API/contract detail, flows, business-rule enforcement, security,
  error handling, algorithms, test strategy, traceability.
- **Isn't:** a re-statement of the PRD (link it, don't copy), a task board, or final production code.
  Cross-cutting or shared-contract decisions become **ADRs** — referenced here, not buried.

## Audience layering (why BA/PO can read it)

Sections **1, 2, 6, 7, 9** are written in plain language for a BA/PO to validate the solution shape
(what it does, the flow, the rules, who's allowed). The rest carry the engineering detail. Keep the
plain-language sections free of code identifiers where possible.

## Section set (all design docs — depth scales)

1. **Overview & context** — what this designs, the PRD/brief FRs it realises, audience note.
2. **Solution summary** *(plain language)* — the approach in a short paragraph a BA/PO can validate.
3. **Architecture & components** — layers/services, where it lives, a small diagram; external calls.
4. **Data model** — tables/entities, fields, types, constraints, indexes. (ER sketch if it helps.)
5. **API / interface design** — endpoints or interfaces: request/response, status codes, validation
   rules, what is server-derived vs client-supplied.
6. **Key flows** *(plain language)* — happy path **and** failure paths, step by step.
7. **Business rules → enforcement** *(plain language)* — each `BR-*` mapped to where/how it's enforced.
8. **Validation & error handling** — field rules, the error catalog, race-safety, no-partial-write.
9. **Security & permissions** *(plain language)* — authorization, tenant isolation, what's enforced
   server-side, sensitive operations. Mark HIGH-risk areas.
10. **Non-functional approach** — accessibility, performance, reliability, observability.
11. **Algorithms / key logic** — any non-trivial logic spelled out (e.g. an id/signature algorithm).
12. **Test strategy** — unit/integration cases incl. **negative and permission** paths; fixtures.
13. **Traceability** — `FR/AC → task → test`. Every AC maps to at least one test.
14. **Decisions & open items** — decided points; **ADR links** for cross-cutting/shared-contract
    decisions; open questions with proposed defaults (never silently invented).
15. **Impact & dependencies** — what it touches, upstream/downstream, migration/rollout notes.

## How the gears size it

- **Quick** — folded into the brief's "What we build"; no standalone doc.
- **Standard (default)** — **this full document**, every section present, most short; full API/schema/
  flow/tests for the feature's P0s; only forced ADRs. One sprint-sized feature. *(A two-line note is
  not acceptable at Standard — that was the old behavior.)*
- **Deep** — the full document **plus** a formal domain model, alternatives-considered, sequence
  diagrams, and cross-feature/data-critical analysis. Multi-team / regulated / high blast radius.

## Relationship to the rest of AI-DLC

PRD (WHAT) → **Design Document (HOW)** → Task Specs (the smallest buildable units, carried in the
design or elaborate) → Code → Test. The design consumes the PRD's `FR/AC/BR`; it does not restate
them — it says how each is met and points back by id. Shared-contract or cross-cutting decisions are
raised as ADRs and linked from §14.
