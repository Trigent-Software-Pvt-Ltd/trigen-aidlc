# GitLab CI Core Rules

## Job Ordering

**Use stages for cross-stage ordering and `needs` only for intra-stage ordering.**

| Keyword | Use When |
|---------|----------|
| `needs` | Ordering jobs within the **same stage** |
| `dependencies` | Getting artifacts from **earlier stages** (no ordering effect) |
| No `needs` | Entry-point jobs that should wait for **all** previous stage jobs |

If a job has `needs` pointing to an earlier stage, it bypasses stage gates entirely.
