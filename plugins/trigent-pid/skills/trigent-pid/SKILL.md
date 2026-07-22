---
name: trigent-pid
description: Guide the creation and iterative refinement of a Trigent Project Initiation Document (PID) in Confluence. Covers business case drafting, solution design, Confluence publishing, and comment resolution rounds until final approval. (Triggers - create PID, project initiation document, PID, new project, business case, solution design, pid review, pid refinement, initiation document, project brief, start a PID, update PID, PID feedback, review PID comments, address PID comments, PID approval, business case review)
---

# Trigent Project Initiation Document (PID)

Guide the team through creating or refining a Project Initiation Document — a structured Confluence page capturing the business case and solution design for significant projects, features, refactors, or large cross-team initiatives.

> **When is a PID required?**
> New products, significant new product features, major technical refactors that carry risk, or large cross-team initiatives. If in doubt, advise the user to check with their manager.

## Configuration

This skill is not tied to any single Confluence space. The following placeholders must be
resolved before any Confluence operation — never hardcode a space:

| Placeholder | Meaning |
|---|---|
| `<CONFLUENCE_SPACE_KEY>` | Target Confluence space key (e.g. `ENG`) |
| `<CONFLUENCE_SPACE_ID>` | Numeric space ID for that space |
| `<PID_PARENT_PAGE_ID>` | Page ID of the parent folder where PIDs are published (e.g. "Business Cases — In Review") |

Resolve them, in order of preference:

1. From a `pid.config.yaml` in the project root (see `pid.config.example.yaml` in this plugin for the schema).
2. If an `aidlc.config.yaml` exists, reuse its `atlassian.cloudId` and `confluence.spaceKey`.
3. Otherwise, ask the user for the space key, then call `getConfluenceSpaces({ cloudId, keys: ["<the key>"] })` to resolve the space ID, and ask which parent page PIDs should live under.

The `cloudId` is always retrieved at runtime via `getAccessibleAtlassianResources()`.

## Completion Checklist

> **IMPORTANT**: At skill start, determine the mode and create tasks using `TodoWrite`. Mark tasks in_progress when starting a step, and complete when exit criteria are met.

### Mode A — New PID

| # | Task | Depends On | Exit Criteria |
|---|------|------------|---------------|
| 1 | Determine scope | — | User confirms: BC only, SD only, or full PID; destination folder confirmed |
| 2 | Gather Business Case info | 1 | All BC interview rounds complete |
| 3 | Market & competitive research | 2 | Research brief reviewed and incorporated (or skipped) |
| 4 | Confirm BC summary | 3 | User confirms 5–8 bullet summary is correct |
| 5 | Cross-reference scan | 4 | Related EPD initiatives identified, confirmed, and noted |
| 6 | Draft Business Case | 5 | All BC template sections populated, research and links incorporated |
| 7 | Review and iterate BC | 6 | User approves BC draft |
| 8 | Publish to Confluence | 7 | TBD scan complete; destination confirmed; page created, URL returned to user |
| 9 | Gather Solution Design info | 1, 8 | All SD interview rounds complete (if in scope) |
| 10 | Draft Solution Design | 9 | All SD template sections populated |
| 11 | Review and iterate SD | 10 | Three Amigos confirmed; user approves SD draft |
| 12 | Update Confluence page | 11 | SD completeness check passed; page updated with SD section, URL confirmed |
| 13 | Final handoff | 12 | ELT prep offered; aidlc bridge suggested; user confirms PID ready |

### Mode B — Comment Resolution

| # | Task | Depends On | Exit Criteria |
|---|------|------------|---------------|
| 1 | Fetch PID page and open comments | — | Page content + all open comments retrieved; round number confirmed |
| 2 | Triage and propose resolutions | 1 | Each comment has a typed, proposed resolution; project references looked up |
| 3 | User approves resolutions | 2 | All comments accepted, adjusted, or deferred |
| 4 | Apply changes to Confluence | 3 | Page updated; individual comment replies posted; revision footer added |
| 5 | Confirm round complete | 4 | User confirms next steps; DRAFT callout updated if final round |

## Challenge Level

