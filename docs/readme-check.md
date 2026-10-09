# Checking the README against a finished change

A small audit, scoped to one branch. It runs when a piece of work is finished and before its pull
request is opened. Used by `create-pr`, which runs it, and by `plan-work`, which names the passages
up front.

## Why after every change, and why only this much

A README goes stale one merged change at a time. Each change is small, nobody re-reads the README
for it, and the drift only shows when someone runs a command that no longer works. A full audit
catches it all at once, and costs a session. Checking each change against the README costs a few
greps, because the diff already says which names moved.

So this is bounded by the diff, not by the README. Do not read the README end to end here. A
change that touches nothing the README names finishes in under a minute, and that is the common
case.

## The documents in scope

The `README.md` at the repository root, plus any hand-written document the repository's own
instructions (`CLAUDE.md`, `CONTRIBUTING.md`) say describes how to run, use or develop it. Skip
generated documents. Their drift is a generator's job, and usually a CI check's.

## 1. List what the change renamed, removed, added or finished

From `git diff --stat "$BASE...HEAD"` and the diff itself, write down the names a reader of the
README might meet:

- **Files and directories** added, removed or renamed (`git diff --name-status "$BASE...HEAD"`).
- **Commands:** package scripts, Makefile targets, CLI subcommands and flags.
- **Configuration:** environment variables, config keys, ports, defaults and limits.
- **Interfaces:** routes, response shapes, error codes, and the names of roles or permissions.
- **The ticket the branch closes**, and any item number it carries. "Until item 12" and "not yet"
  passages are the most common drift, and they go stale on the day that item ships.

## 2. Search for each, and read only what matches

```bash
grep -n -i -e '<name>' -e '<another>' README.md
```

**First, make the search find something you know is there**, such as a heading. A search that
matches nothing looks exactly like a README that never mentions the change.

For each hit, read its paragraph and ask whether it is still true after this branch. Watch for
the kinds of claim that rot without anyone touching them:

- **Counts:** "three roles", "exactly two functions", "the only endpoint".
- **Examples of output:** a response body, a log line, a printed summary.
- **Measured figures:** timings, sizes, row counts. Re-measure, or date them.
- **Statements about the future:** "not yet", "until #N", "arrives in item N", "will be".

Then ask the converse once: **does the README list things like the one this branch added?** If it
lists the scripts, the environment variables or the routes, a new one belongs on the list.

## 3. Run only the commands the change affects

If a README command invokes something the diff changed, run it and compare its output with what
the README says it prints. Leave the other commands alone. Running all of them is the full audit,
which is a separate piece of work.

## 4. Fix it on the branch, or file it

- **Caused by this branch:** fix it on the branch, as its own commit (`Docs - …`), so the README
  and the change land together.
- **Older drift you happened to see:** file it with `file-issue` rather than widening the branch.
  Several unrelated findings at once usually mean the README needs a full audit. File that as one
  issue.

## 5. Say what was checked

Put one line in the pull request description, under Testing instructions, so a reviewer can see
the check happened and how far it went:

> README: searched for `seed-world`, `--images`, `#311`; updated "Seeding a world"
> (output summary and timing).

> README: searched for `MAX_UPLOAD_BYTES`, `/assets`; nothing in it describes them.

"Nothing to update" is a fine result. Not saying is not, because a check nobody reports is
indistinguishable from one that never ran.
