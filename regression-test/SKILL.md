---
name: regression-test
description: Write a test that pins a bug so it cannot come back — and prove it fails against the broken code before accepting it. Use when a bug has been found or fixed and should be guarded, when the user asks for a regression test or asks whether a fix is covered, or when a defect keeps recurring.
---

# Pin a bug with a test that has been seen to fail

Write the test that stops a defect coming back, and prove it works by watching
it fail for the right reason first. A finished result is a test that has been
red against the broken code and green against the fixed code — not merely a
test that passes.

**A test that has never failed has never been shown to be a test.** It may be
asserting nothing, asserting the wrong thing, or silently skipping. Green is not
evidence; the transition from red to green is.

## When to use

- A bug has been found or fixed and should be guarded against recurrence.
- The user asks for a regression test, or whether a fix is covered.
- A defect has come back, meaning whatever guarded it did not.

Do not use this for general test authoring on a new feature — this skill is
about defects, where a specific thing broke. Do not use it to diagnose a
failing CI run; that is `triage-ci`.

## Instructions

### 1. Start from a reproduction, not a description

If the bug has not been reproduced yet, do that first — `plan-work` covers how.
A test written from a description of a bug tests the description.

### 2. Follow the project's test idiom

Find it before writing anything:

```bash
ls tests/ test/ spec/ 2>/dev/null
ls package.json pytest.ini setup.cfg go.mod Makefile 2>/dev/null
git log --oneline -- tests/ | head        # how tests get added here
```

Match what is there — the directory, the naming, the helpers, the way failures
are reported. A second convention for the sake of a single test costs more than
it gives.

When a project genuinely has no tests, **propose a location and ask** rather
than choosing one silently. That first choice constrains everything added later.

### 3. Write the smallest test that fails because of this defect

One behavior per test. Name it after the defect, not the function under test, so
the failure output says what broke: `a failed copy must not destroy the
installed skill` beats `test_copy_dir`.

### 4. Prove it fails

This is the step that makes it a regression test rather than a hope. Two paths:

**The fix is not written yet** — run the test now and watch it fail.

**The fix already landed**, which is the usual case: restore the broken code
into a scratch copy and run the test there. The working tree is never touched.

```bash
SCRATCH=$(mktemp -d)
cp -R tests "$SCRATCH/"
git show <fix-sha>^:path/to/file > "$SCRATCH/path/to/file"
cd "$SCRATCH" && ./tests/<suite>            # must fail
```

Never skip this because the test "obviously" covers the case.

### 5. Read the failure before believing it

A test can fail from a typo, a missing fixture, a wrong path, or an unset
variable, and that looks exactly like catching the bug. Confirm the assertion
that failed is the one about the defect, and that the message describes the
defect's symptom.

The same applies in reverse: a check that prints nothing may have found nothing,
or may not have run. Confirm which.

### 6. Assert the fixture's own preconditions

A broken fixture passes quietly, which is worse than failing. If the test needs
a commit on a remote, a file with two hunks, or a populated directory, assert
that it is there before asserting anything about the behavior:

```bash
check "fixture: teammate commit is on the remote" "$(...)" "1"
```

If the test depends on the shape of the code — fault injection by matching a
line, say — assert the match applied, and fail loudly with a message telling the
next person to update the test.

### 7. Go green, then run everything

Run the test against the fixed code and confirm it passes. Then run the whole
suite once: a regression test that breaks a neighbour is a net loss.

### 8. Say what is now guarded, and what is not

A regression test covers the path that broke, not the neighbourhood around it.
Say plainly which case is pinned, so nobody reads it as broader coverage than it
is.

## Guidelines

- The deliverable is the red-then-green transition. Reporting "the test passes"
  without having seen it fail is reporting nothing.
- Not every fix deserves a test. A documentation correction, a rename, or a
  comment fix has no behavior to pin — say so instead of manufacturing coverage.
- Prefer one sharp assertion over five vague ones. A test that checks everything
  fails uninformatively.
- Do not weaken an assertion to make a test pass. If the expected value is
  surprising, find out why before changing it.
- Leave the scratch copy behind — clean it up, and never let a proof run write
  into the working tree.

## Notes

**Why the proof matters, from this repo's own history.** The `install.sh`
data-loss suite was written after its fix and, until recently, had never been
run against the broken code. It turned out to be correct — 15 passed, 8 failed
against the pre-fix installer, with the right assertion among the failures — but
nothing in the process had ever established that. It was care, not method.

**Checks that silently prove nothing are common.** A test fixture that created
a branch named `master` while the code pushed `main` produced passing
assertions comparing empty strings. A capability loop written as `cmd $var`
reported everything missing, because zsh does not word-split unquoted
parameters. A width check using `awk '{print length}'` reported violations that
did not exist, because it counts bytes and an em-dash is three. In each case the
output looked like a result.
