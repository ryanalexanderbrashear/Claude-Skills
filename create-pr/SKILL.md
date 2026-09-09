---
name: create-pr
description: Open a pull or merge request for the current branch on GitHub, GitLab, Bitbucket, or Azure DevOps, with the title and description filled in from the branch's own commits using the standard PR template. Use when the user wants to open, create, raise, or draft a PR or MR for the work on the current branch.
---

# Create a pull request

Open a pull request for the current branch on whichever platform the repository
lives on, with a title and description written from the commits that belong to
this branch alone. A finished result is a PR the reviewer can act on without
asking what changed or why — never an empty template.

## When to use

- The user asks to open, create, raise, submit, or draft a PR or MR.
- The user asks to "put this up for review" or "send this to review".

Do not use this for pushing a branch, writing a commit message, or reviewing an
existing PR — do those directly.

## Instructions

### 1. Establish the base branch

The default branch is often but not always `main`. Detect it rather than
assuming:

```bash
git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's@^origin/@@'
# if that prints nothing:
git remote show origin | sed -n 's/.*HEAD branch: //p'
```

Then check whether this branch is stacked on another unmerged branch. Any branch
that is an ancestor of `HEAD` but not of the default branch is a candidate base:

```bash
BASE=<default branch>
CURRENT=$(git branch --show-current)
for b in $(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes); do
  case "$b" in "$CURRENT"|"origin/$CURRENT") continue;; esac
  git merge-base --is-ancestor "$b" HEAD 2>/dev/null || continue
  git merge-base --is-ancestor "$b" "$BASE" 2>/dev/null && continue
  echo "$b"
done
```

If that prints nothing, the default branch is the base. If it prints candidates,
the branch is stacked: the real base is the candidate nearest `HEAD` (the one
whose merge-base with `HEAD` is the most recent commit). Tell the user what you
found and confirm the base before continuing — targeting the wrong base puts
someone else's unmerged commits in this PR.

### 2. Read only this branch's work

```bash
git log --no-merges --reverse "$BASE..HEAD"   # the commits to describe
git diff --stat "$BASE...HEAD"                # scope of the change
git diff "$BASE...HEAD"                       # the change itself
```

Use three dots for diffs: it compares against the merge base, so commits that
landed on the base branch after this one was cut are excluded. Ignore merge
commits from the base branch — they are not this branch's work.

Read the actual diff before writing the description. The commit messages tell
you what the author intended; only the diff tells you what the PR does.

### 3. Draft the title and description

Follow `~/.claude/skills/docs/pr-template.md` (repo path: `docs/pr-template.md`)
for the title format and every section's guidance. If the repository has its own
template — `.github/pull_request_template.md`, `.gitlab/merge_request_templates/`,
or `docs/pull_request_template.md` — that one wins; fill its sections instead.

- **Ticket ID** — take it from the branch name (`feature/SEG-7777-retry-refresh`)
  or from the commit messages. If none is present, ask the user for one; if there
  is genuinely no ticket, drop that segment rather than inventing a placeholder.
- **Descriptor** — infer it from the diff and state your choice to the user.
- **Testing instructions** — derive them from the tests in the diff and from how
  the changed code is actually exercised. Ask the user rather than inventing
  steps you cannot verify, and if the change is untestable, say so and why.
- **Risk, splash zone, related links** — fill from the diff. Leave a section out
  entirely if it does not apply; never ship a heading with `N/A` under it.

### 4. Confirm before creating

Show the user the resolved base branch, the final title, and the full
description. Wait for approval. Do not create the PR until they approve it, and
do not push to a branch that has no upstream without saying so first.

### 5. Push and create

Push the branch, then create the PR with the platform's CLI. Write the
description to a file in the scratchpad and pass it by path — bodies passed
inline break on backticks, quotes, and newlines.

```bash
git push -u origin HEAD
```

| Remote host | Command |
| --- | --- |
| github.com | `gh pr create --base "$BASE" --title "$TITLE" --body-file "$BODY"` |
| gitlab.com or self-hosted GitLab | `glab mr create --target-branch "$BASE" --title "$TITLE" --description "$(cat "$BODY")"` |
| dev.azure.com, visualstudio.com | `az repos pr create --target-branch "$BASE" --title "$TITLE" --description "$(cat "$BODY")"` |
| bitbucket.org | No first-party CLI. Fall back below. |

Identify the host with `git remote get-url origin`. Add `--draft` (`glab`: also
`--draft`) when the user asks for a draft.

If the CLI is missing, unauthenticated, or the host is unrecognised, do not
guess at an API call. Print the finished title and description for the user to
paste, along with the compare URL for their host — for GitHub,
`<repo-url>/compare/<base>...<branch>?expand=1`.

Report the PR URL when it succeeds.

## Guidelines

- Creating a PR is outward-facing and visible to other people. Confirm first,
  every time, even when the user's request was enthusiastic.
- Never open a PR from the default branch. If `HEAD` is the base branch, stop
  and offer to move the commits to a new branch.
- Check for uncommitted changes first and tell the user if the working tree is
  dirty — they may have meant to include that work.
- If `$BASE..HEAD` is empty, there is nothing to open a PR for. Say so.
- Describe what the branch does, not what each commit did. A reviewer reads the
  PR, not the commit log.
- Do not claim a change was tested unless you ran the tests or the user said so.