Before determining the mode, ask the user to choose a **challenge level** that controls how critically Claude examines their assumptions, ideas, and stated requirements throughout the session. This applies to both new PIDs and comment resolution.

> "Before we begin — how much do you want me to challenge your thinking during this process? This controls how critically I'll examine your assumptions, push back on stated requirements, and probe for gaps in the rationale.
>
> - **Low** — I'll focus on capturing your vision faithfully with light clarifying questions. Best when you've already pressure-tested the idea and just need help structuring it.
> - **Medium** *(recommended — default)* — I'll ask pointed follow-up questions, flag potential gaps or risks, and suggest alternatives where I see them. Good for most PIDs.
> - **High** — I'll actively play devil's advocate: questioning assumptions, stress-testing the business case, probing for weak spots, and pushing you to justify key decisions. Best when you want the strongest possible document or are still shaping the idea.
>
> Which level works for you? (Type 'medium' or 'default' to use the recommended default.)"

Wait for the user's response before proceeding. If the user does not specify a recognised level (e.g. says "default", "medium", or gives an unrecognised response), use **Medium** and confirm: *"I'll use Medium — let me know if you'd like to change it."* Record the chosen level and apply it throughout the session as follows:

### Low Challenge Behaviour

- Accept stated goals, scope, and constraints at face value
- Ask clarifying questions only when information is genuinely missing or ambiguous
- Focus on completeness — ensure every template section is populated
- Flag only clear contradictions or factual issues
- During comment resolution: propose straightforward resolutions aligned with the author's intent

### Medium Challenge Behaviour

- Ask pointed follow-ups on key claims: "What evidence supports this?", "Have you validated this with users?"
- Flag gaps in reasoning — e.g., missing risk mitigations, unstated assumptions, thin customer validation
- Suggest alternatives when the stated approach has obvious trade-offs: "Have you considered X as an alternative?"
- Probe scope boundaries: "You've included X but excluded Y — what's the rationale for the boundary?"
- During market research (Step 3): actively compare claims against findings and surface discrepancies
- During comment resolution: consider whether the commenter's concern has deeper merit beyond the surface objection

### High Challenge Behaviour

- Actively play devil's advocate on business justification: "If a competitor already does this, what's the defensible differentiator?", "What happens if you don't build this?"
- Stress-test the investment case: "Is the ROI realistic given these assumptions?", "What would need to be true for this to fail?"
- Question scope aggressively: "Could you achieve 80% of the value with half the scope?", "Is this a feature or a product?"
- Challenge timing and priority: "Why now rather than next quarter?", "What's the cost of delay vs. the cost of doing this wrong?"
- Push for specificity on vague claims: turn "improved efficiency" into measurable outcomes
- Surface second-order risks the user may not have considered
- During interviews: don't accept the first answer — probe one level deeper on key assertions
- During comment resolution: assess whether comments reveal a fundamental concern with the approach, not just a wording issue
- Before drafting: explicitly summarise the strongest argument *against* proceeding and ask the user to address it

> **Important:** High challenge is not hostility. Frame challenges constructively — the goal is to strengthen the document, not to discourage the initiative. Always acknowledge the merit of the user's idea before probing its weaknesses.

---

## Task Tracking

When this skill is invoked:

1. **Set challenge level** — ask the challenge level question above before anything else
2. **Determine mode** — ask "New PID or refining an existing one?" before creating tasks
3. **Create tasks** for the relevant mode checklist using `TodoWrite`
   - Include the mode and step reference in the task description (e.g., "Gather Business Case info (Mode A > Step 2)")
   - Set activeForm appropriately (e.g., "Gathering Business Case information")
4. **Mark in_progress** when starting each step
5. **Mark complete** when exit criteria are met
6. **Verify all tasks complete** before finishing the skill

## AI-Drives-Conversation Pattern

This skill follows the Trigent EPD pattern where AI initiates and directs the conversation:

1. **AI proposes** — surface options, risks, and trade-offs proactively
2. **Human approves** — validate, adjust, or redirect
3. **AI elaborates** — expand on the approved direction with full detail
4. **Human confirms** — explicit approval gate before writing to Confluence

> **Never write to Confluence without explicit user approval of the draft content.**

## Example Invocations

