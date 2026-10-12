# Writing Style — documents a person would actually write

Every narrative artifact AI-DLC produces — the Feature doc, the Epic description, the Design
document, the ADRs — is meant to be **read by people**: a product owner, an engineer joining the
work, a reviewer deciding whether to approve. Those readers are poorly served by terse,
fragment-style output: lines stitched together with em-dashes and semicolons, headings made of
stacked nouns, and sections that are really just bullet lists standing in for explanation. This
reference defines how to write these documents so they read like a thoughtful human wrote them —
in complete sentences, organised into paragraphs, with enough detail to remove ambiguity.

This is about *prose quality*, and it complements `artifact-consolidation.md` (which decides how
many pages there are) and the per-document templates (which decide what sections appear). Apply it
whenever you author or update a Feature, Epic, Design, or ADR page.

## Write in sentences and paragraphs

The default unit of a document is the **paragraph**, not the bullet. Each section should open with
a sentence or two that states what the section is about and why it matters, and then develop the
idea in a few connected sentences. A reader should be able to start at the top of a section and
read straight through without having to reassemble meaning from fragments.

Do not write in telegraphic shorthand. A line such as *"Bi-temporal — event_time + as_of;
point-in-time read; reproducible"* forces the reader to decode it. Written properly it becomes:
*"The model is bi-temporal: every event records both when it happened and the point in time at
which we knew about it. Reads are evaluated as of a chosen moment, so the same question asked twice
returns the same answer even after late data arrives."* The second version is longer, and that is
the point — it actually explains itself.

## Lead with the why, then the what and the how

Begin a document, and ideally each major section, by explaining the problem or intent before diving
into mechanics. A design section about storage should first say *why* the storage is shaped the way
it is, then describe the shape. Readers follow a decision far more easily when they understand the
pressure that produced it.

## Use lists sparingly, and only for genuinely listable things

Bullet and numbered lists are for enumerations that are naturally a list: a set of API endpoints, a
sequence of steps, a small table of options. They are **not** a way to avoid writing sentences. If
you find a section that is entirely bullets, it almost always should be one or two paragraphs
instead. When a list genuinely helps, write each item as a **complete sentence**, not a fragment,
and introduce the list with a sentence that says what it contains.

Tables are welcome for truly tabular material — data contracts, decision logs, requirement
matrices, status — where the grid carries meaning. Do not turn narrative into a table to avoid
prose.

## Define terms, expand acronyms, and assume a newcomer

Write so that someone competent but new to this feature can follow the document without a glossary
open in another window. Expand an acronym the first time it appears. When you introduce a term that
carries specific meaning in this project — *canonical event*, *coverage*, *provenance* — say in a
clause what it means. The goal is a document that teaches as it informs.

## Keep the plain-language sections plain

In the Design document, sections 1, 2, 6, 7 and 9 (overview, solution summary, key flows, business
rules, security) are written for a BA/PO to validate the solution. Keep these free of code
identifiers, table names and class names wherever you can; describe behaviour in the language of
the business. The engineering detail belongs in the other sections, and even there it should be
embedded in explanatory prose rather than dumped as a list of field names.

## Be detailed, not padded

"Human-written" does not mean verbose. Say everything the reader needs and nothing they do not.
Detail means covering the real cases — the happy path and the failure paths, the edge that will
trip someone up, the reason an alternative was rejected — in enough words to be unambiguous. It does
not mean restating the same point three ways or filling space with ceremony. A good section is as
long as the idea requires and no longer.

## Choose the format that communicates best (prose is the default, not the only tool)

Prose is the default because most of a design or a requirement is reasoning, and reasoning reads
best as sentences. But "write in prose" does not mean "turn everything into long paragraphs."
Detailed and readable also means **using the right shape for each piece of content and keeping it
precise**:

- **A short "at a glance" summary** at the top of any long document — three or four sentences, or a
  handful of one-line bullets — so a busy reader gets the gist before the detail.
- **Bullet lists** for things that are genuinely a set: options, steps, endpoints, a checklist of
  criteria. Keep each item a complete thought; introduce the list with a sentence.
- **Tables** for truly tabular material: data contracts, decision logs, requirement-to-test
  matrices, status, comparisons.
- **A diagram** (a Mermaid flowchart or sequence diagram) when a relationship or a flow is easier to
  see than to read. One clear diagram often replaces three paragraphs.
- **Precision over padding.** Say the thing once, in the fewest words that remove ambiguity. If a
  paragraph is not adding information, cut it. A long document earns its length by covering more
  cases, not by saying the same case at greater length.

The test to apply to every section: *would a reader understand this faster as a paragraph, a short
list, a table, or a diagram?* Use that shape. A document that is all prose can be as hard to use as
one that is all fragments — aim for the mix a good human author would choose.

## Acceptance criteria: write them in EARS, make them testable

Acceptance criteria are where ambiguity does the most downstream damage, so write them to a
standard. Use **EARS (Easy Approach to Requirements Syntax)** — a small set of sentence templates
that make a requirement unambiguous and directly testable:

- **Ubiquitous:** "THE SYSTEM SHALL <response>." (an always-true rule)
- **Event-driven:** "WHEN <trigger> THE SYSTEM SHALL <response>."
- **State-driven:** "WHILE <in a state> THE SYSTEM SHALL <response>."
- **Optional feature:** "WHERE <feature is included> THE SYSTEM SHALL <response>."
- **Unwanted behaviour:** "IF <condition>, THEN THE SYSTEM SHALL <response>." (errors, edge cases)

Every criterion must be a **mechanical yes/no check** a reviewer can answer without interpretation,
with **concrete values** (a real TTL, status code, threshold, enum), and must cover the negative and
permission paths, not just the happy path. Prefer EARS for the crisp rule and add a Given/When/Then
example when a worked scenario aids understanding. A criterion that cannot be turned into a passing
or failing test is not done — rewrite it until it can.

## Voice and mechanics

Write in plain, professional English, in the active voice, in the present tense for how the system
behaves ("the card shows…", "the resolver returns…"). Prefer short, direct sentences over long ones
held together by semicolons. Use em-dashes occasionally for a genuine aside, not as the main
connective tissue of every line. Headings are short noun phrases that name the section; they are not
where the content lives.

## A quick before/after

**Before (fragment style, avoid):**

> Cycle Time — median first-commit→prod over eligible release-linked merged PRs; 4 phases
> (coding/pickup[business-time]/review/deploy); phases don't sum; WIP separate; N/A until 1 prod
> change; show sample size + P85.

**After (prose, use):**

> The Cycle Time card reports how long a change takes to go from its first commit to reaching
> production. The headline figure is the median of that duration across the eligible, release-linked
> pull requests that were merged in the window. Beneath the headline we break the same set of changes
> into four phases — the time spent coding, the time a pull request waits before a reviewer picks it
> up (measured in business hours, not wall-clock), the time in review, and the time waiting to deploy
> — so a leader can see where the delay actually sits. Because medians do not add up, we present the
> phases as a representative breakdown and never claim they sum to the headline. Changes still in
> flight are reported separately as work in progress, and until at least one change has reached
> production the card honestly reads "not available" and shows how small the sample is.

Write every section the second way.
