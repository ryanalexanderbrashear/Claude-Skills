# Pull Request Template

Guidelines for writing a pull request, followed by a copy-paste template.

A PR is read by someone who does not have the context you have right now — a
reviewer today, or whoever runs `git blame` on this line in two years. Write for
them. Every section below exists to answer a question that person will ask.

---

## Title guidelines

The title is the line that survives. It shows up in the commit log, release
notes, and search results long after the PR page stops being read.

**Format:**

```
<TICKET-ID> - <Descriptor> - <Summary of the change>
```

```
SEG-7777 - Bugfix - Fix for the crashing issue
```

Three parts, separated by a spaced hyphen, in that order.

### Ticket ID

- **Use the full identifier** — workspace prefix plus number — exactly as the
  tracker writes it: `SEG-7777` is ticket 7777 in the SEG workspace. This makes
  the PR auto-link in JIRA and makes the log greppable by workspace.
- **No ticket?** Drop the segment entirely and lead with the descriptor
  (`Docs - Correct the install path in the README`). Do not invent a
  placeholder such as `NO-TICKET`, `N/A`, or an empty bracket.

### Descriptor

A single word naming the *kind* of work, so a reader scanning the log can tell
a risky change from a routine one without opening it. Pick the one that
describes the bulk of the diff — if a PR is genuinely two kinds of work, that is
usually a sign it should be two PRs.

| Descriptor | Use for |
| --- | --- |
| `Bugfix` | Correcting behavior that was wrong |
| `Hotfix` | An urgent production fix, usually shipping outside the normal release |
| `Feature` | New user-facing capability |
| `Enhancement` | Extending or improving something that already exists |
| `Refactor` | Restructuring with no intended change in behavior |
| `Perf` | Changes made for speed, memory, or cost |
| `Test` | Adding or repairing test coverage only |
| `Docs` | Documentation, comments, READMEs |
| `Chore` | Build, tooling, CI, formatting, dependency bumps |
| `Config` | Environment, flags, or infrastructure settings |
| `Revert` | Backing out a previous change |
| `Spike` | Exploratory or proof-of-concept work not meant to ship as-is |

Capitalize it as written above, and keep the vocabulary closed — an invented
descriptor defeats the point of having one.

### Summary

- **Describe the change, not the file.** `Fix race condition in session refresh`
  beats `Update auth.ts`.
- **Prefer the imperative**, as if completing "This PR will…": `Add`, `Fix`,
  `Remove`, `Refactor` — not `Added`, `Fixes`, `Fixing`.
- **Do not restate the descriptor.** `Bugfix - Bug fix for the login bug` wastes
  the whole line.
- **Keep the full title under ~80 characters** so it is not truncated in list
  views. The ticket and descriptor consume roughly 20 of those, so the summary
  itself should stay short. Detail belongs in the description, not the title.
- **Mark work that is not ready** with a `Draft` PR, or prefix `WIP:` if drafts
  are unavailable.

**Good:**

```
SEG-7777 - Bugfix - Retry token refresh on 401 instead of logging out
SEG-1042 - Chore - Remove the unused legacy invoice exporter
SEG-0311 - Feature - Add CSV export to the billing dashboard
Docs - Correct the install path in the README
```

**Avoid:**

```
Bug fix                                — which bug? no ticket, no summary
SEG-7777                               — ticket number with no descriptor or summary
SEG-7777 - Fix the crash               — missing the descriptor
SEG-7777 - Bugfix - Bug fix            — summary restates the descriptor
SEG-7777 - Stuff - Updates per review  — invented descriptor, describes the process
```

---

## Description

Explain **what changed** and, more importantly, **why**. The diff already shows
the what; only you can supply the why.

Cover, in this order:

1. **Why this change exists.** The problem, bug, or need being addressed. If a
   ticket exists, source this from the ticket rather than paraphrasing from
   memory — pull the actual reported symptom or the stated goal, and link the
   ticket so the reviewer can read the full context.
2. **What the change does.** A short walkthrough of the approach at the level of
   behavior, not line-by-line narration. Name the key files or modules a
   reviewer should look at first.
3. **Why this approach.** Any decision a reviewer might question: an alternative
   you considered and rejected, a tradeoff you accepted, a constraint that
   forced your hand. This is where you preempt the review comment.
4. **What is deliberately not here.** Scope you left out on purpose, with a
   follow-up ticket if one exists. Prevents "you forgot to also…" comments.

Guidelines:

- Write prose in full sentences. A bare bullet list of file names is not a
  description.
- Link the ticket, and any design doc, incident, or prior PR that gives context.
- Call out anything surprising in the diff — a large unrelated-looking rename, a
  dependency bump, a generated file — before the reviewer has to ask.
- If the change is user-visible, say what the user will now see or experience.

---

## Screenshots / recordings

If the change is visible to a user, show it. A reviewer catches a wrong-looking
result in a screenshot faster than in any description of it.

- **Before and after, side by side**, for changes to existing UI. A single
  "after" image hides regressions — the reviewer cannot tell what moved.
