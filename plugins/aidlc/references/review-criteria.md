# Review Criteria Reference

Shared scoring rubrics, quality checklists, and skill-specific rubrics for AI-DLC documentation and implementation review. Used by `/aidlc-review`, `/aidlc-verify`, and `/aidlc-sprint`.

---

## Part 1: Shared Foundations

### 1.1 Scoring Scale

All dimensions use a 0-100 scale.

| Range | Label | Meaning |
|-------|-------|---------|
| 80-100 | High confidence | Solid work, minor issues only |
| 60-79 | Concerns | Notable issues that should be resolved |
| 0-59 | Significant issues | Substantial rework needed |

### 1.2 Confidence Thresholds

| Level | Score | Action |
|-------|-------|--------|
| **High** | 80-100 | Proceed — documentation or implementation is solid |
| **Medium** | 60-79 | Address gaps — notable issues to resolve before proceeding |
| **Low** | <60 | Stop — substantial rework needed before continuing |

### 1.3 Finding Severity Levels

| Severity | Definition | Example |
|----------|-----------|---------|
| **Blocking** | Must fix before merge/approval. Correctness, security, or data safety issue. | SQL injection, missing auth check, AC not implemented |
| **High** | Should fix before merge. Quality or reliability concern. | Missing error handling, untested AC, N+1 query |
| **Medium** | Improve in this MR or follow-up. Maintainability or best practice. | Poor naming, missing edge case test, inconsistent style |
| **Low** | Consider improving. Nice-to-have. | Minor style preference, optional refactoring opportunity |

---

## Part 2: Shared Quality Checklists

These checklists are shared across skills. Each skill-specific rubric in Part 3 references the relevant checklists.

### 2.1 Document Completeness Checklists

#### Feature Document
- [ ] Feature Summary present
- [ ] Problem / Opportunity described
- [ ] Target Users identified
- [ ] Assigned Amigos listed (PO, Tech Lead, Design Lead)
- [ ] Feature Profile complete (pathway, scale, constraints, programme)
- [ ] Outcomes defined (business + user)
- [ ] Scope defined (in scope + out of scope)
- [ ] Technical Considerations listed
- [ ] NFRs with measurable targets
- [ ] Measurement Criteria (OKR/KPI/SLI)
- [ ] Dependencies listed
- [ ] Risks identified (using Organizational Risk Taxonomy)
- [ ] Assumptions documented
- [ ] Testing Strategy outlined
- [ ] Open Questions captured

#### Epic Page
- [ ] Description / scope summary
- [ ] Tasks table with status
- [ ] Sprint Plan table (Sprint, Scope, Tasks, Estimate)
- [ ] Dependencies (depends on, blocks, external)
- [ ] Risks table (Risk, Impact, Likelihood, Mitigation)

#### Task Page

**Task Spec format (AIDLC 3.9+):**
- [ ] `id` and `title` in frontmatter
- [ ] `sprint` and `size` in frontmatter
- [ ] `## Behaviour` section with at least one item
- [ ] `## Rules` section (optional — omit if no hard constraints)
- [ ] `files` frontmatter (optional — omit if no file-level detail available)
- [ ] `dependencies` frontmatter (optional)

**User story format (legacy, valid through AIDLC 3.9.x):**
- [ ] Summary present
- [ ] User story format (As a... I want... So that...)
- [ ] Acceptance criteria in checkbox format
- [ ] Context section
- [ ] Dependencies with references
- [ ] Risks table
- [ ] Test Notes

#### Design Document
- [ ] Domain model (entities, value objects, aggregates)
- [ ] Bounded context boundaries defined
- [ ] Context map (upstream/downstream relationships)
- [ ] ADRs for key architectural decisions
- [ ] Integration points identified

### 2.2 Vague Language Patterns

Flag and deduct points for any of the following patterns:

| Pattern | Example | Remediation |
|---------|---------|-------------|
| **Open-ended scope** | "and more features", "etc.", "various improvements" | Define explicit boundaries |
| **Untestable criteria** | "should be fast", "user-friendly", "secure" | Add measurable targets |
| **Missing specifics** | "connects to backend" without naming APIs/services | Identify specific APIs/services |
| **Boilerplate content** | Sections copied without customisation | Rewrite with project-specific detail |
| **Unmeasurable NFRs** | "good performance", "high availability" | Add specific targets (see 2.3) |
| **Undefined scope** | "the system should handle X" — which system? | Clarify system boundaries |
| **Unclear referents** | Pronouns with unclear referents in technical context | Use explicit names |

### 2.3 NFR Measurability Criteria

