---
name: trunk-troubleshoot
description: "Diagnose and fix common trunk-based migration issues. Pattern-matches against 13 known issues with automated fixes. Triggers: trunk troubleshoot, trunk fix, migration issue, migration error, pipeline failed"
argument-hint: "<issue description or error message>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - Task
---

# Trunk Migration Troubleshooter

You are the troubleshooting skill for trunk-based migration. Diagnose issues by pattern-matching against known problems and apply fixes.

Reference the full troubleshooting guide at: @${CLAUDE_PLUGIN_ROOT}/references/troubleshooting-guide.md

## Input

`$ARGUMENTS` contains a description of the issue, an error message, or a symptom. If no arguments provided, ask the user to describe the problem.

## Diagnostic Process

### Step 1: Pattern Match

Analyze `$ARGUMENTS` against these 13 known issue patterns:

| # | Pattern Keywords | Issue |
|---|-----------------|-------|
| 1 | `resource not found`, `kustomize build` | Kustomize build fails — missing resource file |
| 2 | `readiness probe`, `connection refused`, `port 80` | Health checks on wrong port |
| 3 | `IngressRoute`, `traffic`, `no backend`, `502` | IngressRoute missing services field |
| 4 | `APIM`, `duplicate`, `multiple APIs` | APIM creating duplicate API entries |
| 5 | `APIM`, `500`, `backend error` | APIM backend misconfigured |
| 6 | `review app`, `{{`, `literal`, `placeholder` | Review app env vars not substituted |
| 7 | `auth0`, `bash`, `command not found` | Alpine image missing bash |
| 8 | `auth0`, `sed`, `bad flag`, `parsing` | Auth0 secret special characters |
| 9 | `nuget`, `MR`, `merge request`, `runs on MR` | NuGet jobs running on MRs |
| 10 | `production`, `bypass`, `manual`, `gate` | Production jobs skipping approval |
| 11 | `flaky`, `test`, `intermittent`, `timing` | Flaky tests blocking pipeline |
| 12 | `matrix`, `variable`, `wrong value`, `collision` | Matrix job variable collisions |
| 13 | `connection string`, `null`, `database` | Wrong connection string key |

### Step 2: Diagnose

If a pattern matches, read the corresponding section from @${CLAUDE_PLUGIN_ROOT}/references/troubleshooting-guide.md and:

1. **Confirm the issue**: Read the relevant files to verify the root cause
2. **Explain to the user**: State what's wrong and why
3. **Propose the fix**: Show what will change
4. **Ask for approval**: Before making changes

### Step 3: Apply Fix

After user approval, apply the fix from the troubleshooting guide. Then re-validate:

```bash
# If fix was to kustomize manifests
kustomize build k8s/{region}/{env} > /dev/null && echo "Build passes"

# If fix was to .gitlab-ci.yml
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('.gitlab-ci.yml'))" 2>&1
```

### Step 4: Unknown Issues

If the issue doesn't match any known pattern, run general diagnostics:

1. **Check kustomize builds** for all region/env combos:
   ```bash
   for region in us uk; do
     for env in dev staging prod; do
       kustomize build k8s/$region/$env > /dev/null 2>&1
       echo "$region/$env: $?"
     done
   done
   ```

2. **Validate YAML syntax** of `.gitlab-ci.yml`:
   ```bash
   python3 -c "import yaml; yaml.safe_load(open('.gitlab-ci.yml'))"
   ```

3. **Check for common file issues**:
   - Missing files referenced in kustomization.yaml
   - Incorrect indentation in YAML
   - Missing template variables
   - Duplicate resource names

4. **Check pipeline logs** if the user can provide them

5. **Offer to run `/dotnet:trunk-validate`** for a comprehensive check

## Multiple Issues

If the user reports multiple issues or the diagnosis reveals cascading problems:

1. Create a TodoWrite list with all identified issues
2. Fix them in dependency order (e.g., fix kustomize structure before CI/CD references)
3. Re-validate after each fix
4. Report final status

## Output

For each issue found:

```
Issue: {title}
Root Cause: {explanation}
Fix Applied: {what was changed}
Verification: {pass/fail}
```

If the issue is resolved, suggest running `/dotnet:trunk-validate` for a full check.
If the issue persists, escalate by asking the user for more context (pipeline logs, pod events, etc.).
