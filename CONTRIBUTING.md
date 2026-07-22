# Contributing to `claude-plugins`

This document defines the rules for making changes to the `claude-plugins` repository. It is the contract between contributors and maintainers.

## 1. Peer review

Every merge request that lands on `main` must be approved by at least one reviewer who is not the author. Once approved, the author can merge - there is no separate "maintainer clicks Merge" step.

Enforced by GitLab project settings:

| Setting | Value |
|---|---|
| Allow author to merge own MR | Enabled |
| Approvals required | 1 |
| Prevent author from approving own MR | Enabled |
| Prevent committer-only approvals | Enabled |
| Reset approvals on new commits | Enabled |
| Allow merging only if pipeline passes | Enabled |
| Allow merging only if all threads resolved | Enabled |

## 2. Branch protection on `main`

| Setting | Value |
|---|---|
| Push to `main` | Maintainers only |
| Force-push or delete `main` | Disabled for everyone |

## 3. Reviewer assignment

Authors are encouraged to assign a reviewer when opening the merge request. If you don't have a specific reviewer in mind, default to a maintainer. This rule will tighten to a hard requirement once a dedicated reviewers group is in place.

## 4. Review timing

| Stage | Target |
|---|---|
| First reviewer response | Within 1 business day of reviewer assignment |
| Actionable feedback (approval or change requests) | Within 1 business day of the first response |

## 5. Stale merge request policy

A merge request is considered stale if it has been open for more than one week. A maintainer contacts the author first, then either drives the merge request to merge or closes it.

## 6. Merge request template

Every merge request uses the project template at `.gitlab/merge_request_templates/Default.md`:

```markdown
## Plugin(s) touched
<!-- e.g. plugins/aidlc, plugins/issues -->

## Type
- [ ] Bug fix (PATCH)
- [ ] New feature / new skill (MINOR)
- [ ] Breaking change (MAJOR)
- [ ] Docs / chore inside a plugin (PATCH)

## Summary
<!-- 1-3 bullets -->

## Testing done
<!-- list what you ran / how you verified, e.g. `bash tests/validate-plugins.sh`, manual `/plugin` reload -->
-
```

## 7. Versioning

Every merge request that touches a plugin must bump that plugin's version in **both** of:

1. `plugins/<plugin-name>/.claude-plugin/plugin.json` - the `version` field.
2. `.claude-plugin/marketplace.json` - the matching plugin entry's `version` field.

The two values must match. Bumps follow Semantic Versioning:

| Change type | Bump |
|---|---|
| Bug fix, doc / chore inside a plugin | PATCH (e.g. `1.0.0 → 1.0.1`) |
| New feature / new skill | MINOR (e.g. `1.0.1 → 1.1.0`) |
| Breaking change | MAJOR (e.g. `1.1.0 → 2.0.0`) |

**Exemption:** changes that only touch repo-root files (e.g. `CONTRIBUTING.md`, `README.md`, `.gitlab-ci.yml`) are not part of any plugin and do not require a version bump.

Enforced by `tests/check-version-bumped.sh`, which runs in CI on every MR touching `plugins/**` or `.claude-plugin/marketplace.json`. The check fails the pipeline if any changed plugin's `plugin.json` and `marketplace.json` versions weren't bumped together vs. the target branch. Because the pipeline must pass before any merge, this is enforced at the merge gate.