NFRs must include measurable targets. Flag NFRs that do not meet this standard.

| NFR Category | Bad (unmeasurable) | Good (measurable) |
|-------------|-------------------|-------------------|
| Performance | "should be fast" | "API response <200ms p95" |
| Availability | "high availability" | "99.9% uptime, <5min recovery" |
| Security | "must be secure" | "OWASP Top 10 mitigated, encrypted at rest with AES-256" |
| Scalability | "should scale" | "Support 10k concurrent users with <10% latency increase" |
| Reliability | "reliable system" | "Zero data loss on failover, RPO=0, RTO<15min" |

Baselines should be documented where possible (current performance vs. target).

### 2.4 Accuracy and Consistency Checks

Apply these checks across all documents in scope:

- **Terminology consistency** — same terms used across documents for the same concepts
- **Scope alignment** — Epic scope matches Feature scope; no scope creep or gaps
- **AC consistency** — Task AC aligns with Epic/Sprint scope
- **Dependency consistency** — referenced items exist in other documents
- **NFR consistency** — targets don't contradict across documents
- **Contradiction detection** — identify statements in one document that conflict with another

---

## Part 3: Skill-Specific Rubrics

### 3.1 Documentation Review Rubric (aidlc-review Path A)

5 dimensions. Use with `/aidlc-review` Path A.

#### Completeness (weight: 25%)

| Score Range | Criteria |
|-------------|----------|
| 90-100 | All required sections present, thorough coverage, no gaps |
| 70-89 | Most sections present, minor gaps that don't block understanding |
| 50-69 | Several sections missing or incomplete |
| 0-49 | Major sections missing, document is a skeleton |

Apply Document Completeness Checklists from **Part 2.1** for the relevant document type.

#### Quality (weight: 25%)

| Score Range | Criteria |
|-------------|----------|
| 90-100 | Clear, specific, actionable content throughout. No vague language. |
| 70-89 | Mostly clear with occasional vague statements |
| 50-69 | Multiple vague or untestable statements |
| 0-49 | Predominantly vague, unclear, or boilerplate content |

Apply Vague Language Patterns from **Part 2.2** and NFR Measurability from **Part 2.3**.

#### Accuracy (weight: 25%)

| Score Range | Criteria |
|-------------|----------|
| 90-100 | Internally consistent, aligns with Feature, no contradictions |
| 70-89 | Minor inconsistencies that don't cause confusion |
| 50-69 | Several inconsistencies between documents |
| 0-49 | Major contradictions that would cause implementation errors |

Apply Accuracy and Consistency Checks from **Part 2.4**.

#### Ambiguity Risk (weight: 15%)

Lower ambiguity = higher score.

| Score Range | Criteria |
|-------------|----------|
| 90-100 | Unambiguous throughout, boundaries crystal clear |
| 70-89 | Minor ambiguities that can be resolved from context |
| 50-69 | Several statements open to interpretation |
| 0-49 | Pervasive ambiguity, multiple valid interpretations |

**Check for:**
- Statements with multiple valid interpretations
- Undefined technical terms or acronyms
- Unclear boundaries ("the system should handle X" — which system?)
- Implicit assumptions not stated
- Pronouns with unclear referents in technical context

#### Open Questions (weight: 10%)

Fewer unresolved questions = higher score.

| Score Range | Criteria |
|-------------|----------|
| 90-100 | No unresolved questions, or only minor clarifications needed |
| 70-89 | A few open questions, none blocking |
| 50-69 | Several open questions, some could block implementation |
| 0-49 | Critical questions unanswered, cannot proceed safely |

---

### 3.2 Implementation Review Rubric (aidlc-review Path B)

4 dimensions. Use with `/aidlc-review` Path B.

#### Requirements Fit (weight: 30%)

| Score Range | Criteria |
|-------------|----------|
| 90-100 | All AC addressed, appropriate scope, edge cases handled |
| 70-89 | Most AC addressed, minor gaps in edge cases |
| 50-69 | Several AC not addressed or implementation scope misaligned |
| 0-49 | Fundamental mismatch between AC and implementation |

**Check for:**
- Each AC has corresponding implementation
- No over-engineering beyond AC scope
- No missing pieces that AC requires
- Edge cases from AC are handled in code
- Scope creep (changes not tied to any AC)

#### Code Quality (weight: 25%)

| Score Range | Criteria |
|-------------|----------|
| 90-100 | Clean, well-structured, follows project conventions, readable |
| 70-89 | Good quality with minor style or structure issues |
| 50-69 | Notable quality issues affecting maintainability |
| 0-49 | Poor quality, hard to understand or maintain |

