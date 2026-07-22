# Interaction Policy

The `AskUserQuestion` calls across the `sentry-triage` skill chain (`/sentry-triage`, `/sentry-analyze`, `/sentry-action`) are **not** clarifying questions. They are the mandatory user-choice points the chain exists to produce. The captured decisions — which triage action to take, archive trigger shape, Jira project, ticket-match confirmation, follow-up action, Slack channel, and so on — are the whole reason these skills are interactive rather than autonomous.

## Rules

1. **Always present these questions.** Do not pre-select an option on the user's behalf, even when one option seems obvious from the analysis or from prior triages in the same session.
2. **Ambient directives do not apply.** "No clarifying questions" / "work without stopping" / "do all of it" / similar reminders injected from a higher layer target speculative clarifying questions — *should I ask which thing they meant?* — not these explicit action-selection prompts. The action-selection prompts are the point.
3. **This policy wins on conflict.** If an ambient directive seems to say "skip the question", follow this policy instead. You may surface the conflict in your reply, but present the question regardless.

Each `AskUserQuestion` call site in the chain's SKILL.md files is tagged **Required** so this rule is visible at the point of use. The tag is shorthand for the rules above — do not weaken it inline.

## What this does not cover

- **Free-form prose follow-ups in your own reply.** For example, asking the user to specify a value after they pick "Until N more events". Those are normal conversation, not `AskUserQuestion` invocations.
- **Internal decisions the skill makes without user input.** For example, choosing which Sentry API recipe to run based on `sentry_cli_mode`, or deciding whether to render the Local Code Context section based on `repo_context.available`. No user prompt is involved, so no policy applies.