- "Start a PID for the new visitor management rewrite"
- "Help me create a business case for the API gateway project"
- "I need to refine my PID — can you check the Confluence comments?"
- "Round 2 on the mobile app PID — let's address the stakeholder feedback"

---

## Workflow A — New PID

### Step 1: Determine Scope

Start by understanding the user's starting point. Ask:

1. Are you preparing just the **Business Case**, the **full PID** (Business Case + Solution Design), or just the **Solution Design** (if a BC already exists and has been approved)?
2. What is the project name?
3. Is there an existing Jira project or JPD issue to link?
4. **Where in the EPD space should this PID be published?** The default is **Business Cases — In Review**. If you'd like to publish to a specific programme area, team sub-folder, or custom location, say so now and I'll look it up — otherwise I'll use the default.

If the user is unfamiliar with PIDs, briefly explain:

> A PID has two sections. The **Business Case** (Section 1) justifies _why_ the project should be done — it's reviewed by ELT first. The **Solution Design** (Section 2) describes _how_ — covering architecture, tech approach, testing, delivery, and risks. They can be completed together or in separate rounds.

After scope is confirmed, record the chosen publish destination (default: parentId `<PID_PARENT_PAGE_ID>`), create tasks for Mode A, and proceed.

---

### Step 2: Gather Business Case Information

Conduct a conversational interview. **Group related topics** and ask one group at a time — never present all questions as a single list. Adapt based on what the user has already shared.

Follow the Business Case interview guide in @${CLAUDE_PLUGIN_ROOT}/references/pid-reference.md.

After each round, summarise what's been captured and confirm before moving to the next.

> **Note while interviewing:** If the user mentions competitor names, other internal projects, or existing Trigent products by name, record them. These will be used in Steps 3 (research) and 5 (cross-reference).

---

### Step 3: Market & Competitive Research (Optional)

After completing all BC interview rounds, offer a market and competitive research pass:

> "Before I draft the Business Case, I can run a quick market and competitive research pass to help strengthen the investment analysis and positioning sections. This can surface market size estimates, key competitors, relevant industry trends, and data points to support the 'why now?' narrative. Would you like me to do that?"

If the user declines, skip to Step 4.

If the user agrees, proceed as follows:

#### 3a — Identify search terms

From the BC interview, extract:
- **Product/service category** — the market segment this project operates in (e.g., "school visitor management software", "student ID card platforms")
- **Named competitors** — any competitors explicitly mentioned during the interview
- **Domain keywords** — 2–3 terms that describe the problem space
- **"Why now?" signals** — any market changes, regulatory shifts, or industry events mentioned

#### 3b — Run research searches

Execute the following `WebSearch` calls (adapt terms to the specific project):

1. **Market size & growth** — `[product/service category] market size [current year]`
2. **Competitor landscape** — `[product/service category] top competitors [current year]`
3. **Named competitor deep-dive** — `[specific competitor name] features pricing [current year]` *(run once per named competitor, if any were mentioned)*
4. **Industry trends** — `[domain keyword] industry trends [current year]`
5. **Analyst / benchmark data** — `[product/service category] analyst report OR benchmark [current year]`

Do not run more than 6 searches total. Prioritise quality over quantity — skip a search type if the project domain is very niche and unlikely to return useful results.

#### 3c — Synthesise into a Research Brief

Compile findings into a structured brief:

```
## Research Brief — [Project Name]

### Market Overview
- Estimated market size: [figure + source]
- Growth rate / trend: [e.g., "~12% CAGR through 2027 — Source: X"]
- Key tailwinds: [2–3 bullet points from trend research]

### Competitor Landscape
| Competitor | Positioning | Notable Strengths | Notable Weaknesses |
|------------|-------------|-------------------|-------------------|
| [Name] | [e.g., "Enterprise-focused"] | [Insert] | [Insert] |

### Data Points for Business Case
- [Stat 1 — e.g., "73% of K-12 schools report visitor tracking as a compliance requirement — Source: X"]
- [Stat 2]

### Sources
- [Source 1 — title + URL]
- [Source 2]
```

> ⚠️ **Sourcing note:** All figures in this brief are drawn from public web sources and should be verified before including in presentations or external documents. Market size estimates in particular vary widely by source and methodology.

