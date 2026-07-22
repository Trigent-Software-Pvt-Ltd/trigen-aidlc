# Sentry CLI Integration

## What this gives the skill

The Sentry MCP can read issues but cannot mute/archive them or formally link them to Jira tickets. With `sentry-cli` plus a small amount of Sentry REST API, the triage skill can automate two manual steps:

1. **Archive (mute) an issue** — unconditional or with a reopen trigger (event count, user count, time window, duration, deadline).
2. **Link an existing Jira ticket to the Sentry issue** — creates the formal "Linked Issues" sidebar entry on the Sentry side.

## Placeholders

Recipes in this file use these placeholders. The skill substitutes them from the YAML contract:

| Placeholder | Source | Example |
|---|---|---|
| `{project}` | YAML `project` (Sentry project slug) | `cpoms` |
| `{sentry_org_slug}` | YAML `sentry_org_slug` | `cpoms` |
| `{sentry_numeric_id}` | YAML `sentry_numeric_id` | `6602946670` |
| `{ticket_key}` | Jira ticket key (existing or newly created) | `AI-1452` |
| `{status_details_body}` | JSON object built from the user's archive-trigger choice | `{"ignoreCount":10}` |

## Prerequisites

### Sentry CLI installed

```bash
command -v sentry-cli >/dev/null 2>&1
```

