# GitLab MR Template — .NET Version Upgrade

Use this template when creating a Merge Request for a .NET version upgrade.

---

```markdown
## .NET Version Upgrade — `{target-framework}`

### Summary

Upgrades `{repo-name}` from `{current-framework}` to `{target-framework}`.

| | |
|---|---|
| **Current Framework** | `{current-framework}` |
| **Target Framework** | `{target-framework}` |
| **SDK Version** | `{sdk-version}` |
| **Risk Level** | 🟢 Low / 🟡 Medium / 🔴 High |

---

### Changes

#### TFM Updates
<!-- List each file where TargetFramework was changed -->
- `{project-file}`: `{old-tfm}` → `{target-framework}`
- `global.json`: SDK `{old-sdk}` → `{new-sdk}`

#### Package Changes
<!-- List packages that were updated, if any -->
- `{package}`: `{old-version}` → `{new-version}`

#### GitLab CI / Docker
<!-- List any CI or Dockerfile image tag updates -->
- `.gitlab-ci.yml`: SDK image `{old}` → `{new}`
- `Dockerfile`: base image `{old}` → `{new}`

---

### What Was NOT Changed (Manual Follow-Up Required)

<!-- List items intentionally excluded from this MR -->
- [ ] HIGH-risk package upgrades (see below)
- [ ] Central Package Management migration
- [ ] Directory.Build.props centralisation
- [ ] .slnx migration
- [ ] OpenAPI tooling (Swashbuckle → Scalar evaluation)
- [ ] Azure Functions execution model migration (if applicable)

---

### High-Risk Packages — Manual Review Required

<!-- Packages flagged by analyze-packages.py -->

| Package | Current Version | Recommended | Risk | Action |
|---------|----------------|-------------|------|--------|
| `{package}` | `{version}` | `{recommended}` | HIGH | Review before upgrading in follow-up MR |

---

### Build & Test Results

```
dotnet restore:   ✅ / ❌
dotnet build:     ✅ / ❌
dotnet test:      ✅ / ❌ ({pass}/{total})
```

---

### Breaking Changes Identified

<!-- Document any breaking changes encountered -->
- None / {description}

---

### Follow-Up Work

<!-- Create separate issues for these -->
- [ ] {issue}: Upgrade `{risky-package}` to `{target-version}`
- [ ] {issue}: Evaluate Scalar for OpenAPI UI
- [ ] {issue}: Migrate Azure Functions to isolated worker model

---

### Reviewer Checklist

**Required before merge:**
- [ ] All projects build successfully
- [ ] All tests pass (unit, integration, functional)
- [ ] GitLab CI pipeline green
- [ ] HIGH-risk packages confirmed not automatically upgraded
- [ ] No auth/security behaviour changes
- [ ] Dockerfile base images updated and verified
- [ ] No unrelated changes included

**If Azure Functions present:**
- [ ] Execution model confirmed (in-process or isolated)
- [ ] In-process → isolated migration NOT included (separate MR required)

**If OpenAPI/Swagger present:**
- [ ] Swashbuckle version compatible with target framework
- [ ] No automatic Scalar replacement included

---

/label ~dotnet-upgrade ~{target-framework}
/assign @{upgrade-engineer}
/reviewer @{tech-lead}
```
