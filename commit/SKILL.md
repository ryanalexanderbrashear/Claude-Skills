---
name: commit
description: Write a commit message for the staged changes — subject in the repo's title format, body explaining why — and commit it non-interactively. Also advises on which commits should exist by the time a PR merges. Use when the user asks to commit, wants a commit message written or improved, or asks how to tidy a branch's commits before merge.
---

# Write the commit

Turn a set of staged changes into a commit whose message still helps someone in
two years. A finished result is a commit whose subject says what changed and
whose body says why, in a form that survives the merge intact.

## When to use

- The user asks to commit staged or unstaged work.
- The user wants a commit message written, improved, or reworded.
- A branch has accumulated review-response commits and needs tidying before it
  merges.

Do not use this to separate work that belongs in different commits — that is
`split-work`, and this skill hands off to it. Do not use it for pull request
titles and descriptions; that is `create-pr`.

## Instructions

### 1. Read what is actually being committed

```bash
git diff --cached --stat     # what is staged
git diff --cached            # the change itself
git status --short           # anything unstaged that was meant to be included
```

Read the diff before writing anything. If the staged set covers several
unrelated concerns, say so and offer `split-work` — one message stretched over
two changes describes neither, and it is the commit nobody can revert cleanly
later.

### 2. Write the subject

Use the same format as a pull request title, so the two agree:

```
<TICKET-ID> - <Descriptor> - <Summary>
```

`docs/pr-template.md` holds the descriptor vocabulary (`Bugfix`, `Feature`,
`Refactor`, `Chore`, …) and the rules. Drop the ticket segment entirely when
there is no ticket rather than inventing a placeholder.

- **Imperative mood** — `Add`, `Fix`, `Remove`, not `Added` or `Fixes`.
- **Describe the change, not the file.** `Fix race in session refresh` beats
  `Update auth.ts`.
- **Keep it to 72 characters.** The format plus a ticket ID costs about 20 of
  those, so the summary itself has to be tight.

### 3. Write the body, when there is a why

A body earns its place when it records something the diff cannot show: the
problem being solved, an approach that was rejected, a constraint that forced an
awkward shape, a finding that came out of testing.

Wrap at 72 columns. Explain *why*, not *what* — the diff already says what.

**Skip the body entirely for a trivial change.** A paragraph of ceremony over a
typo fix is noise, and it trains readers to skim bodies that matter.

### 4. Preserve required trailers verbatim

If the environment mandates attribution trailers — `Co-Authored-By:`, a session
link — they go as the final block after a blank line, copied exactly. Never
paraphrase or reorder them.

### 5. Commit non-interactively

No editor is available, so pass the message on stdin:

```bash
git commit -F - <<'MSG'
Feature - Add the thing

Why the thing needed adding, wrapped at 72 columns.

Co-Authored-By: ...
MSG
```

A bare `git commit` is not an option here. It would also pick up whatever
`commit.template` is configured, which on this machine is an empty file left by
SourceTree.

### 6. Before a PR merges, decide which commits should exist

Under squash merge the subject comes from the PR title and the body is **every
branch commit's message concatenated**, each prefixed `* `. That means branch
commit messages are the permanent record, and so are the review-response commits
among them. A branch with six "address review" commits merges into a body that
reads as a review transcript rather than as the change.

When responding to review on an open PR, prefer fixups:

```bash
git commit --fixup <sha>                                    # marks it for squashing
GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>  # collapses them, no editor
```

**Recommend this; do not do it unprompted.** Autosquashing a pushed branch
rewrites published history — that is `split-work`'s territory, with its rescue
point and its divergence check.

### 7. Say what the merge will look like

Before the PR merges, tell the user what the permanent commit will read as:
the PR title as subject, the concatenated bodies beneath. That is the moment to
decide the current set of commits is the record they want, and it is much
cheaper than deciding afterwards.

## Guidelines

- Read the diff before writing the message. A message written from the task
  description describes the intention, not the change.
- Never claim a change is tested unless the tests were run.
- Do not commit unrelated work together to save a step.
- Match the surrounding history's voice. A repo whose commits are terse prose
  does not want paragraphs, and the reverse.
- If the change is not worth a body, do not write one.

## Notes

**Squash concatenation** was observed on a two-commit branch: the merge commit's
subject was the PR title plus `(#N)`, and its body held both messages in full,
each prefixed `* `. Behavior with many more commits has not been checked here —
if a body looks truncated on a long branch, verify before relying on it.

**This repo's history is mid-migration.** Only the most recent commits use the
title format; earlier ones are plain imperative subjects. That is deliberate —
backfilling merged history for tidiness is all cost and no benefit. New commits
follow the format; old ones stay as they are.
