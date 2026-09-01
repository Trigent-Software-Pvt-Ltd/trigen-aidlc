# Work-Item Template (Jira Story/Task/Bolt descriptions)

Canonical structure for the **leaf work-item description** created during `/aidlc-verify` Phase 6
(Confluence & GitLab backends → Jira; Linear applies the same body to the Issue description).
The `task-creator` agent MUST build every leaf item's description from this template, and
`/aidlc-verify` MUST pass the fields below to the agent.

> **Format:** write the description as **Markdown** (`###` headings, `-` bullets, backtick `code`,
> `[text](url)` links) and create the item with **`contentFormat: "markdown"`** (Atlassian MCP
> `createJiraIssue`/`editJiraIssue`) or `acli ... --description-file <md>` where acli converts
> Markdown to ADF. **Never** wrap the whole description in an ADF `codeBlock` — it renders as
> monospaced pre-text. **Never** emit Jira wiki markup (`h3.`, `[text|url]`) under markdown.

## Section order (required unless marked optional)

1. `### Overview` — 2–3 sentences: what this builds and why. *(synthesize from title + primary behaviour + epic context)*
2. `### User Story` — `As <role/service/persona>, I need <capability> so that <reason>.` *(role from the Epic's target users; capability from the task; reason from the epic outcome)*
3. `### Scope` — bullets of in-scope behaviour *(from Behaviour + in-scope Rules)*
4. `### Out of Scope` — from Not in Scope *("None" if empty)*
5. `### Dependencies` — each dependency mapped to the **real work-tracker key**: `**Blocked by** <KEY> (<U0x-Tyy>) — <reason>` or `Non-blocking: <reason>` *("None" if independent)*
6. `### What to build` — `**Goal:** <one line>` then `**Implementation checklist (do all items):**` imperative bullets (ADD / IMPLEMENT / BUILD / EXPOSE / CONFIGURE / DOCUMENT / TEST …) derived from Behaviour + `files`
7. `### Technical notes` — hard constraints (Rules) + `[ASSUMED]` items (verbatim) + the applicable stack *(optional — omit if none)*
8. `### APIs and interfaces` — endpoints/methods with request/response shapes from the Data Contract; for UI items list the endpoints **consumed**; "internal service, no HTTP" where applicable *(required when the spec has a Data Contract; else optional)*
9. `### Acceptance criteria` — the spec's ACs grouped as `**AC 1 — <label>**`, `**AC 2 — …**`, each with Given/When/Then bullets and **concrete values**; include request/response bodies where the Data Contract defines them; then sub-blocks:
   - `**Data Contract**` — typed fields *(when present)*
   - `**Errors & edge cases**` — from the Errors table *(when present)*
   - `**UI States**` — loading / empty / error / success / disabled-permission *(UI items only)*
10. `### Verification steps` — numbered `Step 1..N`, concrete and runnable, derived from the ACs / sprint test scope
11. `### Definition of done` — the boilerplate below
12. `### References` — the deep-links below

### Definition of done (boilerplate)

- Code merged to the feature branch; the PR description references this work item's key.
- Acceptance criteria demonstrated locally or via screen recording.
- Relevant Verify test case(s) executed; evidence linked in a work-item comment.
- No P0/P1 bugs open for this work item's scope.

### References (deep links, resolved from BackendContext / aidlc.config.yaml)

- **Feature:** `[<featureId> — <title>](<featureUrl>)`
- **Design:** `[Design](<designUrl>)` · `[ADRs](<adrsUrl>)`
- **Business Rules:** `[Business Rules](<businessRulesUrl>)` *(if the project has one)*
- **Task Spec:** `[<U0x-Tyy>](<taskSpecUrl>)`
- **Board:** `[<projectKey> board](<boardUrl>)`

## Source mapping (Task Spec → template)

| Template section | Task Spec source |
|---|---|
| Overview | `## Behaviour` intro + epic context (synthesized) |
| User Story | epic target users + task title + epic outcome (synthesized) |
| Scope | `## Behaviour` + in-scope `## Rules` |
| Out of Scope | `## Not in Scope` |
| Dependencies | `dependencies` frontmatter / `## Dependencies` → mapped to work-item keys |
| What to build | Behaviour (goal) + `files` + Behaviour (checklist) |
| Technical notes | `## Rules` + `## Assumptions` (`[ASSUMED]` verbatim) + stack |
| APIs and interfaces | `## Data Contract` |
| Acceptance criteria (+ sub-blocks) | `## Acceptance Criteria` + `## Data Contract` + `## Errors & Edge Cases` + `## UI States` |
| Verification steps | derived from ACs + the epic's sprint `## Test Scope` |
| Definition of done | boilerplate |
| References | fixed deep-links |

**Fidelity rule:** preserve concrete values, tables, request/response bodies, and `[ASSUMED]` items
**verbatim** — never summarize them away. Use the spec's real `## Acceptance Criteria`; do not
re-synthesize ACs from Behaviour when the spec provides them.

## Labels (per leaf work item)

Apply this configurable set (from `workItemTemplate.labels` in `aidlc.config.yaml`):

```
aidlc, NoQA, <leafType>, <featureId>, <productSlug>, <layer>, <epicId>, sprint-<n>
```

- `NoQA` = standing convention label (literal; remove it from `workItemTemplate.labels` to drop it, or gate it on the team's QA policy)
- `<leafType>` = `story` | `task` | `bolt` (matches `jira.issueTypes.leaf`, lower-cased)
- `<featureId>` = e.g. `FI-0001`
- `<productSlug>` = e.g. `bench-resource-tracker`
- `<layer>` = `backend` | `frontend` | `fullstack` | `platform` — **derived per ticket** from its own `files`/`behaviour` (API/DB/service files → `backend`; UI/component/page files → `frontend`; both → `fullstack`; infra/IaC → `platform`). Falls back to the sprint type when the task's own signal is ambiguous.
- `<epicId>` = e.g. `U01`
- `sprint-<n>` = sprint grouping number

Literal tokens (e.g. `aidlc`, `NoQA`) are applied verbatim; `<angle-bracket>` tokens are resolved per item. Epics keep `aidlc:epic`, `aidlc:designed`, `<featureId>`, `<productSlug>`.

## Estimation (per leaf work item)

Set the estimate from the task's Fibonacci `size`, per `workItemTemplate.estimation`:

- `mode: points` — write **Story Points** only (`story_points_field`, default `customfield_10016`).
- `mode: hours` — write **Original Estimate** only (`timetracking.originalEstimate`), converting `size` via `pointsToHours`.
- `mode: both` (default) — write **both** Story Points and Original Estimate.

Default `pointsToHours`: `1→2h, 2→4h, 3→8h, 5→16h, 8→24h, 13→40h`. Story Points remain the source of truth; hours are a derived convenience. If neither field is configured/available, log a LOW warning and continue (estimation is non-blocking).

## Toggle & backward compatibility

`workItemTemplate.enabled: false` restores the legacy minimal description (Behaviour + AC + link).
Re-running transfer over existing items updates descriptions in place (idempotent) rather than
duplicating.