#### 3d — Review with user

Present the Research Brief and ask:

> "Here's what I found. Does this look accurate and relevant to the project? Are there any competitors I missed, or any data points you'd like me to dig into further? I'll incorporate the approved findings into the relevant Business Case sections when I draft."

After the user confirms, note which findings map to which BC sections:
- Customer validation stats → **Section 3** (Customer & User Validation)
- Trend / "why now?" data → **Section 2** (Objectives)
- Competitor data → **Section 7** (Alternatives Considered) and **Section 11** (Marketing Positioning)
- Market size / growth → **Section 8** (Investment Analysis — Addressable Market)
- Specific stats → use inline citations with source attribution

---

### Step 4: Confirm Business Case Understanding

Synthesise everything gathered (interview + approved research findings) into 5–8 concise bullets. Ask:

> "Before I draft, let me confirm my understanding: [bullets]. Does this capture the project correctly? Any corrections?"

Do not proceed to drafting until the user confirms.

---

### Step 5: Cross-Reference Scan

Before drafting, search the EPD Confluence space for related initiatives, existing PIDs on similar topics, and any content that should be linked or acknowledged.

#### 5a — Extract search terms

From the confirmed BC summary, extract:
- The project name (and any nickname)
- 2–3 core domain or capability keywords
- Any internal projects, products, or systems mentioned in the interview
- Any predecessor or related initiatives explicitly referenced

#### 5b — Search the EPD space

Use Atlassian MCP:

1. `getAccessibleAtlassianResources()` — get cloudId (if not already retrieved)
2. Run `searchConfluenceUsingCql()` with the following queries (adapt terms to the project):

   - **Related PIDs**: `space = "<CONFLUENCE_SPACE_KEY>" AND title ~ "Project Initiation Document" AND text ~ "[domain keyword]" ORDER BY lastModified DESC`
   - **Title match**: `space = "<CONFLUENCE_SPACE_KEY>" AND title ~ "[project name keyword]" ORDER BY lastModified DESC`
   - **Content match**: `space = "<CONFLUENCE_SPACE_KEY>" AND text ~ "[core capability keyword]" AND type = page ORDER BY lastModified DESC`

3. Limit each query to 10 results. Deduplicate across queries by page ID.

#### 5c — Deduplication check

