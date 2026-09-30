---
name: start-project
description: Create the GitHub milestones, issues and blocked-by dependency graph for an approved project plan, verify the graph reads back, and set the repository options that are invisible until they bite. Use when an approved plan's work breakdown needs to exist in the tracker, when someone asks to set up milestones or issues for a project, or straight after plan-project.
---

# Start a project from its plan

Take a project plan the user has approved and make it real in a tracker: milestones,
one issue per work item, the dependency edges between them, verified by reading the
graph back. A finished result is a tracker that can answer "what is next" without
anyone consulting the plan document again.

This skill does not scaffold a codebase — no `package.json`, no CI, no database. What
a project is built with is its own decision, and `/init` owns `CLAUDE.md`.

## When to use

- `plan-project` has produced a plan and the user has approved it.
- The work breakdown exists only in a document and needs to be tracked.
- The user asks to set up milestones or issues for a project.

Do not use it to file one piece of work — that is `file-issue`. Do not use it to
re-plan; if the plan is wrong, fix the plan first. GitHub only; see Notes.

## Instructions

### 1. Establish the repository, and stop if there is not one

```bash
git rev-parse --show-toplevel                      # a repository at all?
gh repo view --json nameWithOwner,defaultBranchRef -q '.nameWithOwner'
```

If either fails, say what is missing and offer the two commands rather than running
them unasked — `git init -b main` and `gh repo create <name> --source=. --private`.
Creating a remote is one command and needs no skill; it needs the user's decision
about name and visibility.

Read the plan file before anything else. If the user has not named one, find it
rather than guessing at its contents.

### 2. Read the plan's own numbering, and do not invent any

`plan-project` writes a work-item table:

| # | Work item | Milestone | Depends on | Status |
| --- | --------- | --------- | ---------- | ------ |

Those item numbers are the plan's identifiers. They are **not** issue numbers and
will not match them — the tracker assigns its own, and the repository may already
have issues. Keep the plan's numbers as a key for step 4 and nothing else.

Parse and echo what you read — items, milestones, and dependency edges, with counts —
and have the user confirm before creating anything. An issue created from a
misparsed row costs more to unpick than to re-read.

### 3. Create the milestones, then the issues

Milestones first: an issue cannot reference one that does not exist.

```bash
gh api "repos/$OWNER/$REPO/milestones" -f title="M1 — <outcome>" -f description="<outcome, and what it retires>"
gh issue create --title "<item>" --body "<done-condition and scope>" --milestone "M1 — <outcome>"
```

Give each milestone its **outcome** as the description, not a restatement of its
name. The description is what a reader sees months later when deciding whether a new
issue belongs to it.

**Record the mapping from plan item number to created issue number as you go.**
Step 4 cannot be done without it, and it cannot be reconstructed afterwards from
titles alone once two items have similar names.

A bug or an item with no milestone gets its label and no milestone. Work the plan did
not foresee is not work the plan scheduled.

### 4. Wire the dependencies as a second pass

**This is the step with the trap.** Dependencies can only be resolved after every
issue exists, because the numbers do not exist until then. Resolve each `Depends on`
entry through the step 3 mapping — never by assuming item *N* is issue *N*.

```bash
gh issue edit "$ISSUE" --add-blocked-by "$BLOCKER"     # numbers or URLs
```

Item 1 is rarely issue 1: the repository may already hold issues, numbering is shared
with pull requests on GitHub, and a failed creation leaves a gap. An off-by-anything
here attaches an edge to a real but unrelated issue, so it produces no error and
reads as a correct graph.

### 5. Read the graph back and compare it to the plan

```bash
gh issue list --limit 200 --json number,title,milestone --jq \
  '.[] | "\(.number)\t\(.milestone.title // "-")\t\(.title)"'
gh issue view "$ISSUE" --json number,blockedBy,blocking
```

Compare edge for edge against the table, and report the counts: milestones created,
issues created, edges created, edges read back. **Equal counts are the claim; say
the numbers rather than saying it worked.** A graph is wired once and consulted for
months, and a wrong edge misleads every scheduling decision made from it.

Only once the comparison holds should the plan's table be retired — see step 7.

### 6. Set the two repository settings that are invisible until they bite

```bash
gh repo edit --delete-branch-on-merge
gh api -X PUT "repos/$OWNER/$REPO/branches/main/protection" --input protection.json
```

- **Delete head branches on merge.** Without it, every merged branch stays forever.
  One project reached 131 stale remote branches before anyone noticed, and clearing
  them afterwards took a verified `git cherry` pass over every one.
- **Branch protection**, if the user wants it: confirm first, and say what it will
  refuse, because it can lock the user out of their own default branch on a
  one-person project.

Both are one-line settings whose absence costs cleanup months later. Ask about
protection; just do the branch deletion, and say you did.

### 7. Point the plan at the tracker, and stop maintaining the table

The plan's work-item table has done its job. Leaving it in place creates a second
copy of tracker state that nothing updates as a consequence of the work, and it will
disagree within weeks — the tracker is updated by doing the work, the table by
remembering to.

Replace the table with a line saying where the work now lives, and keep everything in
the plan that the tracker cannot hold: the goal, the success criteria, the milestone
reasoning, the risks, the non-goals. Those are why the project is shaped as it is,
and no issue holds them.

Then report what exists, and name the first item the user can start on.

## Guidelines

- Confirm the parse before creating anything, and confirm before branch protection.
  Everything else here is additive and safe to do.
- Never assume a plan item number is an issue number.
- Report counts, not adjectives. "9 milestones, 99 issues, 121 edges, 121 read back"
  is the result; "set up the tracker" is not.
- Create nothing on a partial read. If the plan's table is malformed or its
  dependencies name items that do not exist, say which rows and stop.
- Prefer the tracker's own features over a convention in text. A milestone, a label
  and a dependency edge are queryable; "blocked by item 4" in a body is not.

## Notes

**GitHub only**, deliberately, like `address-review` and `triage-ci`. Milestones,
issue dependencies and branch settings differ across GitLab, Jira and Linear, and
guessing would produce confident, wrong commands. On another tracker, say so and stop.

**Issue dependencies need a recent `gh`.** `--add-blocked-by` and `--add-blocking`
on `gh issue edit`, and `blockedBy` / `blocking` on `gh issue view --json`, are what
this skill relies on; verified on `gh` 2.100.0. Check with
`gh issue edit --help | grep blocked` before a long run rather than after it.

**A rate limit looks like a failure halfway through.** Creating a hundred issues is a
hundred API calls. If creation stops partway, the mapping recorded in step 3 is what
makes resuming possible instead of starting over — which is the other reason to keep
it as you go rather than reconstructing it at the end.
