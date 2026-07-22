# Trigent Change Management Process

> **Status**: Scaffold with known facts. Sections marked **TODO** require verification/completion
> by the DevOps team. Confluence docs exist but are partially outdated; do NOT reference them as
> authoritative until the relevant TODO is resolved.

---

## Overview

Trigent uses an **automated change-management gate** (Komodo Monitor) to enforce approval for
significant changes to production services. The gate sits in front of production deployments and
requires either:

- A project to be **pre-approved** (ongoing, criteria-based exemption), or
- An **urgent bypass** (self-service for critical fixes, no prior approval), or
- A **major change approval** (Jira ticket, reviewed by change approvers)

DevOps **enforces** the gate (manages Komodo Monitor, investigates bugs, unblocks pipelines) but
has **no authority** to approve or deny change requests. Approval authority lies with the designated
change approvers.

---

## Change types

### Standard changes (pre-approved projects)

Projects that meet the pre-approval criteria (> 75% code coverage, prior approved major change,
successful pipeline history) can apply for pre-approval. Once approved, their pipelines bypass the
gate automatically with no ticket required per deployment.

To apply: submit a **Pre-Approval Eligibility Request** via the Jira service desk.
→ Portal: https://trigent1.atlassian.net/servicedesk/customer/portal/3
→ Request type 473 ("Pre-Approval Eligibility Request")

Komodo will automatically evaluate the project against the criteria and respond via a Jira comment.

### Major changes (Jira ticket approval)

Any deployment from a non-pre-approved project that Komodo's AI classifies as a major change will
trigger an automatic Jira change-request ticket in the **CM** project. The pipeline is held
"Pending Approval" until the ticket is approved (or denied / times out).

**Who approves?**

| Change type | Approver group | Members |
|-------------|---------------|---------|
| **Major changes** | Jira group `AA-PushtoProductionChanges` | Andy Kay, Chris Noell, Fola Komolafe, Pavel Trakhtman |
| **Urgent/emergency changes** | Jira group `Incident Commanders` | Chris Noell, Fola Komolafe, Pavel Trakhtman |

<!-- TODO: Confirm expected approval response SLAs for each change type. -->
> ⚠️ TODO: Document expected approval SLAs.

**What triggers automatic Jira ticket creation?**
- The pipeline is on a monitored project + protected branch + production-environment job
- The commit is classified as a major change by Komodo's AI model
- The project is not pre-approved and no urgent bypass is active

**What to do while waiting:**
- Check the CM project in Jira for your ticket and follow up with the approver.
- If the deployment is genuinely critical, consider the urgent bypass (see below).

### Urgent / emergency changes (self-service bypass)

For critical production fixes that cannot wait for the approval cycle, engineers can bypass the gate
using either:

1. **Pipeline variable**: set `isUrgentChange` = `true` (also accepts `1` or `yes`; key is
   case-insensitive) when triggering the pipeline manually.
2. **Branch name**: use a branch whose name contains `urgent`, `hotfix`, or `emergency` (anywhere
   in the name, case-insensitive — e.g. `hotfix/my-fix`, `my-hotfix`, `EMERGENCY-123`).

The bypass is self-service — no prior approval needed. Outcome: pipeline proceeds immediately,
commit status set to "Approved - Urgent change".

**Guidance on when to use the urgent bypass:**
<!-- TODO: Define the policy for when an urgent bypass is appropriate vs. when the major-change
     approval flow should be followed. Example: "Use urgent bypass only for P1/P2 incidents
     actively causing user impact. For planned hotfixes, follow the standard major-change path." -->
> ⚠️ TODO: Document the policy/guardrails for using the urgent bypass.

**For non-automated (manual) urgent changes** that do not go through GitLab pipelines at all, submit
a manual change request via:
→ https://trigent1.atlassian.net/servicedesk/customer/portal/3

---

## Roles and responsibilities

| Role | Responsibility |
|------|----------------|
| **Engineering teams** | Ensure pipelines are correctly configured; submit pre-approval requests; follow the urgent-bypass policy; interact with Jira for approvals |
| **DevOps** | Operate and maintain Komodo Monitor; investigate pipeline blocks; unblock jobs in case of system bugs; explain genuine pending approvals; cannot approve/deny change requests |
| **Change approvers** | Review and approve/deny CM Jira tickets (change-request tickets). See the "Who approves?" table above for the Jira groups and named members |

---

## Escalation

**If your pipeline is blocked and you believe it is a system bug (not a genuine pending approval):**
→ Report it to DevOps via: https://trigent1.atlassian.net/servicedesk/customer/portal/4/group/9/create/126

**If your pipeline is blocked due to a genuine pending approval and the approval is overdue:**
<!-- TODO: Document the escalation path for slow approvals (e.g. ping the CAB in Slack channel X,
     or contact the delivery manager). -->
> ⚠️ TODO: Document the approval escalation path.

**For general questions about change management:**
<!-- TODO: Add the appropriate Slack channel or contact for process questions. -->
> ⚠️ TODO: Add the primary contact / Slack channel for change-management questions.

---

## Frequently asked questions

**Q: My pipeline has been "Pending Approval" for hours with no CM ticket created — is that a bug?**
A: Yes, likely. After the ~2-minute grace period, a CM ticket should be created automatically if
the change is classified as major. No ticket after several minutes indicates a system issue. Report
it to DevOps using the portal above.

**Q: A CM ticket was approved but my jobs did not retry — what do I do?**
A: This is a system bug. Report it to DevOps. Provide the pipeline URL and the CM ticket key.

**Q: My project should be pre-approved — why is the gate still firing?**
A: Either the pre-approval evaluation failed against current criteria (coverage may have dropped),
or there's a sync issue. Report to DevOps with your project name/ID.

**Q: Can I always use the urgent bypass?**
<!-- TODO: Replace with the actual policy once documented above. -->
A: The urgent bypass is intended for critical situations. See the guidance section above (TODO).

**Q: Who is DevOps and how do I reach them?**
To raise a CI/CD issue with DevOps: https://trigent1.atlassian.net/servicedesk/customer/portal/4/group/9/create/126

<!-- TODO: Add DevOps team members and Slack channel. -->
> ⚠️ TODO: Add DevOps team contact details (members, Slack channel).
