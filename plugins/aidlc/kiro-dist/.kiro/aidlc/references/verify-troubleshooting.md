# AI-DLC Verify — Troubleshooting

Diagnostic reference for `/aidlc-verify`. Relocated verbatim from the skill body
(ENH-011 slimming; no requirement removed — detail moved to a reference and linked).

## Backend Detection Issues
- **Backend not detected**: Ensure Feature artifact has proper metadata (GitLab: frontmatter with `backend: gitlab`, Linear: `linear_initiative_id`, Confluence: page with status table)
- **Wrong backend detected**: Verify Feature metadata matches actual backend used
- **Multiple backends detected**: Choose one as source of truth; migrate artifacts if needed

## GitLab-Specific Issues
- **Git repo not found**: Verify `"$AIDLC_DOCS_PATH"` exists and is up to date (`git pull`)
- **Branch not found**: Check branch naming convention `intent/<project-slug>/<intent-slug>`
- **Frontmatter missing fields**: Ensure `intent.md` has `backend`, `status`, and optional `jira_project_key`
- **Epic/Task files not found**: Verify file structure: `epics/<epic-name>/epic.md` and `epics/<epic-name>/tasks/<task-name>.md`
- **Git push fails**: Check authentication with `glab auth status` or `git config --list`
- **MR update fails**: Verify `glab` CLI is installed and authenticated

## Linear-Specific Issues
- **Initiative not found**: Verify Initiative ID from `/aidlc-intent` output
- **Linear MCP not responding**: Check Linear authentication and API token
- **Status update fails**: Ensure Initiative exists and user has write permissions
- **Projects not created**: Linear Projects may not have been created in `/aidlc-elaborate`; verify with `list_projects`
- **Issues not created**: Check Project ID and ensure parent hierarchy is correct
- **Labels not applied**: Verify label names are valid (no spaces, lowercase preferred)

## Confluence/Jira Issues (legacy)
- **Project not supported**: Some Jira projects may not have Advanced Roadmaps. Skip Project level and use Feature as top-level artifact.
- **Epic issue type not supported**: If Jira project lacks Epic type, use alternative type + issue links or parent field; ask for preferred structure.
- **Grouping issue type not available**: The grouping type is set by `jira.issueTypes.grouping` (default "Story", present in stock Jira). If your project uses a different name (e.g. a custom "Sprint" type), set `jira.issueTypes.grouping` accordingly and confirm it via `getJiraProjectIssueTypesMetadata`. Retrieval is by the `aidlc:sprint` label, not the type, so any valid grouping type works.
- **Leaf can't be parented to the grouping** (e.g. Story + Task are the same Jira hierarchy level): set `jira.leafAttach: "link"` so the leaf is parented to the Epic and joined to its grouping via an issue link (`jira.linkType`, default "Relates"). Only use `leafAttach: "parent"` when the leaf type is a valid native child of the grouping type (e.g. ADO User Story → Task).
- **Task issue type not supported**: If Jira project lacks Task type, use alternative type with parent link or issue links instead.
- **Missing issue types**: Use `getJiraProjectIssueTypesMetadata` and confirm available types.
- **Low confidence score**: Guide user to address specific gaps; offer to re-run verification after updates.
- **Sub-agent failure**: Report which Epic verification failed and offer to retry or assess manually.
- **Confluence page deletion fails**: Verify permissions; may need admin to delete pages.
- **Design missing**: Confidence will be lower; recommend running `/aidlc-design` first but allow override.
- **User wants to skip verification**: Allow with explicit confirmation, but warn that AI execution quality may suffer.
- **Sprint groupings unclear**: Review proposed Sprints in Epics Overview; may need to regroup Tasks before transfer.
- **Tasks span multiple Sprints**: Each Task should belong to exactly one Sprint; resolve before Jira transfer.
- **`acli` not installed for linking**: Document dependencies in Sprint descriptions instead; instruct user to manually create links later.
- **Team field not found in Jira**: Use `acli jira workitem fields PROJ-123` to discover the correct field name for team assignment.
- **Cross-project Tasks**: Jira constraint — Tasks must be in the same project as their parent Sprint. Route at the Sprint level, not Task level.
- **Circular sprint dependencies detected**: Flag as blocking gap. Must restructure into a DAG (directed acyclic graph) before transfer.
- **Too many phases in execution plan**: Consolidate phases where sprints have no actual inter-phase dependencies.
- **Single lane per phase (no parallelism)**: Flag for team to consider splitting sprints or adjusting dependencies to enable parallel work.
- **Story Points field not found**: Cause: Jira project doesn't have Story Points field configured. Resolution: Workflow continues without Story Points. Recommend team enable Story Points field in project settings. Check: Use Jira admin interface → Project Settings → Issue Types → Task → Fields
- **Story Points field is read-only**: Cause: Jira permissions or field configuration. Resolution: Tasks created without Story Points. Recommend manual addition or permission update.
- **Story Points value rejected**: Cause: Jira field validation rules (e.g., only allows 0.5, 1, 2, 3, 5, 8, 13). Resolution: Use default value 5 or skip Story Points for that task. Check: Verify field configuration allows Fibonacci values (1, 2, 3, 5, 8, 13, 21)
- **Epic-creator agent fails entirely**: Cause: Critical error (Epic creation failed). Resolution: Retry agent for that Epic only. Other Epics' artifacts are preserved. Check agent error output for specific failure reason (API timeout, permissions, invalid parent Feature key).
- **Partial Epic success**: Cause: Some Sprints/Tasks created, others failed during agent execution. Resolution: Partial Jira artifacts exist for this Epic. Manual creation needed for failed items. Check `errors` array in agent output to identify failed Sprints/Tasks. Query Jira: `labels = aidlc:epic AND parent = PROJ-100` to see what was created.
- **Agent timeout**: Cause: Large Epic with 50+ Tasks, network latency, or Jira API rate limiting. Resolution: Retry agent with same Feature key. Duplicate detection: Check for existing Epic with `aidlc:epic` label and matching Feature parent before creating. If Epic exists, skip creation and resume at Sprint creation.
- **Sprint dependency linking fails**: Cause: `acli` not installed, network issue, or invalid Sprint keys in sprint map. Resolution: Dependencies already documented in Sprint descriptions by agents ("Blocked by: Sprint 1.1"). Manually create links later using Jira Query: `labels = aidlc:sprint` to find all Sprints, then use UI or `acli jira workitem link` to create links.
