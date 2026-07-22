# QA coverage discovery, mapping changed files to their tests

This reference defines the algorithm for the QA tab. It is the only tab whose quality depends on having a local clone of the MR's project. When the cwd does not match, the algorithm runs Pass 0 only and the remaining files fall back to the "unknown, local repo not available" state described at the bottom. This is the canonical home for that degraded-mode behaviour; SKILL.md and html-template.md reference back here.

## Why this exists

The point of the QA tab is to let a QA engineer skip what the automated suite already covers. That value only materialises if the verdicts are honest: calling something "automated" when no test references the changed symbol is worse than calling it "unknown". Better a "partly automated" verdict the QA engineer can investigate than an "automated" verdict that hides a gap.

## Partitioning the changed files

For each file in the MR diff, decide whether it is `production` or `non-production`. Only `production` files appear in the coverage table. `non-production` files appear in the Diff tab's "Tests" or "Config / migrations / docs" groups but are not verdicted.

### Identifying a test file

A file is a test file (and therefore `non-production`) when its path matches any of these patterns:

- Ends with `_spec.rb` or sits anywhere under a `spec/` directory
- Ends with `_test.rb`, `_test.go`, `_test.py`, or `Test.php`, or starts with `test_` (Python)
- Ends with `.test.ts`, `.test.tsx`, `.test.js`, `.test.jsx`, `.spec.ts`, `.spec.tsx`, `.spec.js`, `.spec.jsx`, or `.spec.vue`
- Ends with `Tests.cs` or sits in a directory whose name ends with `.Tests`
- Sits anywhere under `tests/`, `test/`, or `__tests__/`
- Ends with `.bats` (Bash) or `.feature` (Cucumber)

The production-to-test mapping table further down is for the reverse lookup (given a production file, find its tests). The list above is the only thing you need to classify a file as a test on sight.

### Other `non-production` files

Treat as `non-production`:

- Migrations: `db/migrate/`, `Migrations/`, `migrations/`, `*.sql` under a `schema/` or `migrations/` folder
- Config (data, not runtime code): `config/initializers/`, `config/locales/`, `config/cable.yml`, `config/database.yml`, `config/storage.yml`, `config/secrets.yml`, `config/credentials*`, `config/master.key`, any other `config/*.yml`, `appsettings*.json`, `.editorconfig`, `.gitignore`, `Dockerfile`, `docker-compose*.yml`
- Lockfiles: `Gemfile.lock`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `composer.lock`, `*.csproj.lock`, `Cargo.lock`
- Docs: `*.md`, `*.rst`, `docs/`, `README*`, `CHANGELOG*`
- CI: `.gitlab-ci.yml`, `.github/workflows/*`, `azure-pipelines*.yml`
- Generated: anything under `gen/`, `dist/`, `build/`, `node_modules/`, `vendor/` (these should rarely be in a real MR diff)

Treat as `production` even though they sit under `config/`:

- `config/application.rb`, `config/environment.rb`, `config/boot.rb`, `config/routes.rb`, `config/puma.rb`
- `config/environments/*.rb`
- Any other `config/*.rb` that is not under `config/initializers/`. These files hold executable Rails configuration and a change in them is a runtime behaviour change, not a settings tweak. They are exactly the kind of file an MR will pair with a regression spec.

Everything else is `production`.

## Test-path conventions by language

The skill uses the changed file's path and extension to decide which conventions to apply. A repo can use more than one; try every applicable convention before declaring "no test found".

| Language / framework | Heuristics |
|----------------------|-----------|
| Ruby on Rails (`*.rb` under `app/`, `lib/`) | Mirror path under `spec/` with `_spec.rb` suffix (for example `app/models/foo.rb` -> `spec/models/foo_spec.rb`). Also check `test/` with `_test.rb` suffix for projects on Minitest. |
| .NET (`*.cs` under `src/`) | Sibling `*Tests.cs` in a parallel test project. Common layouts: `<Project>.Tests/`, `tests/<Project>.Tests/`, `test/`. |
| JavaScript / TypeScript (`*.ts`, `*.tsx`, `*.js`, `*.jsx`) | `*.test.ts` or `*.spec.ts` adjacent to the file; `__tests__/` directories alongside the file; mirrored paths under `test/`, `tests/`, or `__tests__/` at the project root. |
| Vue (`*.vue`) | `*.spec.ts` or `*.test.ts` adjacent; or under `tests/unit/` with a mirrored path. |
| Python (`*.py`) | `tests/` mirrored path with `test_` prefix (for example `pkg/foo.py` -> `tests/test_foo.py`); also `*_test.py` adjacent for projects on the Go-style layout. |
| Go (`*.go`) | Sibling `*_test.go` file in the same package directory. |
| PHP (`*.php`) | Sibling `*Test.php` in `tests/` mirroring the source path. |
| Rust (`*.rs`) | Inline `#[cfg(test)] mod tests` in the same file; sibling `tests/*.rs` files for integration tests. |
| Shell (`*.sh`) | Adjacent `*.bats` or sibling test in `tests/`. |

For files that do not match any convention (for example a YAML pipeline, a SQL stored procedure, an HTML template), record the verdict as "not automated" with the note "no convention for test discovery". These are usually genuinely manual-QA territory anyway.

## Coverage check, three passes, in order

For each `production` file, run these passes in order and stop at the first positive (covered) verdict. SKILL.md Step 6 names these passes by what they do - Same-MR diff check (Pass 0), Path-mirror lookup (Pass 1), Symbol grep (Pass 2); the numbered and descriptive labels refer to the same three passes.

### Pass 0 - Same-MR diff check (do this even without a local repo)

