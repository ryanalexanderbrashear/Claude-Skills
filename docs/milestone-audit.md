# Auditing a milestone

The check that runs when a milestone's last item merges, before the next one starts.
Used by the `plan-project` skill, which schedules it as part of the milestone
sequence rather than leaving it to be remembered.

## Why it is not a review of the work items

Every item being marked done is the weakest possible evidence that a milestone's
outcome is real. It says the work someone thought of got done — which is a
statement about the plan, not about the system. A breakdown written from a goal
enumerates **nouns**: the things that will exist. The **verbs** — rename, delete,
page, undo, re-type, export — are invisible in a breakdown and obvious after five
minutes of use.

So: open the application, run the command, call the API. The findings that matter
come from use.

## The three questions

1. **Does the milestone's outcome sentence hold of the running system?** Not "is
   every item merged". If the outcome cannot be checked this way, that is itself a
   finding — an outcome was supposed to be checkable from the outside.
2. **What is missing that nobody wrote down?** This is where the value is. Try the
   ordinary things a user would do next: make a second one, correct a mistake,
   remove something, find something in a large set, undo.
3. **Does the plan now describe anything wrongly?** Code moves and plans do not.
   A plan people trust that disagrees with the code is worse than no plan. Fix it
   in the same pass.

## Recording it

Put the verdict **where the milestone is**, so a reader meets it beside the promise.
A few lines in the milestone section is usually right; link to a fuller document
when the findings need one.

Then **schedule what it found as numbered work items**, noting that they came from
the audit. A finding that lands in a document and not in the breakdown is a finding
nobody will action.

## The failure mode

**An audit that finds nothing usually means the milestone was re-read rather than
used.** Zero findings is possible, but it is the least likely outcome and the
easiest to produce by accident. Say plainly that the walk turned nothing up, and
what was actually exercised, rather than reporting a clean bill.