- **A short recording** for anything interactive: a multi-step flow, an
  animation, a drag interaction, an error state that appears and clears.
- **Cover the states that are easy to forget** — empty, loading, error, long
  text, and the narrowest supported viewport. Dark mode, if the product has one.
- **Annotate** when the change is subtle. An arrow or a box beats a paragraph
  explaining where to look.
- **Not user-visible?** Omit this section entirely rather than writing "N/A".

---

## Testing instructions

Tell the reviewer how to convince themselves this works.

- **Give reproducible steps**, numbered, starting from a clean state. Include
  the setup a reviewer would not guess: required env vars, seed data, feature
  flags to enable, which account or role to use.
- **State the expected result** at each step, not just the actions. "Click Save"
  is not testable; "Click Save — the row appears in the table without a page
  reload" is.
- **Name the automated coverage** you added or changed, and how to run it
  (`npm test -- session-refresh`). If existing tests cover the change, say which.
- **Describe what you actually verified**, distinct from what could be verified.
  Reviewers should know which claims are tested and which are reasoned.
- **If it cannot be tested, say so explicitly and say why** — do not leave the
  section blank or write "N/A". Legitimate reasons include: the change is
  config or documentation with no runtime behavior; it depends on a third-party
  environment unavailable outside production; it is a type-level or build-only
  change validated by CI; reproduction requires data that cannot be staged.
  Then state what mitigates the gap — a staged rollout, a feature flag, a
  monitoring dashboard to watch after deploy, or a manual check post-release.

---

## Change splash zone

The blast radius: what else this change touches, so reviewers know where to look
for breakage and on-call knows where to look when something smokes.

List the areas affected, and for each, whether the effect is direct or
incidental:

- **Surfaces and flows** — screens, endpoints, jobs, or CLI commands whose
  behavior changes.
- **Shared code** — utilities, components, or types that other callers depend
  on. Name the other callers you checked.
- **Data** — schema migrations, backfills, new columns, changed serialization.
  Note whether the migration is reversible.
- **Contracts** — public API responses, event payloads, config keys, or
  anything another team or client consumes.
- **Operational** — new env vars, secrets, permissions, dependencies, or
  infrastructure required for this to run.

If the change is genuinely self-contained, say so in a line — "Touches only the
README; no runtime code paths affected." This section carries little weight in
simple projects such as documentation or config repos, and a single honest line
is a complete answer there. In a service with shared modules and live consumers,
it is the most important section on the page.

---

## Risk and rollback

The splash zone says what this touches. This section says what to do when it
goes wrong at 3am, written for whoever is on call — who may not be you.

- **Risk level, and what drives it.** Say plainly whether this is routine or
  needs watching, and why: volume of traffic through the changed path, whether
  it writes data, whether it is hard to reverse.
- **How to turn it off.** Name the feature flag and its kill value, if there is
  one. A flag is the cheapest rollback there is — consider adding one for any
  change to a hot path.
- **Whether reverting the commit is sufficient.** Often it is not. A migration
  that has already run, a backfill that has already written, a message consumed
  off a queue, a cache populated in a new format — all survive a `git revert`.
  Say what else must be undone, and how.
- **Migration reversibility.** State whether the down migration exists and has
  been run at least once. An untested down migration is not a rollback plan.
- **What to watch after deploy.** The dashboard, alert, or metric that would
  show this change failing, and roughly how soon a problem would surface.

For a low-risk change, one line closes this out: "Documentation only; no
runtime risk, revert is sufficient."

---

## Related links

Everything a reviewer might need to open, in one place, so they are not hunting
through the description for a URL.

- **Ticket** — the primary one, plus any it rolls up to.
- **Design doc, RFC, or spec** the implementation is meant to satisfy.
- **The incident or bug report** that prompted the work, if it came from one.
- **Dependent PRs, and the order they merge in.** Say it explicitly: "merge
  #412 first — this depends on the schema change" or "must deploy after #418."
  Ordering is the detail most often left implicit and most expensive to get
  wrong.
- **Follow-up tickets** filed for the scope this PR deliberately leaves out.
- **Prior art** — an earlier PR that did something similar, or the one that
  introduced the code being changed.

---

## Copy-paste template

```markdown
## Description

<!-- Why this change exists (source from the ticket where available), what it
     does, why this approach, and what is deliberately out of scope. -->

## Screenshots / recordings

<!-- Before and after for visible changes. Delete this section if the change
     is not user-visible. -->

## Testing instructions

<!-- Numbered steps from a clean state, with expected results. Name the
     automated tests. If this cannot be tested, say why and what mitigates it. -->

1.

## Change splash zone

<!-- Surfaces, shared code, data, contracts, operational requirements.
     One line is fine for self-contained changes. -->

-

## Risk and rollback

<!-- Risk level and why. Feature flag and its kill value. Whether reverting the
     commit is sufficient, and what else must be undone if not. What to watch
     after deploy. -->

## Related links

<!-- Ticket, design doc, originating incident, dependent PRs and their merge
     order, follow-up tickets. -->

-
```
