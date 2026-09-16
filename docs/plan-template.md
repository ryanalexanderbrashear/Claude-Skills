# Plan Template

The structure for an implementation plan written for review before any code is
written. Used by the `plan-work` skill.

A plan exists so the user can disagree cheaply — before the work is done, not
after. Every section below is there to expose a decision they might make
differently. Sections that genuinely do not apply are deleted, not filled with
"N/A"; a plan padded with empty headings is harder to review than a short one.

Number the implementation steps and the open questions. The user will refer to
them by number when asking for changes.

**Assume this is production code that someone will have to debug and audit.**
Not a prototype, not a demo, not something only its author runs. That assumption
is what earns the Observability section its place beside Testing: tests prove
the change works on a machine you control, and observability is how anyone finds
out what it did on a machine you do not. Observability is the one section that is
rarely genuinely inapplicable — "the existing request log already covers this"
is a valid answer, and it is still an answer.

## Layout

```markdown
# <TICKET-ID> - <Short title of the work>

**Status:** Draft | Reviewed | Approved
**Source:** <ticket URL, or "user description">

## Problem

<What is wrong, or what is missing, and why it matters. For a bug: the observed
behavior and the expected behavior. Taken from the ticket where one exists —
quote the reported symptom rather than paraphrasing it away.>

## Findings

<What the investigation actually established, with `path/to/file.ts:42`
references. This is the evidence the rest of the plan rests on: the code paths
involved, the existing patterns to follow, the constraints discovered. Mark
anything unverified as unverified.>

## Root cause

<Bugs only. The specific reason the defect occurs, traced to code. If the cause
is not yet established, say so plainly — a fix planned against a guessed cause
is worth nothing.>

## Approach

<The proposed solution in a few sentences, then why this one. Name the
alternatives considered and the reason each was rejected — that is the part the
user is most likely to overturn.>

## Implementation steps

1. **<Step name>** — <what changes, in which files, and what it achieves.>
2. **<Step name>** — <…>

<Order the steps so the tree builds and tests pass at each one where possible.>

## Testing

<How the change will be verified: the automated tests to add or update, and the
manual checks that cannot be automated. If some part cannot be tested, say why.>

## Observability

<How a failure in this change will be noticed, diagnosed and audited once it is
running in production and nobody is watching. Name the signal, not the
intention: which log line, at which level, carrying which identifiers; what a
person greps for at 3am; what an auditor reads to reconstruct who did what.

If the change adds a slow path, say what makes slowness visible. If it adds a
guard, say what a tripped guard looks like from outside the process. If existing
signals already cover it, say which ones and why they are enough — that is a
finding, not a skipped section.>

## Risks and unknowns

- <What could go wrong, what is uncertain, what depends on something outside
  this change.>

## Open questions

1. <A decision the user needs to make, with your recommendation and the
   tradeoff. Do not resolve these silently.>

## Out of scope

- <Related work deliberately excluded, and whether it needs a follow-up ticket.>
```

## Downstream use

The plan is the raw material for the pull request that closes the work. When the
change ships, the sections map onto `pr-template.md` directly:

| Plan section | PR section |
| --- | --- |
| Problem | Description — why this change exists |
| Approach | Description — why this approach, alternatives rejected |
| Testing | Testing instructions |
| Observability | Risk and rollback — how a problem gets noticed |
| Findings, Risks and unknowns | Change splash zone, Risk and rollback |
| Out of scope | Description — what is deliberately not here |

Writing the plan well means the PR description is largely already written.