⚠️ If any result has a title closely matching `[Project Name] — Project Initiation Document` (the current project's intended title), flag it immediately:

> "⚠️ A page with a very similar title already exists in the EPD space: **[title]** ([link]). Do you want to review it before we proceed? It may be a duplicate, a related predecessor, or a different project with a similar name."

Wait for the user's response before continuing.

#### 5d — Present findings

Group results into three tiers and present them to the user:

```
Cross-Reference Results for [Project Name]:

**Directly referenced** (mentioned during the interview):
- [Page title] — [Confluence link] — [brief description]

**Related PIDs** (other initiatives in a similar space):
- [Page title] — [Confluence link] — [brief description]

**Related EPD content** (relevant but not PIDs):
- [Page title] — [Confluence link] — [brief description]
```

If no relevant results are found, say so and proceed.

Ask:
> "Which of these should be referenced in the PID? I can add them as links in the Related Initiatives field, the Dependencies section, or inline in the Description where relevant."

Wait for the user's response, then record the confirmed links and where each should appear in the document.

---

### Step 6: Draft Business Case

Use the Business Case template in @${CLAUDE_PLUGIN_ROOT}/references/pid-reference.md.

- Populate every section. Use `TBD — [what information is needed]` for genuinely unknown fields — never skip sections.
- **Incorporate research findings**: In Sections 2, 5, and 8, weave in approved data points from the Research Brief (Step 3). Use inline source attribution — e.g., *(Source: [publication], [year])*.
- **Incorporate cross-references**: Populate the `Related Initiatives` field with confirmed Confluence links from Step 5. Add inline mentions or links in the Description or Dependencies where appropriate.
- Present the full draft inline so the user can review it directly.

---

### Step 7: Review and Iterate — Business Case

Ask for approval and iterate until the user says "approved", "looks good", or equivalent.

Track which sections have been revised. If revisions are significant, offer a clean re-read of the full draft before asking for final approval.

---

### Step 8: Publish to Confluence

#### 8a — Destination folder

If the user did not confirm a destination in Step 1, ask now:

> "Where in the EPD space should I publish this? Your options:
> 1. **Business Cases — In Review** (default) — Standard location for new PIDs awaiting ELT review
> 2. **Browse sub-folders** — I'll list the child pages under Business Cases — In Review so you can pick a specific area
> 3. **Custom** — Paste a Confluence page URL or page ID to use as the parent"

If the user selects **Browse sub-folders**, call:
- `getAccessibleAtlassianResources()` — get cloudId (if not already retrieved)
- `getConfluencePageDescendants(cloudId, "<PID_PARENT_PAGE_ID>")` — list child pages under Business Cases — In Review

Present the results as a numbered list (page title + page ID) and ask the user to choose.

If the user provides a Confluence page URL, extract the page ID (the number after `/pages/` in the URL).

Record the confirmed `parentId` before proceeding.

#### 8b — Pre-publish TBD scan

Before creating the page, scan the approved BC draft for remaining `TBD —` placeholder entries:

- Count the total number and list which sections contain them
- Ask:
  > "There are **N** sections with placeholders: [list sections]. Would you like to fill any in now before publishing, or are you happy to publish with these marked as pending? (You can always address them in a comment resolution round.)"

If the user wants to fill in any placeholders, update the draft now before proceeding. If they're happy to publish as-is, proceed.

If there are zero TBD entries, skip this gate and proceed directly.

#### 8c — Create the page

Use Atlassian MCP to create the Confluence page:

1. `getAccessibleAtlassianResources()` — retrieve the cloudId (if not already retrieved)
2. `getConfluenceSpaces({ cloudId, keys: ["<CONFLUENCE_SPACE_KEY>"] })` — confirm the spaceId (expected: `<CONFLUENCE_SPACE_ID>`)
3. `createConfluencePage()` with:
   - **cloudId**: from step 1
   - **spaceId**: `<CONFLUENCE_SPACE_ID>`
   - **parentId**: confirmed in step 8a (default: `<PID_PARENT_PAGE_ID>`)
   - **title**: `[Project Name] — Project Initiation Document`
   - **contentFormat**: `markdown`
   - **body**: Business Case section with a DRAFT status callout at the top (see template in reference file)

Return the Confluence page URL to the user and say:

> "Your Business Case draft is live at [URL]. Share it with stakeholders and ask them to add comments directly in Confluence. When you're ready to address feedback, run `/trigent-pid` again and choose 'Refine existing PID'."

⛔ **STOP — Gate**: If only the Business Case was requested, stop here. If the full PID is in scope, continue to Step 9.

---

### Step 9: Gather Solution Design Information

Continue the interview for the Solution Design. Group questions into rounds — do not present all at once.

Follow the Solution Design interview guide in @${CLAUDE_PLUGIN_ROOT}/references/pid-reference.md.

---

### Step 10: Draft Solution Design

Use the Solution Design template in @${CLAUDE_PLUGIN_ROOT}/references/pid-reference.md.

- Populate every section. Use `TBD — [what's needed]` for unknowns.
- Present the full draft for review.

---

### Step 11: Review and Iterate — Solution Design

#### 11a — Three Amigos confirmation

Before reviewing the draft, confirm the Three Amigos have had a chance to contribute:

> "Before we finalise the SD, have all three Amigos — Product Lead, Engineering Lead, and Design Lead — had a chance to review and contribute to the content we've discussed? The SD is most valuable when it reflects all three perspectives.
>
> - **Yes** — great, let's review the draft together.
> - **Not yet** — I'd recommend sharing the draft for their input before publishing. Would you like to proceed anyway and treat this as a working draft, or pause here?"

If the user confirms all Amigos have been involved, proceed to the review.

If the user wants to pause: note this in the document's DRAFT callout (e.g., "Awaiting Three Amigos review — not yet final"), publish the working draft to Confluence for their review, and advise the user to run `/trigent-pid` again once input has been gathered.

#### 11b — Review and iterate

Ask for approval and iterate until the user says "approved", "looks good", or equivalent. If changes are substantial, offer a clean re-read before final approval.

---

### Step 12: Update Confluence Page

#### 12a — SD completeness check

Before appending the Solution Design, assess completeness in the critical sections below. These are the areas reviewers most commonly flag as thin:

| Section | Check |
|---------|-------|
| Architecture Overview | Is this substantive (more than 1 sentence / not just "TBD")? |
| Data Model | Is this populated, or explicitly marked "no data model changes"? |
| Data Migration | Is this addressed, or explicitly marked "net-new feature, N/A"? |
| Test Approach | Is at least one of manual/automated populated beyond "TBD"? |
| NFRs: Security | Is this substantive? |
| NFRs: Accessibility | Is the WCAG target specified? |
| Open Questions | Are any known unknowns captured, or is the table explicitly empty? |

If one or more critical sections are substantively empty (not just one TBD, but genuinely unaddressed), flag them before publishing:

> "Before I publish the Solution Design, I want to flag that these sections appear incomplete: [list]. Publishing with thin content here can invite critical feedback in review and slow down sign-off. Would you like to add more detail now, or publish as-is knowing these will need to be addressed in a comment resolution round?"

Wait for the user's decision before proceeding.

#### 12b — Update the page

Retrieve the current page content via `getConfluencePage(pageId)`, then `updateConfluencePage()` to append the Solution Design section after the Business Case. **Preserve all Business Case content exactly.**

Update the DRAFT callout to reflect that both sections are now present.

Confirm the updated URL to the user.

---

### Step 13: Final Handoff

#### 13a — ELT presentation prep (Optional)

Offer to help prepare for the ELT review meeting:

> "Your PID is published. Would you like help preparing for the ELT review? I can put together any of the following based on the BC content:
>
> 1. **Talking points** — a 5-minute verbal walkthrough structure covering the key BC arguments in order
> 2. **Meeting invitation summary** — a short executive paragraph suitable for the calendar invite or pre-read note
> 3. **Anticipated questions & responses** — likely ELT questions based on the BC content, with suggested answers
>
> Which of these would be useful, or would you like all three?"

If the user requests any of these, generate them grounded in the actual BC content — do not invent details not in the document.

#### 13b — aidlc bridge

If the full PID (both BC and SD) has been published, suggest the natural next step:

> "Now that the full PID is published, the next step is delivery planning. The **aidlc** plugin can help decompose the Solution Design into structured Tasks and Units, plan the delivery approach, and create the full Jira hierarchy (Epics, Stories, Sub-tasks) from it.
>
> When you're ready, run `/aidlc-intent` — you can reference this PID page as the source of truth for the Intent document."

If only the BC has been published (SD not yet in scope), skip this suggestion and instead tell the user:

> "Your Business Case draft is live at [URL]. Next steps: share it with stakeholders, ask them to add comments directly in Confluence, and schedule your ELT review. When you receive feedback, run `/trigent-pid` and choose 'Refine existing PID' to start a comment resolution round."

---

## Workflow B — Comment Resolution

### Step 1: Fetch PID Page and Open Comments

Ask for the Confluence page URL or page ID. Extract the page ID from the URL (the number after `/pages/`).

Use Atlassian MCP:
1. `getAccessibleAtlassianResources()` — get cloudId
2. `getConfluencePage(pageId, contentFormat: "markdown")` — retrieve page body
3. `getConfluencePageInlineComments(pageId, resolutionStatus: "open")` — open inline comments
4. `getConfluencePageFooterComments(pageId, status: "current")` — footer/general comments

**Auto-detect round number:** Scan the retrieved footer comments for entries matching the pattern `"Comment resolution round"`. Count how many exist to determine the current round (e.g., if two prior round summaries exist, this is Round 3). Report this to the user and confirm:

> "I can see [N] previous resolution round(s) recorded on this page — this will be **Round [N+1]**. Does that sound right?"

If no prior round comments are found, default to Round 1 and confirm with the user.

**Store comment IDs** — record the ID of every open comment retrieved in this step. You will need these IDs in Step 4 to post individual replies.

Report back to the user:
- Page title and current DRAFT/published status
- **Round number** (auto-detected or confirmed above)
- Total open inline comments (with count)
- Total footer comments (with count)
- Brief thematic grouping of comments (e.g., "3 comments about scope, 2 about risks, 1 editorial")

If there are child comments (replies), fetch them via `getConfluenceCommentChildren()` to understand the full thread context.

---

### Step 2: Triage and Propose Resolutions

For each open comment, produce a structured resolution entry:

```
Comment #N — [Inline | Footer]
Author: [name or account]
Context: "[quoted text the comment is anchored to, or section title]"
Comment: "[full comment body]"

Type: Editorial | Clarification Needed | Missing Information | Factual Disagreement | Question / Query
Proposed Resolution: [specific wording change, section addition, or explanation to add]
Confidence: High (clear fix) | Medium (judgment call) | Low (needs user input before acting)
```

- Group related comments that affect the same section together
- For Low confidence items, explicitly state what additional input is needed from the user
- Flag any comments that raise a significant concern warranting discussion before editing (use **⚠️ Significant concern — discuss before editing**)

**Project references in comments:** If a comment references another internal project, initiative, or system by name (e.g., "similar to what the Kiosk team built", "see the API Gateway PID"), offer to look it up:

> "Comment #N references '[project name]'. Would you like me to search the EPD space for this and add a link in the updated document?"

If the user agrees, run `searchConfluenceUsingCql()` against the `<CONFLUENCE_SPACE_KEY>` space for the referenced name, and incorporate a confirmed link into the proposed resolution.

---

### Step 3: Present Resolutions for Approval

Present the full triage list and ask:

> "Here are my proposed resolutions for [N] comments. Reply with numbers to accept (e.g., 'Accept 1, 2, 4'), adjustments for specific ones (e.g., 'For #3, instead say X'), or to defer any (e.g., 'Defer 5 — need more info'). I'll wait for your full response before making changes."

Wait for a complete response before proceeding. Do not partially apply changes.

---

### Step 4: Apply Changes to Confluence

1. Re-fetch the current page content (it may have changed since Step 1): `getConfluencePage(pageId)`
2. Apply all accepted resolutions to the content, preserving the document structure
3. `updateConfluencePage()` with the revised content and a version message describing the round (e.g., "Round 1 comment resolution — addressed 5 comments")
4. **Reply to each accepted and deferred comment individually** using `createConfluenceFooterComment()` with `parentCommentId` set to the original comment's ID:

   For accepted comments:
   > _"Addressed in Round [N]: [one sentence describing what changed]."_

   For deferred comments:
   > _"Deferred in Round [N]: [reason, or 'needs further discussion before actioning']."_

5. Add a page-level footer comment summarising the full round:
   > _"Comment resolution round [N] — [date]: Addressed comments #[accepted list]. Deferred: #[deferred list if any]. Applied by Claude Code via /trigent-pid."_

Confirm the updated page URL to the user.

---

### Step 5: Confirm Round Complete

Ask:

> "Round [N] complete — the page has been updated at [URL]. Are more review passes expected, or is the PID approaching final approval? Let me know when to start another round, or when the approval meeting is scheduled."

If the user indicates this is the final round:

1. **Offer DRAFT callout removal**: Ask:
   > "Would you like me to remove the DRAFT status callout and mark the page as approved? I can update it directly — or you can do it manually in Confluence."

   If the user confirms, re-fetch the page, remove the DRAFT callout block from the top of the content, and call `updateConfluencePage()` with a version message of `"Removed DRAFT status — PID approved"`.

2. **Suggest next steps:**
   - Moving the page to the Approved Projects folder (`1401716737`) via the Confluence UI
   - Linking the page to the relevant JPD issue

---

## Confluence Space and Storage Reference

| Location | Purpose | Parent Page ID |
|----------|---------|----------------|
| Business Cases — In Review | New draft PIDs and Business Cases pending approval | `<PID_PARENT_PAGE_ID>` |
| Approved Projects | Business Cases and PIDs approved by ELT | `1401716737` |
| Rejected | Rejected Business Cases | `1685389313` |

- **Space key**: `<CONFLUENCE_SPACE_KEY>` — Space ID: `<CONFLUENCE_SPACE_ID>`
- **PID template page** (reference only): `2147942594` — do not create child pages under it

> **Note on page moves**: Moving pages between folders must be done in the Confluence UI. Inform the user when a move is appropriate (e.g., after ELT approval → move to Approved Projects).

> **Browsing sub-folders**: Use `getConfluencePageDescendants(cloudId, parentPageId)` to list child pages under any known parent. This is useful when the user wants to publish to a specific programme area or team sub-folder within Business Cases — In Review. Add `depth: 2` if you need to see nested levels.

---

## Definition of Done

**New PID:**
- Destination folder confirmed before publishing
- Market research completed or explicitly skipped
- Cross-reference scan complete; confirmed links incorporated into draft
- TBD scan completed and user has acknowledged any remaining placeholders
- BC sections: Customer & User Validation, Strategic Alignment, and Alternatives Considered populated
- Confluence page created in the confirmed destination folder
- Business Case section fully populated, with research data cited and cross-references linked
- Solution Design section populated (if in scope); Three Amigos confirmed; SD completeness check passed
- Data Model, Data Migration, and Accessibility sections addressed in SD (or explicitly marked N/A)
- Open Questions table populated or explicitly left empty
- ELT presentation prep offered; aidlc bridge suggested (if full PID)
- DRAFT callout present at the top of the page
- User has confirmed the PID is ready for stakeholder review

**Comment Resolution Round:**
- Round number confirmed
- Project references in comments looked up and linked where confirmed
- All accepted resolutions applied to the Confluence page
- Individual reply posted to each accepted and deferred comment
- Page-level revision footer comment added
- User has confirmed the round is complete and stated next steps

---

## Troubleshooting

- **Page not found**: Ask for the page ID from the URL — it's the number after `/pages/` (e.g., `2147942594`)
- **No comments appearing**: The skill fetches open/unresolved comments only — resolved comments won't be returned
- **Comment context unclear**: Ask the user to paste the full comment text before proposing a resolution
- **Unknown field values**: Use `TBD — [what information is needed]` — never skip a template section
- **Confluence write fails**: Confirm the user's Atlassian account has edit permissions for the `<CONFLUENCE_SPACE_KEY>` space
- **Space not found**: Try using the numeric space ID `<CONFLUENCE_SPACE_ID>` directly instead of the key `<CONFLUENCE_SPACE_KEY>`
- **User wants to restart mid-session**: Re-ask the mode question and recreate the task list from scratch for the new mode
- **Can't find sub-folders**: Use `getConfluencePageDescendants(cloudId, "<PID_PARENT_PAGE_ID>")` to browse what's under Business Cases — In Review; add `depth: 2` if you need nested levels
- **Round number unclear**: If footer comments don't match the expected "Comment resolution round" pattern, ask the user directly which round this is
- **parentCommentId not found for replies**: Store comment IDs when fetching in Step 1 — you need them in Step 4 to reply to individual comments; if IDs are unavailable, fall back to a single page-level footer summary
- **Market research returns thin results**: If the domain is very niche, note this to the user and proceed with what was found — don't fabricate data points; use "TBD — market data not readily available" in the relevant BC sections
- **Cross-reference CQL returns too many results**: Narrow by adding `AND title ~ "Project Initiation Document"` to find only PIDs, or add a date filter like `AND lastModified >= "2024-01-01"` to focus on recent work
- **Near-duplicate PID found**: Do not proceed until the user has reviewed the existing page and confirmed this is a genuinely distinct initiative — flag with ⚠️ and wait for explicit go-ahead
- **Three Amigos not all available**: If one Amigo is unavailable, note the gap in the DRAFT callout and publish as a working draft — advise the user to gather their input before the ELT review
- **SD completeness check flags critical gaps**: Do not silently publish thin sections — surface the specific gaps, give the user the choice, and record what was acknowledged
- **ELT prep content wrong**: If the generated talking points or anticipated questions don't match the actual PID content, ask the user to correct specific details before finalising — never invent positions or data not in the document
- **Data model is N/A**: If the feature genuinely creates no new data and modifies no schema, write "No data model changes — this feature operates entirely on existing entities" in that section — do not leave it blank or TBD
- **Data migration is N/A**: If the feature doesn't touch existing data, write "Net-new feature — no migration required" — do not leave it blank or TBD
