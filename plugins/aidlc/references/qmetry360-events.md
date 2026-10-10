# QMetry360 event integration (optional)

Emit AI-DLC lifecycle events so delivery can be measured in QMetry360. **Optional** — project policy
decides whether it's required. Default behaviour **records events locally**; a live adapter runs only
when a verified QMetry360 API contract is configured.

> **Hard constraint:** do **not** invent QMetry360 API endpoints, authentication flows, or metric
> formulas. The live path posts to a **configured** URL with a **configured** token only; until a real
> contract is wired, events are recorded locally and no network call is made.

## Events

Emit on these transitions (stable names):
`intent.approved` · `requirements.elaborated` · `design.approved` · `readiness.verified` ·
`story.implementation.started` · `tests.executed` · `review.completed` · `pr.merged` ·
`release.gate.evaluated`.

## Event schema (stable, correlatable)

```json
{
  "schemaVersion": "1",
  "event": "design.approved",
  "ts": "2026-10-10T12:00:00Z",
  "project": "<project key, e.g. QI>",
  "featureId": "<FI-0001>",
  "epicId": "<WSS / QI-136>",
  "storyId": "<QI-137>",
  "artifact": "<page id / PR url / file path, optional>",
  "correlationId": "<stable id linking the chain for one unit of work>",
  "actor": "<user / agent>",
  "risk": "<low|med|high, optional>",
  "data": { "...event-specific, no secrets..." }
}
```

- `project` + `featureId`/`epicId`/`storyId` are the stable keys (reuse the existing backend mappings).
- `correlationId` links an event chain (intent → … → release) for one unit of work.
- **Never** put secrets/PII in `data`.

## Emitting

Use the dependency-light emitter `hooks/qmetry-emit.sh`:

```
bash "${CLAUDE_PLUGIN_ROOT}/hooks/qmetry-emit.sh" \
  --event design.approved --project QI --feature FI-0001 --epic QI-136 --story QI-137 \
  --artifact "https://…/pages/297336833" --correlation WSS-setup --risk med
```

Modes (from config / env `QMETRY_EMIT_MODE`):
- **`off`** — no-op.
- **`local`** (default) — append the event to `.aidlc/qmetry-events.jsonl` (git-ignored). Always safe.
- **`live`** — additionally POST to the **configured** `QMETRY_API_URL` with the token in the env var
  named by `QMETRY_TOKEN_ENV`. Only enable once the API contract is verified; no URL/auth is shipped.

## Where to emit (skill milestones)
`/aidlc-intent` → `intent.approved`; `/aidlc-elaborate` → `requirements.elaborated`; `/aidlc-design` →
`design.approved`; `/aidlc-verify` → `readiness.verified`; `/aidlc-sprint` → `story.implementation.started`,
`tests.executed`; `/aidlc-review` → `review.completed`; PR merge → `pr.merged`; release gate →
`release.gate.evaluated`. Emit **after** the human gate, not before.
