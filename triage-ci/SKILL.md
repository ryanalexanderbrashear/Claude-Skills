---
name: triage-ci
description: Diagnose a failing CI run — find what actually failed, and say whether it is a real failure, an environment difference, or a suspected flake, with the evidence. Read-only; it does not fix anything. Use when a CI run or PR check is red, when the user asks why a build failed, or whether a failure is a flake.
---

# Triage a failing CI run

Turn a red run into a short verdict with evidence behind it: **real failure**,
**environment-dependent**, or **suspected flake**. A finished result names the
failing step, quotes the handful of log lines that matter, and says which of the
three it is and why.

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

### 3. Check for matrix disagreement first

If some jobs passed and others failed **on the same commit**, that is the most
valuable sentence in the report: the code is the same, so the difference is the
environment. Say which platforms disagreed and what differs between them —
GNU versus BSD userland, a different runtime version, a missing tool.

Do not go further into the logs before saying this. It reframes everything
after it.

### 4. Pull only the failing step's log, and make it readable

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

### 5. Extract the signal, not the log

The useful content is usually three or four lines inside a much larger dump: the
error or assertion, the expected-versus-got, and the summary tally. Quote those.
Do not paste fifty lines of setup echo.

Ignore output that is not from the failing step. A run prints deprecation
warnings and other noise that has nothing to do with why it went red; surfacing
one as the finding sends people the wrong way.

### 6. Check whether it has failed before

```bash
gh run list --workflow <file>.yml --limit 10 --json conclusion,headBranch,createdAt
```

A first-ever failure on a changed file points at the change. The same job failing
intermittently across unrelated branches points at a flake.

### 7. Give the verdict, with its evidence

State one of:

- **Real failure** — an assertion or error caused by the change. Say which.
- **Environment-dependent** — passes somewhere and fails elsewhere on the same
  commit. Say what differs.
- **Suspected flake** — and only with evidence: a prior intermittent failure, or
  a passing rerun. Never call something a flake merely because the cause is not
  obvious.

Say what would confirm the verdict if it is not certain.

### 8. Offer the rerun; do not run it

```bash
gh run rerun "$RID" --failed    # reruns only the failed jobs
```

Give the command and let the user decide. A rerun costs minutes, is the slowest
signal available, and — on a genuine failure — can go green by chance and bury a
real bug.

## Guidelines

- Read-only. Diagnose, report, stop. Do not push a fix as part of triage.
- Never assert "flake" without evidence. Calling a real failure a flake sends
  someone to rerun until green and merge a genuine bug — the most damaging
  mistake this skill can make.
- Say what you could not determine. A truncated log or a cancelled job is a
  fact worth reporting, not a gap to paper over.
- Quote evidence rather than summarising it. "The assertion expected 'yes' and
  got empty" beats "a test failed".

## Notes

**GitHub Actions only**, deliberately, like `address-review`. GitLab pipelines,
CircleCI and Jenkins expose different shapes, and guessing would produce
confident, wrong commands. On another system, say so and stop.

**Annotations are not diagnosis.** GitHub's failure annotation for a failed step
reads `Process completed with exit code 1` and nothing more, and the annotation
list mixes in unrelated warnings. The log is the only place the cause lives.

**`--log-failed` is narrower than `--log`** but still mostly setup noise; step 5
is what turns it into an answer.
