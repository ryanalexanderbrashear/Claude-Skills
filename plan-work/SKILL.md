---
name: plan-work
description: Investigate a bug or feature from a ticket or a user's description, then write an implementation plan to a file for the user to review and iterate on before any code is written. Use when the user wants a plan, wants work scoped or broken down, asks how they would approach a ticket, or hands over a ticket ID, ticket URL, or bug report.
---

# Plan work from a ticket or description

Turn a ticket or a description of a bug or feature into an implementation plan,
written to a file the user can read, argue with, and revise. A finished result
is a plan the user has approved — grounded in the actual code, with the open
decisions surfaced rather than guessed at.

## When to use

- The user hands over a ticket ID, ticket URL, or bug report and wants it
  scoped.
- The user describes work and asks how it should be approached, or asks for a
  plan or a breakdown before implementing.
- Work is large or ambiguous enough that starting to code would mean guessing.

Do not use this for work small or clear enough to simply do — a plan for a
one-line fix wastes the user's review. Do not use it to stress-test a plan the
user already has; that is `grill-me`.

## Instructions

### 1. Gather the source material

If the user named a ticket, read it before anything else:

```bash
gh issue view <number>                    # GitHub issues
gh pr view <number>                       # a linked PR
glab issue view <number>                  # GitLab
```

For JIRA or another tracker, use a configured CLI or MCP tool if one is
available. If you cannot reach the ticket, ask the user to paste its contents.
Never write a plan against an invented ticket — if the ticket text is
unavailable and the user has not described the work, stop and ask.

If there is no ticket, work from the user's description and ask for the details
it is missing: the observed behavior, the expected behavior, and how to
reproduce it for a bug; the user-facing outcome and its constraints for a
feature.

### 2. Investigate before planning

Read the code. A plan written from the ticket alone is a guess.

- **For a bug**, find the root cause and trace it to specific lines. Reproduce it
  if it is cheap to do so. If you cannot establish the cause, say so in the plan
  rather than proposing a fix for a cause you assumed.
- **For a feature**, find the existing patterns the change should follow, the
  code it will touch, and the constraints already in place.
- Note the file and line references as you go — the plan cites them.

Ask the user questions the codebase cannot answer. Do not ask questions the
codebase can.

### 3. Write the plan to a file

Follow `~/.claude/skills/docs/plan-template.md` (repo path:
`docs/plan-template.md`).

Write it to the session scratchpad directory, named for the ticket or the work:
`<TICKET-ID>-plan.md`, or a short slug when there is no ticket. Tell the user
the full path so they can open it. If the user wants the plan kept beyond the
session or shared with others, write it into the repository instead and ask
whether it should be committed or ignored.

Number the implementation steps and the open questions so the user can refer to
them.

### 4. Iterate with the user

Hand over the path and a short summary — the approach in a couple of sentences
and the open questions. Do not paste the whole plan into the conversation; the
file is the artifact.

When the user responds:

- Edit the file in place. Do not start a second plan file or a versioned copy.
- Report what changed in a line or two, not by reprinting the plan.
- When feedback invalidates part of the investigation, redo that part rather
  than patching the conclusion.
- Keep the open questions current: remove them as the user settles them, and add
  new ones as the revisions raise them.

Stop when the user approves the plan. Set its status to Approved.

## Guidelines

- Do not write implementation code during this skill. The plan is the
  deliverable; the user approves it before the work starts.
- Ground every claim in the code or the ticket. Mark anything you inferred but
  did not verify as unverified — a plan's value is that the user can trust its
  findings.
- Surface decisions rather than absorbing them. Where you had to choose, say
  what you chose, what you rejected, and why, so the user can overturn it.
- Prefer the smallest plan that solves the stated problem. Note the adjacent
  work you noticed under Out of scope instead of folding it in.
- Recommend an answer for every open question. A question without a
  recommendation pushes the work back onto the user.
- If the work turns out to be smaller than it looked, say so and offer to just
  do it.
