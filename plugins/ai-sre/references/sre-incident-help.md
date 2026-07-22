# sre-incident Help Text

Output the block below verbatim when `$ARGUMENTS` contains "help", then stop — do not continue to Phase 0.

```
/ai-sre:sre-incident [product] SYMPTOM

Evidence-driven incident triage. Builds a visible hypothesis scorecard from normalized signals.
Never declares root cause without proof. Separates mitigation from root cause confirmation.

Products:
  em                               Emergency Management
  training                         Training Platform
  psw / psw-us / psw-ca            PSW (AWS ECS — region inferred from symptom)
  vm / visitor                     Visitor Management
  volunteer / vol / volunteersafe  Volunteer Management
  dismissal / dis                  DismissalSafe
  cpoms-studentsafe / studentsafe  CPOMS StudentSafe
  cpoms-staffsafe / staffsafe      CPOMS StaffSafe
  smartpass                        SmartPass
  schoolpass                       SchoolPass
  eventsafe / es                   EventSafe
  badge / badge-alert              Badge Alert
  platform / plt                   Platform (shared services — UserContactRole, ClientBuilding, Product, UserAuth)
  integrations / int               Integrations (Webhooks, TrigentLink V3, Audit, SOR, Staff Sync)
  trigent-safe / trigentsafe         Trigent Safe (mobile Passport check-in — kiosk-service, EUS, Regula faceapi)

Examples:
  /ai-sre:sre-incident psw 504 errors health check green
  /ai-sre:sre-incident em api returning 500s
  /ai-sre:sre-incident training CDC pipeline stopped
  /ai-sre:sre-incident vm kiosk not scanning

Output:
  • Incident Evidence Scorecard — persistent artifact updated every phase
  • SEV1–4 classification with blast radius
  • Top 5 hypotheses with evidence for/against and evidence level
  • Contradiction testing — hypotheses demoted automatically on 3+ VERIFIED_NEGATIVE signals
  • Confirmed root cause (2 corroborating OR 1 VERIFIED signal required)
  • Mitigation plan with reversibility classification — separate from root cause
  • Incident timeline for postmortem handoff

Related: /ai-sre:sre-postmortem (when resolved) · /ai-sre:sre-runbook (prevent recurrence)
```
