# Putting a work breakdown into a tracker

Three passes, in this order. The order is not a preference — each pass needs what the
one before it created.

1. **Create the milestones.** A ticket cannot name a milestone that does not exist.
   Give each one its **outcome** as the description rather than a restatement of its
   name; that is what a reader sees months later when deciding whether a new ticket
   belongs to it.
2. **File every ticket**, with its milestone, and **note which ticket number each item
   became.** That note is the only thing that makes pass 3 possible, and the only
   thing that makes a run interrupted halfway resumable rather than restartable —
   filing thirty tickets is thirty API calls, and a rate limit looks like a failure.
3. **Link the dependencies**, from that note.

## Why linking cannot happen during pass 2

A dependency cannot name a ticket that does not exist yet, so linking as you file works
only while every blocker happens to already be filed.

A plan is ordered by milestone, not by dependency. A blocker filed *after* the thing it
blocks is therefore ordinary — in the project this rule came from, two tickets are
blocked by an item three milestones earlier in the sequence but filed later. Linking as
you go omits exactly those edges, and they are the ones that cross a boundary, which
makes them the ones worth knowing about.

Nothing reports the omission. The edge is simply absent.

## Never resolve a dependency by arithmetic

**Item *N* is almost never ticket *N*.** GitHub shares issue numbering with pull
requests and continues from whatever the repository already holds, and a failed
creation leaves a gap.

So `Depends on: 1` resolved as "ticket 1" names a **real but unrelated ticket**. The
API accepts it, nothing errors, and the resulting graph reads as correct while
misleading every scheduling decision made from it. Resolve every edge through the note
from pass 2.

## The commands

```bash
gh api "repos/$OWNER/$REPO/milestones" -f title="M1 — <outcome>" -f description="<outcome>"
gh issue create --title "<item>" --body "<done-condition and scope>" --milestone "M1 — <outcome>"
gh issue edit <ticket> --add-blocked-by <blocker>        # numbers or URLs
gh issue view <ticket> --json number,blockedBy,blocking
gh issue list --limit 200 --json number,title,milestone
```

`--add-blocked-by` / `--add-blocking` on `gh issue edit`, and `blockedBy` / `blocking`
on `gh issue view --json`, are what pass 3 needs. Verified on `gh` 2.100.0; check with
`gh issue edit --help | grep blocked` before a long run rather than after it.

GitHub only. Milestones and issue dependencies differ across GitLab, Jira and Linear,
and guessing produces confident, wrong commands — on another tracker, set what it does
offer and say what it could not express.

## Read the graph back

Compare it against the breakdown that was agreed, and report counts: milestones
created, tickets filed, edges intended, edges read back.

**Equal counts are the claim — say the numbers rather than saying it worked.** A graph
is wired once and consulted for months, and a wrong edge produces no error at any
point.
