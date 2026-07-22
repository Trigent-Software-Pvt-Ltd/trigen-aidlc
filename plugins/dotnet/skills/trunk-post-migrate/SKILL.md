---
name: trunk-post-migrate
description: "Post-migration tasks after MR is merged. Monitor deployments, cleanup branches, security hardening, and documentation. Triggers: trunk post-migrate, post migration, cleanup migration, after merge, post merge"
argument-hint: "<config.yaml path>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - Task
  - TodoWrite
---

# Trunk Post-Migration Tasks

You are the post-migration skill. Run this after the trunk-based migration MR has been merged to main. You guide the user through monitoring, cleanup, security hardening, and documentation.

Reference config schema at: @${CLAUDE_PLUGIN_ROOT}/references/config-schema.md

## Input

`$ARGUMENTS` may contain a path to `trunk-migration-config.yaml`. If not provided, check for it in the repository root.

## Task Categories

Create a TodoWrite list with all applicable tasks. Work through them interactively with the user.

---

## Phase 1: Monitor First Main Branch Pipeline

Ask the user to provide the pipeline URL or check it together.

### Semantic Release
- [ ] Version calculated correctly (e.g., v1.0.0 or v1.1.0)
- [ ] Git tag created in the repository
- [ ] CHANGELOG updated (if configured)

### NuGet Publishing (if applicable)
- [ ] Packages built with version tag
- [ ] Packages published to GitLab Package Registry
- [ ] Package metadata correct

### Deployments
- [ ] Dev deployments succeed (all regions)
- [ ] Staging deployments succeed (all regions)
- [ ] Migrations applied successfully (if applicable)
- [ ] Auth0 configs updated (if applicable)
- [ ] APIM APIs updated (not duplicated — check Azure Portal)

If any deployment fails, suggest running `/dotnet:trunk-troubleshoot` with the error.

---

## Phase 2: Monitor First Production Deployment

### Manual Approval Workflow
- [ ] Manual approval job appears in prod-gate stage
- [ ] UI regression tests run (if configured)
- [ ] Tests pass before approval is available
- [ ] Approval notification sent to appropriate team

### After Approval
- [ ] Docker images pushed to prod ACR (all regions)
- [ ] Migrations deployed to prod databases (all regions, if applicable)
- [ ] Auth0 configs deployed to prod (all regions, if applicable)
- [ ] K8s deployments succeed (all regions)
- [ ] APIM APIs updated in prod (all regions, all versions)
- [ ] No downtime during deployment
- [ ] Health checks pass after deployment

### Verification
- [ ] Test production endpoints
- [ ] Check New Relic for correct app names (verify naming convention)
- [ ] Verify APIM shows correct API versions in Azure Portal
- [ ] Check database for applied migrations (if applicable)

---

## Phase 3: Cleanup

### Delete Old Branches

Ask the user before deleting:

```
The migration is complete. The following branches are no longer needed
with trunk-based development:

- develop
- staging

Would you like me to delete these branches locally and remotely?
```

If approved:
```bash
git branch -d develop 2>/dev/null
git push origin --delete develop 2>/dev/null

git branch -d staging 2>/dev/null
git push origin --delete staging 2>/dev/null
```

### Remove Test Migrations (if created during migration)

Check if a test migration was created:
```bash
find src/ \( -name "*TestPipeline*" -o -name "*TestMigration*" \) -type f 2>/dev/null
```

If found:
```bash
# Delete migration files
rm src/*/Migrations/*TestPipeline*

# Regenerate migration.sql
dotnet tool restore
dotnet ef migrations script --idempotent \
  --output {data_project_path}/migration.sql \
  --project {data_project_path} \
  --startup-project {project_path}

# Commit
git add .
git commit -m "chore: remove test migration"
git push
```

### Verify Old Files Removed

Check that these are gone from the repository:
- [ ] `.gitlab-ci/` directory deleted
- [ ] Old `k8s/dev/`, `k8s/stag/`, `k8s/prod/` directories deleted
- [ ] `package.json` removed (if it existed)
- [ ] `package-lock.json` removed (if it existed)
- [ ] `release.config.js` removed (if it existed)

---

## Phase 4: Security Hardening

### Read-Only Filesystem

Test read-only root filesystem in dev environment:

```yaml
# Proposed addition to k8s/base/deployment.yaml
spec:
  template:
    spec:
      containers:
        - name: SERVICE_NAME
          securityContext:
            readOnlyRootFilesystem: true
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
```

Ask the user:
```
Would you like to test read-only filesystem in the dev environment?

This adds:
- readOnlyRootFilesystem: true to the container security context
- A writable /tmp volume for temporary files

If the application writes to disk (Data Protection keys, temp files, etc.),
we may need additional volume mounts.

Shall I create a branch to test this?
```

If approved, create a branch, apply the change, push, and monitor the dev deployment.

### Review App Security Audit

Verify review app configuration:
- [ ] Pods running on spot instance node pool (`reviewspotnp`)
- [ ] Auto-cleanup working (1 week after MR closed)
- [ ] Resource limits enforced (300Mi/200m max)
- [ ] No privilege escalation possible
- [ ] HPA max is 1 replica

```bash
# Check for orphaned review app namespaces
kubectl get namespaces | grep "APP_NAME-mr-"
```

---

## Phase 5: Quality Improvements

### Refactor Flaky Tests

Search for skipped tests:

```bash
grep -rn "Skip = " test/ --include="*.cs"
```

For each skipped test, explain the recommended fix pattern:

**Replace fixed sleep with polling:**
```csharp
// BEFORE
await Task.Delay(10000);

// AFTER
var timeout = TimeSpan.FromSeconds(30);
var pollInterval = TimeSpan.FromSeconds(1);
var startTime = DateTime.UtcNow;

while (DateTime.UtcNow - startTime < timeout)
{
    var status = await GetOperationStatus();
    if (status == OperationStatus.Completed)
        break;
    await Task.Delay(pollInterval);
}
```

Ask the user if they'd like to refactor any of the skipped tests now.

### Pipeline Optimization Suggestions

Review the pipeline and suggest optimizations:
- [ ] NuGet package caching
- [ ] Docker layer caching
- [ ] Dotnet build output caching
- [ ] Identify jobs that could run in parallel
- [ ] Check for unnecessary sequential dependencies
- [ ] Optimize matrix job execution

---

## Phase 6: Documentation Updates

Ask the user if they'd like to update documentation:

### README.md
- Update with trunk-based workflow description
- Remove references to develop/staging branches
- Add review app usage instructions
- Document semantic versioning

### Developer Guide Topics
- How to create new EF migrations
- How to test locally with the new structure
- How to use review apps for MR testing
- How to handle flaky tests

### Runbook Topics
- Pre-deployment checklist
- Manual approval process
- Rollback procedures
- Incident response for failed deployments

If the user approves documentation updates, help create or update the relevant files.

---

## Output

Present a final summary:

```
Post-Migration Status
=====================

Phase 1 - Main Pipeline:    ✓ Complete
Phase 2 - Production Deploy: ✓ Complete
Phase 3 - Cleanup:           ✓ Complete
Phase 4 - Security:          ⏳ Read-only filesystem pending
Phase 5 - Quality:           ⏳ 3 flaky tests to refactor
Phase 6 - Documentation:     ⏳ README update pending

Migration is operational. Remaining items are improvements
that can be done incrementally.
```