If absent, install via [Sentry's installation docs](https://docs.sentry.io/cli/installation/). `brew install sentry-cli` is the simplest on macOS.

### Auth file present

`sentry-cli` reads `~/.sentryclirc`. A minimal working config:

```ini
[defaults]
url = https://sentry.io
org = <org-slug>

[auth]
token = sntryu_...
```

Set the file's permissions to `0600` after creating it (`chmod 600 ~/.sentryclirc`).

### Token scope

| Token prefix | Common scopes | What works |
|---|---|---|
| `sntryu_` (User Auth Token) | `org:read`, `project:read`, `event:read/write`, `alerts:*`, `team:*` | All recipes here |
| `sntrys_` (Internal Integration / CI) | `org:ci` | Releases and source maps only; archive and link calls return **403** |

If `sentry-cli info` shows only `org:ci`, the user needs to create a personal token at `https://<org>.sentry.io/settings/account/api/auth-tokens/` with `org:read`, `project:read`, `event:read`. The skill should fall back to manual instructions in that case.

## Availability check

The skill sets `sentry_cli_mode` based on this probe:

```bash
if command -v sentry-cli >/dev/null 2>&1 && sentry-cli info >/dev/null 2>&1; then
  echo available
else
  echo unavailable
fi
```

- `available` — proceed with CLI/curl recipes below
- `unavailable` — fall back to "open Sentry, click Archive / Link Issue manually" instructions

## Reading the token safely

All curl recipes share the same token-extraction pattern. Use the same guarded form everywhere so the skill never sends an empty `Authorization: Bearer` header:

```bash
TOKEN=$(grep '^token' ~/.sentryclirc 2>/dev/null | sed 's/.*= //')
if [ -z "$TOKEN" ]; then
  echo "no token in ~/.sentryclirc — falling back to manual"
  exit 0
fi
```

`grep` swallows its own stderr (file missing) and returns an empty `TOKEN`; the guard converts that into a clean exit so the skill can show the manual fallback rather than a confusing 401.

## Inspecting HTTP responses

`curl -s` silences progress but does not capture HTTP status. Use `-w '\n%{http_code}'` and split the body from the status line:

```bash
RESP=$(curl -s -w '\n%{http_code}' -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '<payload>' \
  '<url>')

STATUS=$(echo "$RESP" | tail -n1)
BODY=$(echo "$RESP" | sed '$d')

case "$STATUS" in
  200|201|202) echo "ok: $BODY" ;;
  401)         echo "auth invalid — refresh ~/.sentryclirc and retry" ;;
  403)         echo "scope too narrow — fall back to manual" ;;
  404)         echo "not found — re-verify IDs" ;;
  *)           echo "unexpected status $STATUS: $BODY" ;;
esac
```

The same status-handling pattern applies to both archive and link calls below; use it whenever the recipe says "Run via curl".

## Archive recipes

### Unconditional archive (CLI)

```bash
if sentry-cli issues mute -p {project} --id {sentry_numeric_id}; then
  echo "archived"
else
  echo "mute failed (exit $?) — fall back to manual"
fi
```

A successful mute returns `Updated matching issues. new status: muted`. Equivalent to "Archive forever" in the UI. The `if`-guard catches transient failures (network, auth expired between the availability probe and the mute call) so the skill can fall back rather than report a false success.

### Conditional archive (REST API)

`sentry-cli mute` has no flags for reopen triggers. Use the REST API with `statusDetails`. Apply the token guard from "Reading the token safely" and the response-handling pattern from "Inspecting HTTP responses":

```bash
RESP=$(curl -s -w '\n%{http_code}' -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"status\":\"ignored\",\"statusDetails\":{status_details_body}}" \
  "https://sentry.io/api/0/organizations/{sentry_org_slug}/issues/?id={sentry_numeric_id}")
```

A successful PUT returns HTTP 200 with a body shaped like:

```json
{
  "status": "ignored",
  "statusDetails": {
    "ignoreCount": 10,
    "ignoreUntil": null,
    "ignoreUserCount": null,
    "ignoreUserWindow": null,
    "ignoreWindow": null,
    "actor": { "username": "..." }
  }
}
```

### `statusDetails` options

| Field | Type | Effect |
|---|---|---|
| `ignoreCount` | int | Reopen after N additional events |
| `ignoreUserCount` | int | Reopen after N additional affected users |
| `ignoreWindow` | int (minutes) | Time window applied to `ignoreCount` |
| `ignoreUserWindow` | int (minutes) | Time window applied to `ignoreUserCount` |
| `ignoreDuration` | int (minutes) | Auto-reopen after N minutes |
| `ignoreUntil` | ISO timestamp | Auto-reopen at this specific time |

### Common trigger patterns

Match the trigger labels the skill offers in `AskUserQuestion`:

| Trigger label (skill option) | `status_details_body` |
|---|---|
| Forever | Use the **Unconditional archive (CLI)** recipe above when `sentry-cli` is available (preferred). REST fallback only: `{}` in `statusDetails`. |
| Until N more events | `{"ignoreCount":N}` |
| Until N events within H hours | `{"ignoreCount":N,"ignoreWindow":<H*60>}` |
| Until U new users affected | `{"ignoreUserCount":U}` |
| For H hours | `{"ignoreDuration":<H*60>}` |
| Until specific date | `{"ignoreUntil":"<ISO-8601, e.g. 2026-05-15T00:00:00Z>"}` |

## Link Sentry issue ↔ Jira ticket

### Discover the org's Jira integration ID

The integration ID is per-Sentry-org. If both archive and link are needed in the same triage, run discovery once and substitute the resulting `INTEGRATION_ID` into both subsequent calls in the same Bash invocation:

```bash
INTEGRATION_ID=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "https://sentry.io/api/0/organizations/{sentry_org_slug}/integrations/?provider_key=jira" \
  | jq -r '.[0].id')
```

### Link a Jira ticket (existing or newly created)

Apply the token guard and response-handling pattern from above:

```bash
if [ -z "$INTEGRATION_ID" ] || [ "$INTEGRATION_ID" = "null" ]; then
  echo "no Jira integration configured in this Sentry org — skipping link"
else
  RESP=$(curl -s -w '\n%{http_code}' -X PUT \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"externalIssue":"{ticket_key}"}' \
    "https://sentry.io/api/0/groups/{sentry_numeric_id}/integrations/${INTEGRATION_ID}/")
  STATUS=$(echo "$RESP" | tail -n1)
  BODY=$(echo "$RESP" | sed '$d')
  case "$STATUS" in
    200|201) echo "linked: $BODY" ;;
    403)     echo "scope too narrow — fall back to manual link" ;;
    404)     echo "wrong sentry_numeric_id or INTEGRATION_ID — re-verify" ;;
    *)       echo "unexpected status $STATUS: $BODY" ;;
  esac
fi
```

A successful PUT returns HTTP 200 with a body shaped like:

```json
{
  "id": 4351407,
  "key": "AI-1452",
  "url": "https://<jira-domain>/browse/AI-1452",
  "integrationId": 221593,
  "displayName": ""
}
```

The link appears in the Sentry issue page's right sidebar under "Linked Issues".

## Fallback behaviour

`sentry_cli_mode` collapses three distinct failures into one state. The probe at the top of this file is the source of truth — if it returns `unavailable`, the skill should present manual instructions without trying to distinguish which sub-failure fired.

| Detectable condition | Maps to | Skill behaviour |
|---|---|---|
| `command -v sentry-cli` fails | `sentry_cli_mode: unavailable` | Show "open Sentry, use Archive / Link Issue buttons" instructions |
| `~/.sentryclirc` missing or unreadable | `sentry_cli_mode: unavailable` | Same |
| `sentry-cli info` fails (token expired or invalid) | `sentry_cli_mode: unavailable` | Same, plus suggest refreshing the token |
| Token scope is `org:ci` only (CLI works, curl returns 403) | Detected at runtime via the 403 status branch in the recipes above | Fall back to manual for archive-conditional and link; unconditional `sentry-cli mute` still works |
| `jq` not installed | Detected when the discovery pipe fails | Skip integration lookup and ask the user for the ID, or use `grep`/`sed` against the raw JSON |

## After acting

After a successful archive or link:

1. Confirm to the user with the issue's URL and (for archive) the chosen reopen trigger.
2. The Sentry issue page reflects the change immediately (refresh if it's open).
3. For links, the Jira ticket also gets a Sentry mention in its activity feed via Sentry's integration — no separate action needed on the Jira side.

## Sentry-side link outcome summary

Use these strings verbatim in the triage summary table. The step number in the column header varies per action handler (Step 6 for Create Jira, Step 3 for Link Existing Jira), but the outcome strings are fixed.

| HTTP / condition | Summary line |
|---|---|
| 200 / 201 | "linked via Sentry integration (visible under Linked Issues)" |
| Empty `INTEGRATION_ID` | "skipped — this Sentry org has no Jira integration configured" |
| 403 | "skipped — Sentry auth token scope is too narrow; add the link manually" |
| 404 | "skipped — Sentry/Jira ID mismatch; add the link manually" |
| Token guard exited (token missing after CLI was reported available) | "skipped — token not found; add the link manually" |
