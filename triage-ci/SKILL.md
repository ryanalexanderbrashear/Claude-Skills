---
name: triage-ci
description: Diagnose a failing CI run — find what actually failed, and say whether it is a real failure, an environment difference, a stale base, a run that never started, or a suspected flake, with the evidence. Read-only; it does not fix anything. Use when a CI run or PR check is red, when the user asks why a build failed, or whether a failure is a flake.
---

# Triage a failing CI run

Turn a red run into a short verdict with evidence behind it: **real failure**,
**environment-dependent**, **stale base**, **never started**, or **suspected
flake**. A finished result names the failing step, quotes the handful of log lines
that matter, and says which of the five it is and why.

Two of those five are red without anything being wrong with the code, and both are
cheap to spot before reading a log — steps 2 and 4.

This skill diagnoses. It does not fix, does not rerun on its own, and does not
write the test — that is `regression-test`, once the cause is known.

## When to use

- A CI run or PR check is red and the user wants to know why.
- The user asks whether a failure is real or a flake.
- A check failed and the log is too long to read.

Do not use it to fix the failure, and do not use it to interpret a *passing*
run. GitHub Actions only; see Notes.

## Instructions

### 1. Find the run

Default to the most recent run for the current branch; accept a run ID, PR
number, or URL. If there is no run, say so rather than guessing.

```bash
gh run list --branch "$(git branch --show-current)" --limit 1 \
  --json databaseId,status,conclusion,workflowName
```

### 2. Read the shape before the logs

This is fast and is often enough to classify the failure on its own.

```bash
gh run view "$RID" --json status,conclusion,jobs -q '"\(.status)/\(.conclusion)"'
gh run view "$RID" --json jobs -q '.jobs[] | "  \(.name): \(.conclusion)"'
gh run view "$RID" --json jobs \
  -q '.jobs[] | .name as $j | .steps[] | select(.conclusion=="failure") | "\($j) -> step \(.number) \(.name)"'
```

**A failed job that lists no failing step never ran.** The third command printing
nothing while the job says `failure` is the tell, and two more confirm it: the job
lasted seconds, and `--log-failed` answers `log not found`.

```bash
gh api "repos/$OWNER/$REPO/actions/runs/$RID/jobs" \
  -q '.jobs[] | "\(.name) \(.conclusion) \(.started_at)->\(.completed_at) steps=\(.steps | length)"'
```

`steps=0` over a two-second span means the run was refused before any of the
workflow executed — exhausted billing or spending limit, a disabled workflow, a
missing runner label, a permissions block. **Stop here and say so.** There is no
failure in that log to find, and the same PR can sit red for hours looking like a
test failure that never happened. Check whether *other* branches ran successfully
in the meantime: if they did, the block has since cleared and the run needs
repeating rather than diagnosing.

### 3. Check for matrix disagreement first

If some jobs passed and others failed **on the same commit**, that is the most
valuable sentence in the report: the code is the same, so the difference is the
environment. Say which platforms disagreed and what differs between them —
GNU versus BSD userland, a different runtime version, a missing tool.

Do not go further into the logs before saying this. It reframes everything
after it.

### 4. Check whether the base has moved under the branch

A pull request that waited while others merged fails for reasons its own diff
cannot explain. Two numbers settle it, and both are cheaper than reading a log:

```bash
BASE=$(gh pr view --json baseRefName -q .baseRefName)
git fetch -q origin "$BASE"
git rev-list --count "HEAD..origin/$BASE"    # commits the branch is missing
```

A non-zero count plus a failing step that **regenerates something and compares**
is a stale base. The shape to recognise is a step that runs a generator and then
`git diff --exit-code`, or a check against a stored floor — a coverage ratchet, a
bundle-size budget, a lockfile. Those fail because the base moved, not because the
branch is wrong, and they print the command that fixes them, so quote that line
instead of diagnosing the generator.

**Do not reach for "the branch didn't touch that file" as the test** — it is
wrong in exactly the repositories that have these checks. A branch that regenerated
a doc or raised a floor when it was opened *does* contain that file, and it still
goes stale the moment something else merges. The distance from the base is the
signal; the file list is not.

