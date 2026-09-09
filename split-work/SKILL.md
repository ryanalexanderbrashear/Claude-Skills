---
name: split-work
description: Separate tangled work into coherent commits or branches — uncommitted changes into several commits, one commit into several, or one branch into two — with a rescue point recorded first and the result verified content-identical to the original. Use when the user wants to split a branch, split or separate commits, pull one change out of a mixed batch, or move work onto its own branch.
---

# Split tangled work apart

Separate work that landed together but belongs apart, using destructive commands
in an order that cannot lose anything. A finished result is a split whose pieces
add up to exactly the original content — verified, not assumed — with a rescue
point the user can fall back to.

## When to use

- The user wants a branch split, or one change pulled out of a mixed batch.
- A branch turns out to hold two unrelated bodies of work and needs separating
  before review.
- Uncommitted changes cover several concerns and should become several commits.

Do not use this to squash, reword, or reorder commits — that is `commit`. Do not
use it to split an already-open PR into two PRs; that is a GitHub operation on
top of this one.

## Instructions

### 1. Record a rescue point before touching anything

```bash
git rev-parse HEAD          # the SHA to return to
git branch --show-current
git status --short          # must be clean for destructive modes
```

Print the exact command that undoes everything — `git reset --hard <sha>` — and
keep the SHA for step 6. Nothing destructive happens before this exists.

**Refuse to start a destructive split with a dirty tree.** Uncommitted work has
no reflog: a `reset --hard` destroys changes git has never seen and they are
gone. Ask the user to commit or stash first.

### 2. Classify the split, and confirm the reading

Three shapes, and getting this wrong wastes the user's time:

- uncommitted changes → several commits (step 3)
- one commit → several commits (step 4)
- one branch → two branches (step 5)

### 3. Uncommitted changes into several commits

Stage whole files where the split is file-shaped — it is the common case and the
robust one. When a single file holds two concerns, fall back to hunks, and say
you are doing so:

```bash
git diff -U0 path/to/file > /tmp/all.patch     # -U0 is required, see Notes
# keep only the wanted hunks in the patch, then:
git apply --cached --unidiff-zero /tmp/all.patch
git diff --cached --stat                        # confirm what is staged
```

Commit each group with its own message, then check nothing is left behind.

### 4. One commit into several

```bash
git reset --soft HEAD~1     # keeps the changes staged, drops the commit
git restore --staged <paths-for-the-second-commit>
git commit -m "first concern"
git add <those paths>
git commit -m "second concern"
```

For a commit further back, do not reach for interactive rebase — it needs an
editor and cannot run here. Cherry-pick the commits after it onto a fresh
branch instead.

### 5. One branch into two

```bash
BASE=main
git log --format='%H %s' "$BASE..HEAD"          # choose by SHA or subject
git checkout -B only-x "$BASE"
git cherry-pick <sha> <sha>                      # oldest first; no -q flag exists
```

**Select commits by SHA or subject, never by position.** `git log` is
newest-first and an off-by-one in a `tail`/`head` pipeline picks the wrong
commit silently.

Stop and hand back on a cherry-pick conflict rather than resolving it silently —
tangled work is why this skill was called, so conflicts are expected, and the
user should see them.

### 6. Verify the pieces add up to the original

```bash
git diff <rescue-sha> HEAD          # must print nothing
```

For a pure split the final tree must be identical to the original. Anything
printed here means content was lost or invented. Stop, show the difference, and
do not offer to push.

When the split produced two branches, check the union: apply both and compare,
or verify each commit is accounted for with
`git log --format=%H "$BASE..<each branch>"`.

### 7. Only then touch the remote

Check divergence **before** any fetch, and do not use `@{upstream}` to do it —
that is the remote-tracking ref, which is stale by definition and will show
nothing. Read the remote directly with `ls-remote`, which does not update the
tracking ref:

```bash
BRANCH=$(git branch --show-current)
REMOTE_SHA=$(git ls-remote origin "refs/heads/$BRANCH" | awk '{print $1}')
LOCAL_SHA=$(git rev-parse "origin/$BRANCH")
[ "$REMOTE_SHA" = "$LOCAL_SHA" ] || echo "remote has moved: $REMOTE_SHA"
```

If those differ, someone else has pushed — stop and tell the user what would be
overwritten. Confirm before pushing, name the branch, and never force onto the
default branch.

```bash
git push --force-with-lease
```

Treat the lease as a backstop, not as the check. See Notes.

### 8. Clean up knowingly

If `git branch -d` refuses on a branch you believe is merged, diagnose before
forcing. The usual cause is a rewritten branch whose tracking ref still holds
the pre-rewrite commit. Confirm the content is genuinely present in the target —
`diff <(git show <branch>:<file>) <(git show <target>:<file>)` or compare trees —
and only then use `-D`. Never force-delete on the strength of the refusal alone.

## Guidelines

- This skill exists to run destructive commands. Confirm before each one that
  reaches a remote or discards local state, and say what would be lost.
- Never start with a dirty tree in a destructive mode.
- Report conflicts and stop; do not resolve someone's tangled history silently.
- If the split turns out to be unnecessary — the work really is one concern —
  say so instead of manufacturing a division.

## Notes

**`--force-with-lease` is weaker than it looks, and fetching makes it weaker.**
The lease compares the remote against your *remote-tracking ref*, so `git fetch`
updates the very value being checked. Verified: with a stale tracking ref the
force push is rejected with `stale info`; after a plain `git fetch` the same
push succeeds and destroys the other person's commit. "Fetch first to be safe"
is exactly backwards, and so is checking `@{upstream}`: both read or refresh the
very ref the lease compares against. `git ls-remote` reads the remote without
touching the tracking ref, which is why step 7 uses it. `tests/split-work-test.sh`
group 5 proves both halves — the trap, and that `ls-remote` catches it.

**Interactive git is unavailable.** `git rebase -i` and `git add -p` need an
editor or a TTY. The equivalents above are the substitutes; for a fixup chain,
`GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash` runs without an editor.

**`--unidiff-zero` is mandatory when staging hunks.** `git apply --cached` on a
`-U0` patch fails without it. And `-U0` itself is required to split at all:
with default context, two edits a few lines apart merge into a single hunk that
cannot be separated.