**Check for:**
- Naming: descriptive variable/method/class names
- Structure: logical file organisation, appropriate abstractions
- Conventions: follows project linter/formatter/style configs
- DRY: no unnecessary duplication (but don't penalise intentional repetition for clarity)
- Complexity: methods/functions not excessively long or nested
- Comments: present where logic isn't self-evident (not over-commented)

**Performance anti-patterns to flag** (not a separate dimension):
- N+1 queries
- Unbounded loops or fetches
- Missing database indexes for new queries
- Loading entire collections when only a subset is needed
- Synchronous calls that should be async

#### Testing Adequacy (weight: 25%)

| Score Range | Criteria |
|-------------|----------|
| 90-100 | All AC tested, edge cases covered, negative tests present, good test quality |
| 70-89 | Most AC tested, some edge cases covered |
| 50-69 | Significant gaps in test coverage |
| 0-49 | Minimal or no tests, or tests don't verify AC |

**AC-to-test mapping checklist:**
- [ ] Each AC has at least one corresponding test
- [ ] Tests verify the AC (not just tangentially related)
- [ ] Test names clearly describe what they verify

**Gap analysis checklist:**
- [ ] Edge cases tested (boundary values, empty inputs, max values)
- [ ] Negative tests present (invalid inputs, unauthorised access, error paths)
- [ ] Error handling tested (what happens when dependencies fail)
- [ ] Concurrency concerns tested (if applicable)

**Test quality checklist:**
- [ ] Tests are independent (don't depend on execution order)
- [ ] Tests use meaningful assertions (not just `assert true`)
- [ ] Test data is clear and purposeful
- [ ] Mocks/stubs are appropriate (not mocking the thing under test)

#### Security & Reliability (weight: 20%)

| Score Range | Criteria |
|-------------|----------|
| 90-100 | Input validated, auth checks present, errors handled, no data leaks |
| 70-89 | Most security concerns addressed, minor gaps |
| 50-69 | Notable security gaps or missing error handling |
| 0-49 | Critical security issues or fundamental reliability problems |

**Security checklist:**
- [ ] User input validated and sanitised
- [ ] Authentication checks present where needed
- [ ] Authorisation enforced (users can only access their own data)
- [ ] No SQL injection, XSS, or command injection vectors
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] No PII/PHI in logs or error messages
- [ ] CSRF protection where applicable
- [ ] Appropriate use of parameterised queries

**Reliability checklist:**
- [ ] Errors handled gracefully (no unhandled exceptions in user paths)
- [ ] External service calls have timeouts
- [ ] Retry logic where appropriate (with backoff)
- [ ] Database transactions used correctly
- [ ] Rollback capability considered

---

### 3.3 Verification Readiness Rubric (aidlc-verify)

Used by `/aidlc-verify` to assess whether documentation is ready for AI execution and Jira transfer.

#### Main Assessment Categories

| Category | Weight | Criteria |
|----------|--------|----------|
| **Feature Clarity** | 20% | Problem/scope/outcomes clearly defined, no vague language |
| **Task Completeness** | 25% | All Tasks have testable acceptance criteria |
| **Design Readiness** | 25% | Domain model documented, patterns chosen, ADRs for key decisions |
| **NFR Coverage** | 15% | Measurable targets (not "fast", "secure"), baselines documented |
| **Dependency Mapping** | 15% | Integration points identified, APIs/services listed, sequencing clear |

#### Sub-agent Scoring Dimensions

Sub-agents score each Epic on these 6 dimensions (0-100 each):

1. **Scope Clarity**
   - Is the Epic scope bounded? (no "and more", "etc.", vague outcomes)
   - Are deliverables specific and measurable?
   - Deduct points for open-ended language (see Part 2.2)

2. **Task Quality**
   - Do all Tasks have acceptance criteria or Behaviour items?
   - Are acceptance criteria / Behaviour items testable (not vague)?
   - **Format detection:** Check `bodyMarkdown` for `## Behaviour` (Task Spec) or "As a..." (user story). Apply the matching checklist from Part 2.1. Flag if neither pattern detected.
   - Apply Task Page checklist from Part 2.1

3. **Technical Readiness**
   - Are integration points identified (APIs, services, databases)?
   - Are data models or schemas referenced?
   - Are error handling expectations documented?

4. **NFR Specificity**
   - Are performance targets measurable (e.g., <200ms, not "fast")?
   - Are security requirements specific?
   - Are availability/reliability targets defined?
   - Apply NFR Measurability Criteria from Part 2.3

5. **Dependency Clarity**
   - Are blockers and prerequisites documented?
   - Is sequencing clear (what comes first)?
   - Are external dependencies identified?

6. **Sprint Grouping Quality**
   - Are Tasks grouped into cohesive Sprints?
   - Does each Sprint have a clear scope (hours to days)?
   - Are there no circular dependencies between Sprints?
   - Are sprint-to-sprint dependencies explicitly identified?
   - Is a Sprint Execution Plan with phases and lanes documented?
   - Are independent Sprints assigned to parallel lanes within the same phase?
   - Is each Sprint appropriately sized? (< 2h = overhead; > 3d = risk)
   - Is a critical path identified?
   - Are parallelism opportunities documented (teams needed per phase)?

#### Gap Categories

When identifying gaps, categorise them:

| Gap Type | Example | Remediation |
|----------|---------|-------------|
| **Vague scope** | "and more features" | Define explicit boundaries |
| **Missing AC** | Task without acceptance criteria | Add testable conditions |
| **Unmeasurable NFR** | "should be fast" | Add specific target (e.g., <200ms) |
| **Unknown integration** | "connects to backend" | Identify specific APIs/services |
| **Missing design** | No domain model | Run `/aidlc-design` |
| **Poor Sprint grouping** | Tasks span unrelated areas | Regroup into cohesive Sprints |
| **Missing sprint dependencies** | No dependency or parallelism analysis | Create Sprint Execution Plan with phases, lanes, critical path |
| **Missing execution plan** | No phased execution plan | Generate Sprint Execution Plan with Phase/Lane structure |
| **Oversized Sprint** | Sprint estimated > 3 days | Split into smaller Sprints |
| **Undersized Sprint** | Sprint estimated < 2 hours | Merge with related Sprint |
| **Circular dependency** | Sprints have circular dependency chain | Restructure into a DAG |

#### Sprint Grouping Quality Scoring Guide

| Score Range | Criteria |
|-------------|----------|
| 90-100 | Full Sprint Execution Plan with phases, lanes, critical path, parallelism table. All dependencies explicit. Sprints sized 2h-3d. No circular deps. |
| 70-89 | Dependencies identified, phases assigned, but missing critical path or parallelism analysis. Minor sizing issues. |
| 50-69 | Dependencies partially identified. No phased execution plan. Some sprints over/under-sized. |
| 0-49 | No dependency analysis. Sprints listed without sequencing. Sizing inappropriate. |

---

## Appendix A: Common Sprint-Time Findings

Recurring patterns surfaced in implementation reviews. Used by `/aidlc-sprint` Step 13.5 self-review checklist and REFACTOR step. When these patterns are present, classify using §1.3 severity levels.

| Pattern | Typical Severity | Description |
|---------|-----------------|-------------|
| **Untestable construction** | High | A `new XxxClient(...)` (or similar) is instantiated directly inside a handler or service, preventing unit tests from substituting the dependency. The wrapping path (payload building, event publishing) has zero automated assertions as a result. |
| **Exception type on DTO boundary** | Medium | A response DTO carries a raw `Exception` (or derived type) property. This leaks stack traces, CLR type details, and inner exception chains across a service boundary, and makes the DTO non-serialisable if ever transmitted or persisted. Replace with a string error message property. |
| **Silent enum integer serialization** | Medium | An enum field in a JSON payload serialises as its ordinal integer by default (e.g. Newtonsoft.Json without a converter). If the AC or downstream consumers expect a human-readable string, this is a silent contract violation. Requires an explicit `[JsonConverter(typeof(StringEnumConverter))]` or equivalent — or documented acceptance of integer encoding. |
| **Swallowed close/dispose exception** | Medium | A `finally { try { resource.CloseAsync(); } catch { } }` block silently discards dispose/close failures. Connection leaks and SDK errors become invisible in observability tooling. The inner catch must log at minimum Warning with the failure details. |
| **Dead DTO property** | Low | A property on a request or response DTO is set but never serialised into the outbound payload and never read by any consumer. Dead properties mislead future readers and accumulate as cargo-cult conventions. Remove or add to the payload if downstream subscribers need it. |
| **Concern conflation** | High | Two logically independent concepts (e.g. "host identity" and "notification feature enabled") are gated by a single condition. Consumers that need only one concept silently receive null/empty for both when the flag is off. Separate the conditions so each concern is resolved independently. |
| **Misleading test name** | Low | A test name claims to verify one scenario but actually exercises a different or broader scenario (e.g. `WhenNoSignedInIds` but the test passes an ID and stubs the repo to return empty rows). Rename the test to describe what it actually asserts. |