### 5. Pull only the failing step's log, and make it readable

```bash
JID=$(gh run view "$RID" --json jobs -q '.jobs[] | select(.conclusion=="failure") | .databaseId')
gh run view --job "$JID" --log-failed \
  | sed 's/\^\[\[[0-9;]*m//g' \
  | sed 's/^\([^	]*\)	\([^	]*\)	[0-9T:.Z-]*Z /[\2] /'
```

**The colour codes are literal caret notation, not ESC bytes.** GitHub's log API
returns them already converted, so `sed 's/\x1b\[...'` and
`perl -pe 's/\e\[...'` both match nothing and pass the text through unchanged,
looking like they worked. Use the literal `\^\[\[` form above.

**Confirm the filter actually changed something** — compare a line before and
after. A no-op filter is indistinguishable from a clean log.

### 6. Extract the signal, not the log

The useful content is usually three or four lines inside a much larger dump: the
error or assertion, the expected-versus-got, and the summary tally. Quote those.
Do not paste fifty lines of setup echo.

Ignore output that is not from the failing step. A run prints deprecation
warnings and other noise that has nothing to do with why it went red; surfacing
one as the finding sends people the wrong way.

### 7. Check whether it has failed before

```bash
gh run list --workflow <file>.yml --limit 10 --json conclusion,headBranch,createdAt
```

A first-ever failure on a changed file points at the change. The same job failing
intermittently across unrelated branches points at a flake.

### 8. Give the verdict, with its evidence

State one of:

- **Real failure** — an assertion or error caused by the change. Say which.
- **Environment-dependent** — passes somewhere and fails elsewhere on the same
  commit. Say what differs.
- **Stale base** — the branch is behind its base and the failing step compares
  against something regenerated or stored. Say how many commits behind, and that
  the fix is a rebase rather than a code change — noting that the rebase itself
  will usually conflict on the generated file, since both sides regenerated it,
  and the conflict is resolved by regenerating on the new base rather than by
  choosing a side.
- **Never started** — the job reports failure with no steps and no log. Say what
  blocks a run from starting, and that nothing was tested.
- **Suspected flake** — and only with evidence: a prior intermittent failure, or
  a passing rerun. Never call something a flake merely because the cause is not
  obvious.

Say what would confirm the verdict if it is not certain.

The middle two look like flakes and behave nothing like them: a flake may pass on
a rerun, a stale base fails identically every time until the branch moves, and a
run that never started will keep not starting until whatever refused it changes.

### 9. Offer the rerun; do not run it

```bash
gh run rerun "$RID" --failed    # reruns only the failed jobs
```

Give the command and let the user decide. A rerun costs minutes, is the slowest
signal available, and — on a genuine failure — can go green by chance and bury a
real bug.

A rerun is the right suggestion for exactly one verdict: a run that never started,
once the thing that refused it has cleared. It cannot clear a stale base, because
the rerun tests the same commits against the same moved base.

## Guidelines

- Read-only. Diagnose, report, stop. Do not push a fix as part of triage.
- Never assert "flake" without evidence. Calling a real failure a flake sends
  someone to rerun until green and merge a genuine bug — the most damaging
  mistake this skill can make.
- Say what you could not determine. A truncated log or a cancelled job is a
  fact worth reporting, not a gap to paper over.
- **A missing log is a finding, not an obstacle.** `log not found` on a job that
  failed in seconds is the answer, and reading it as a tooling problem to work
  around sends someone looking for a failure that was never produced.
- Quote evidence rather than summarising it. "The assertion expected 'yes' and
  got empty" beats "a test failed".

## Notes

**GitHub Actions only**, deliberately, like `address-review`. GitLab pipelines,
CircleCI and Jenkins expose different shapes, and guessing would produce
confident, wrong commands. On another system, say so and stop.

**Annotations are not diagnosis.** GitHub's failure annotation for a failed step
reads `Process completed with exit code 1` and nothing more, and the annotation
list mixes in unrelated warnings. The log is the only place the cause lives.

**`--log-failed` is narrower than `--log`** but still mostly setup noise; step 6
is what turns it into an answer.
