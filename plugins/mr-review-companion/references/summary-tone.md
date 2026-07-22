# Summary tone, writing for a reader who does not read code

The Summary tab is read by people who decide whether a change is risky, urgent, or important, not how it is implemented. They are not less smart than the reviewer; they are paying attention to different things. The Summary tab respects that by speaking in their language.

## The audience

Imagine three readers:

- **A product manager** who needs to know what changes for users and whether to update the release notes
- **A support lead** who needs to anticipate tickets and brief the team
- **A stakeholder** who is checking that the engineering team is shipping what was agreed

None of them care that you split a constant out of a controller. All of them care if a customer-facing screen now behaves differently.

## Rules

### 1. Name the product area, not the code

- Bad: "Refactor `PermissionService` to extract `TRAY_ACCESS_DESCRIPTIONS`."
- Good: "Tidy up how staff permissions are described internally. No visible change for users."

If you cannot describe the change without using a class, method, scope, or constant name, the line belongs in the Diff tab.

### 2. Lead with the user-visible effect

The lede is two to four sentences. Sentence one names what users will notice. Sentence two names who notices. Sentences three and four (optional) say what motivated the change in stakeholder terms, a bug, a compliance requirement, a stakeholder ask.

- Bad: "This change introduces a new bulk-revoke action on the admin access controller and updates the corresponding view template."
- Good: "Admins can now revoke legacy-tray access for multiple staff at once. Before this change, an admin had to click into each staff member individually. The new action is on the Access admin page."

### 3. Negatives are load-bearing

A surprising amount of stakeholder anxiety comes from imagining changes that are not happening. The "What this change does not do" list is short and direct.

- "Does not change anyone's existing access."
- "Does not migrate any data."
- "Does not affect the signing-in flow."
- "Does not change pricing."

Pick three to five negatives that are realistic worries a non-technical reader would have, given the area of the product touched. If the change is purely internal, the headline negative is "No user-visible change of any kind."

### 4. Pipeline status and approvals are facts, not jargon

KPIs and the review-state pill are useful: pipeline status, number of files changed, additions, deletions, approval state. Coverage too, when GitLab reports it. These are objective and easy to read. Leave them in.

### 5. No identifier in the prose

This is a hard rule for the prose a non-technical reader reads. The Summary tab does not contain class names, method names, file paths, constants, regex patterns, SQL fragments, or migration filenames. If you find yourself reaching for one, ask "what would I say to a PM at a coffee machine?"

The clickable Jira tickets and the MR link are not identifiers in this sense, they are navigational chrome.

**One carve-out: the Rollback block.** When the MR has migrations, the Summary tab carries a Rollback block that is explicitly labelled for developers, not QA (see SKILL.md Step 4 and the Rollback shape in html-template.md). That block may name a concrete revert command such as `rails db:rollback` because its reader is a developer reverting a deploy, not the PM the rest of the tab is written for. Keep the command inside `<code>` and keep the surrounding sentences plain. This is the only place a command is allowed in the Summary tab; the no-identifier rule still governs the lede, the bullet lists, and every other word.

### 6. One screen of reading

The whole Summary tab should fit on one laptop screen without scrolling. If it does not, it is too long. Cut bullets, not paragraphs, the lede earns its keep.

## Banned phrases

These words sound technical and break the tone in Summary-tab prose:

- "refactor", "refactoring"
- "DRY", "single source of truth", "DRY up"
- "implement", "implementation"
- "logic"
- "the codebase"
- "encapsulate", "encapsulation"
- "controller", "model", "service", "module"
- "scope" as a noun for a code construct (a Rails scope, a JS lexical scope). The everyday phrase "scope of the change" is allowed because it refers to extent, not code.
- "endpoint", "API surface"
- "type signature", "interface"
- "as part of this change"

Note on "this MR" / "merge request": the Summary tab uses the phrases "this change does" and "this change does not do" in its bullet headings (see html-template "Summary tab structure"). In prose body text, prefer "this change" too. The string "MR" only appears in the banner KPI strip and the title bar, where it is navigational chrome rather than tone-setting.

If the change is purely a refactor with no user effect, the lede is: "Internal tidy-up. No user-visible change. Pipeline green." That is the whole Summary tab, plus the KPI strip and the Jira links.

## Worked examples

### Example A, feature

> Admins can now revoke legacy-tray access for multiple staff at once. Before this change, an admin had to click into each staff member individually. The new action is on the Access admin page. UKE-1037 tracks the rollout for the autumn term.

**What this change does**
- Adds a "Revoke selected" button on the Access admin page.
- Records each revocation in the audit log with the admin's name.
- Re-uses the existing permission descriptions, so the audit log entries match the rest of the product.

**What this change does not do**
- Does not change anyone's existing access.
- Does not affect staff who already have no tray access.
- Does not change how staff sign in.

### Example B, bug fix

> Fixes the legacy-tray permission check that was silently failing for admins whose role name had a capital S. The check was looking for a permission that did not exist. Affected users could not open the tray for the last two weeks. UKE-1041.

**What this change does**
- Restores tray access for admins whose role name uses the British spelling of "system".
- Adds a regression test so the same typo does not slip back in.

**What this change does not do**
- Does not change who has access; it only fixes the check.
- Does not require an admin to log out and back in.
- Does not affect any other permission.

### Example C, internal refactor

> Internal tidy-up. The legacy permission descriptions used to live in three files; now they live in one. No user-visible change. Pipeline green.

**What this change does**
- Moves the description list to a single file.
- Updates the three call sites to read from there.

**What this change does not do**
- Does not change anyone's permissions.
- Does not change what the descriptions say.
- Does not require a deploy coordination, the change is safe to ship.

## The honest fallback

If you genuinely cannot describe the change in non-technical terms, usually because it is a deep infrastructure change with no user surface, write: "This change is internal infrastructure. The Diff tab has the technical details; there is nothing here that will be visible to a user."

That is a fine outcome. Pretending an infrastructure change has user impact is worse than admitting it does not.
