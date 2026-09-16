---
name: file-issue
description: Files a bug report or work item in the project's tracker — GitHub, GitLab, JIRA, Linear or whatever the repo actually uses — with the report in the reporter's words, the cause traced or explicitly unknown, and a reproduction. Use when the user reports a bug, says "file this", "open a ticket", "raise an issue", or when work is discovered that will not be done now and would otherwise be lost.
---

# File an issue

Turn something noticed into something tracked. A finished result is an issue in
the project's real tracker that a stranger can act on in six months, linked back
to whoever needs it.

Untracked work does not exist. If it is worth mentioning, it is worth a ticket;
if it is not worth a ticket, say so rather than filing noise.

## When to use

- The user reports a bug, or one surfaces while doing something else.
- Work is discovered that will not be done now: a gap, a follow-up, a deferred
  decision, a `TODO` worth more than a comment.
- The user says "file this", "open a ticket", "raise an issue", "track this".
- A plan's Out of scope section names something that needs a follow-up.

Do not use this to write an implementation plan — that is `plan-work`, which
runs *after* the issue exists and reads it as input. Do not use it to triage a
failing CI run; that is `triage-ci`.

## Instructions

### 1. Find the tracker, do not assume it

The tracker is a property of the project, not of the host. A repository on
GitHub may track its work in JIRA, and filing in the wrong place is worse than
not filing at all — nobody sees it and everybody believes it is tracked.

Look, in this order, and stop at the first answer:

- `CONTRIBUTING.md`, `README.md`, `CLAUDE.md`, `.github/ISSUE_TEMPLATE/`, or a
  docs folder that names where issues go.
- The last twenty commit subjects and merge commits: a `PROJ-1234` prefix says
  JIRA, a `#123` says the forge's own issues.
- Configured CLIs and MCP tools actually available in this session — `gh`,
  `glab`, a JIRA or Linear integration.

If two sources disagree, or none answers, **ask**. One question costs less than
an issue filed where nobody will look.

### 2. Collect the report before diagnosing it

Write down the symptom in the reporter's own words first, and keep them.
"A set list of entries shows up on entering `[[`" is the sentence someone
recognises six months later; "the endpoint ignores `q`" is not — it is a
diagnosis, and if the diagnosis turns out to be wrong the issue becomes
unsearchable as well as misleading.

Then establish, and mark clearly which is which:

- **Reproduction** — the smallest steps that trigger it, with real values.
  Reproduce it if you can. An issue whose repro has been run is worth several
  that have not.
- **Cause** — traced to `path/to/file.ts:42`, or an explicit "cause not yet
  established". **Never guess a cause in an issue.** The next person believes
  it, and a wrong cause costs more than an absent one.
- **Impact** — who hits it, how often, what it blocks.
- **Environment** — version, platform, browser, region, whatever varies.

### 3. Decide what kind of thing it is

- **A defect** — something is broken against its own stated intent.
- **A gap** — nothing is broken, but a guard cannot catch a class of mistake, or
  a capability is missing. Say plainly that it is about the guard, so nobody
  hunts for a symptom that does not exist.
- **Work** — a planned unit with a done-condition that fits in a sentence.

Say which in the issue. A gap filed as a bug sends someone looking for a
reproduction that will never happen.

### 4. Write it

Title: specific enough to be recognised in a list of fifty. Lead with the
observable behaviour, not the suspected cause. Match the project's existing
title convention exactly — prefix, ticket key, capitalisation — by reading the
last few issues rather than inventing one.

Body, in this order: the report in the reporter's words; the reproduction; the
cause or an explicit statement that it is unknown; the impact; and where the
fix will live if that is already known.

Apply the labels, component, milestone and assignee the project already uses.
Link related issues, the PR that introduced it if you know it, and any plan
document.

### 5. File it, then hand back the link

Filing is outward-facing: it notifies people and it is visible to everyone with
access. **Show the user the title and body and confirm before creating it**,
unless they have already said to file without asking.

Create it with the tracker's own CLI or integration, then give the user the URL
and the identifier. If the work continues immediately, reference that identifier
in the branch name, the commits and the pull request, so the trail closes by
itself.

## Guidelines

- **One issue per thing.** Two defects in one ticket means one of them is never
  fixed, because the ticket closes when the louder one does.
- **A bug is not always a work item.** A one-line fix is a pull request that
  closes the issue. Only a fix whose *shape* is a decision earns a plan and a
  number of its own.
- Write for a stranger in six months, including when that stranger is the user.
  Spell out acronyms, paste the error text, name the file.
- Never put credentials, tokens, customer data or personal data in an issue —
  most trackers are readable by more people than the repository is. Redact and
  say that you redacted.
- If the thing is already filed, say so and link it rather than filing a
  duplicate. Search before creating.
- If it is too small to track, say that plainly and offer to just fix it.
