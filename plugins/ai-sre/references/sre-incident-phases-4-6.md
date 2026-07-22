# sre-incident Phases 4–6

Read in full once Phase 3 contradiction testing is complete. All Hard Rules and Core Definitions from `SKILL.md` still apply — this file only holds the Phase 4–6 procedure and output templates.

## Phase 4: Root Cause vs Mitigation

These are **separate decisions** with separate evidence requirements. Output them separately.

### Root Cause Confirmation

A hypothesis is confirmed as root cause when it meets **either** threshold:
- 1 `VERIFIED` signal in Evidence For, OR
- 2+ `CORRELATED` signals in Evidence For with zero `VERIFIED_NEGATIVE` signals

**When confirmed:**
```
ROOT CAUSE CONFIRMED
Hypothesis: [H# — description]
Confirming Evidence:
  • [signal — source, detail, level, timestamp]
  • [signal — source, detail, level, timestamp]  (if applicable)
Checks run: N of N
Eliminated: [H# — reason] [H# — reason]

→ Update scorecard: Confirmed Root Cause = [hypothesis]
                    Status of confirmed hypothesis = CONFIRMED
```

**When not confirmed:**
```
ROOT CAUSE UNCONFIRMED
Top candidate: [H# — description] at [level]
Gap: needs [N more corroborating signals | 1 VERIFIED signal]
Next discriminating check: [exact command]
```

### Mitigation Authorization

**Reversible actions** (mitigation before confirmed root cause permitted for SEV1):
restore SG rule · rollback deploy · restart pod/task/service · flush cache · scale up replicas · re-enable feature flag

**Irreversible actions** (always require confirmed root cause):
schema change · data operation · secret rotation · DNS change · certificate revocation · IP block

**Authorization matrix:**

| Situation | Reversible | Irreversible |
|-----------|------------|--------------|
| SEV1, root cause unconfirmed, 1 `VERIFIED` signal | **AUTHORIZED** | Not authorized |
| SEV1, root cause unconfirmed, < 1 `VERIFIED` signal | Not authorized | Not authorized |
| Root cause confirmed, any SEV | **AUTHORIZED** | **AUTHORIZED** |
| Root cause unconfirmed, SEV2–4 | Not authorized | Not authorized |

**When authorized:**
```
MITIGATION AUTHORIZED
Action: [exact description]
Type: REVERSIBLE | IRREVERSIBLE
Basis: [confirmed root cause | SEV1 early mitigation — 1 VERIFIED signal]
Note: [authorized before root cause confirmed — investigation continues | N/A]

→ Update scorecard: Mitigation Authorized = [action]
```

---

## Phase 5: Remediation Plan

**Goal:** Produce exact, executable remediation. Include verification and rollback.

For each authorized mitigation:

```
## Remediation Plan

### Action
[exact CLI command — no placeholders, no <variable> tokens]

Reversibility: REVERSIBLE | IRREVERSIBLE
Expected effect: [what changes immediately after running]

### Verification
Command to confirm the fix applied:
  [exact command]
Expected healthy output: [what you should see]

### Rollback
Command to undo (if REVERSIBLE):
  [exact rollback command]
```

**When mitigation treats a symptom but not the root cause:**
```
⚠ SYMPTOM MITIGATION — ROOT CAUSE REQUIRES FOLLOW-UP
Root Cause: [description — e.g. memory leak introduced in deploy abc123]
This mitigation: [action] — provides temporary relief, will recur
Required follow-up: [specific action to address root cause]
Next: /ai-sre:sre-postmortem to capture root cause and assign remediation
```

---

## Phase 6: Timeline / Postmortem Output

**Goal:** Produce the incident timeline and handoff artifact.

```
## Incident Timeline (UTC)

[HH:MM]  Incident reported — [symptom summary]
[HH:MM]  Triage started — /ai-sre:sre-incident v3.0.0
[HH:MM]  Evidence collection complete — [N signals, coverage: FULL|PARTIAL|LIMITED]
[HH:MM]  Hypotheses ranked — top: [H1 description]
[HH:MM]  [H#] eliminated — [reason / which VERIFIED_NEGATIVE signals]
[HH:MM]  Root cause confirmed — [description]   (or: unconfirmed — [top candidate])
[HH:MM]  Mitigation authorized — [action]
[HH:MM]  Mitigation applied — (update if known)
[HH:MM]  Incident resolved — (update if known)
```

Output the **final scorecard snapshot** (full canonical format, current state).

```
## Open Questions
- [Hypotheses not fully resolved — what would confirm or eliminate them]
- [UNRESOLVABLE tracks that should be investigated once access is available]
- [Recurrence risk — does root cause require a runbook or code fix?]
```

```
## Handoff
Incident: [one-line description]
Current state: [mitigated | resolved | ongoing | escalated]
Owner: [escalation owner from KB, or product on-call]
Scorecard: [copy final scorecard above]
Next: /ai-sre:sre-postmortem
```