Before consulting any local-repo path, scan the MR's own diff for test files that reference the changed identifiers. A spec file added or modified in the same MR is *evidence the change was tested by the author*, and that evidence is in the diff payload you already fetched, not on disk.

For each `non-production` test file in the diff:

- Extract the identifiers added in this file using the `+` lines (function names, scope names, fixture names, string assertions, the production filename without extension).
- Check whether the same identifiers also appear in the `production` file's diff or its filename.
- If yes, this test file covers the production file in question.

This pass is the only one that runs when `local_repo_available = false`. It is also the most authoritative when it does fire because the author actually wrote a test for the change in the same commit. An "automated" verdict here does not require a local repo.

### Pass 1 - Path-mirror lookup (requires local repo)

Construct the candidate test paths from the conventions table for this file's language. For each candidate path, use Bash `test -f <path>` (or Glob) to check existence. Record all matches.

### Pass 2 - Symbol grep (requires local repo)

Extract the changed symbols from the diff itself:

- For Ruby: lines starting with `def `, `class `, `module `, or a new constant assignment in ALL_CAPS
- For .NET: lines starting with `public`, `private`, `protected`, `internal` followed by a method or class name; new properties
- For TS / JS: lines starting with `function `, `export function`, `export const`, `class `; new exported names
- For Python: lines starting with `def `, `class `; new module-level names
- Other languages: best-effort by reading the `+` lines in the unified diff and pulling identifiers

If extraction surfaces no useful identifiers (the diff is purely inside method bodies), use the filename (without extension) plus the parent class or module name as a coarse grep target.

For each extracted identifier, grep the candidate test files (and the wider test directory) for the identifier as a whole word. Record which test files reference the changed identifiers.

## Verdict rules

For each `production` file, apply the first rule that matches:

| Condition | Verdict | Pill |
|-----------|---------|------|
| Pass 0 fires: a test file in the same MR references the changed identifiers | Automated | `green` |
| Pass 1 mirror test exists AND references at least one changed identifier | Automated | `green` |
| Pass 1 mirror test exists but does not reference the changed identifiers (test exists for a different reason) | Partly automated | `amber` |
| Pass 2 symbol grep finds the changed identifier in some test file even without a mirror test | Partly automated | `amber` |
| No same-MR test, no mirror test, no symbol grep match | Not automated | `red` |
| Pass 0 returned nothing AND local repo not available | Unknown | `grey` |

The "partly automated" band is wide on purpose. The point is to surface uncertainty so the QA engineer investigates, not to be precise.

An "automated" verdict from Pass 0 is the strongest signal. It does not require the local repo and it does not need Pass 1 or Pass 2 to confirm. An MR author who adds a test file in the same commit has told you what they tested.

## "What QA still needs to verify", per-row guidance

Each row of the coverage table has a "What QA still needs to verify" column. Fill it in based on the verdict:

- **Automated:** Leave the cell **blank**. Do not explain that the spec covers it; an empty cell signals "nothing to do here" to a QA engineer scanning the table. Never write spec names, file paths, or unit-test identifiers in this cell.
- **Partly automated:** Describe only the gap - the user-visible behaviour the automated tests do not exercise. Start with a verb: "Verify ...", "Confirm ...", "Check ...". Name what the user would click and what they should see. Do not name the spec file or method.
- **Not automated:** Describe the full user action to test. Start with a verb: "Smoke-test ...", "Verify ...", "Confirm ...". Name the feature area and the specific outcome. Example: "Open the admin area and use the bulk-revoke action. Confirm only the selected records change." Never say "test the controller" or name any code identifier.
- **Unknown:** "Verify this area manually - automated coverage could not be determined."

## QA checklist summary and Manual QA focus list

Render two checklist sections below the coverage table, both using HTML checkboxes (not plain bullets - see html-template.md for the `.checklist` component):

1. **What you need to check** - one checkbox per non-blank "What QA still needs to verify" entry from the coverage table. This is a direct extraction: same text, same order.
2. **Manual QA focus** - the deduplicated, thematic version. Merge similar items (for example two rows about the same admin action become one checkbox). Omit rows whose verdict is Automated. Unknown rows get a single checkbox: "Verify [plain-language area] manually."

Both sections use `<ul class="checklist">`. The first is the raw list, the second is the curated summary a QA engineer uses when planning their session.

## Risk block

After the two checklist sections, render one sentence:

- **What could regress:** the most likely regression, named in user-visible terms. Lean on the diff content for this; do not invent risks.

Do not include a rollback statement in the QA tab. When the MR contains migration files, the rollback plan belongs in the Summary tab for developers to read (see SKILL.md Step 4).

## Short-circuit: local repo not available

This is the canonical home for the degraded-mode behaviour. SKILL.md Step 2 and Step 6 both link back here.

If the cwd does not match the MR's project (Step 2 of SKILL.md), do NOT skip the same-MR diff check. That check reads the MR diff payload, not the local filesystem, and is the most authoritative signal available. Run it for every production file first. Only fall through to "unknown" for files it does not cover.

The QA tab in this mode looks like:

- An anchor note at the top (use the exact wording from the html-template QA tab structure): "Running without the local codebase. Only test files added or changed in this MR were checked. Items already covered by those tests are marked automated; everything else is marked unknown and needs manual verification."
- The coverage table with verdicts from the same-MR diff check: "automated" (green pill) for files a test in this MR covers, "unknown" (grey pill) for the rest. The "What changed (in plain terms)" column describes the user-visible area, not the file path. The "What QA still needs to verify" cell for unknown rows says "Verify this area manually - automated coverage could not be determined." For automated rows the cell is blank.
- Both checklist sections still render: extract from the table as described above.
- The risk block, still filled in from the diff. It does not require a local repo.
