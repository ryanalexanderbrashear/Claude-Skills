---
name: plan-project
description: Turn a description of a project's end goal into a project plan — success criteria, milestones, and a numbered work breakdown that plan-work can pick up item by item. Covers both a new codebase built from nothing and a large body of work inside an existing one. Use when the user describes something they want to build or change at the scale of weeks rather than hours, wants to start a new app, service, tool, or library from scratch, asks for a roadmap, wants an epic or initiative broken down, or asks how to approach a project.
---

# Plan a project from its end goal

Turn "here is what I want to exist" into a plan that says what done means, what
order the work happens in, and what could sink it. A finished result is a plan
the user has approved, ending in a numbered work breakdown where each item is
small enough for `plan-work` to plan in detail when it comes up.

This skill decides **what** gets built and **in what order**. It does not decide
**how** any single piece is built — that is `plan-work`, one plan per work item,
written when the item is next up rather than all at once.

**"Project" means either of two things here, and the skill covers both:**

- **Greenfield** — something that does not exist yet: a new app, service, tool,
  library, or repository, started from nothing.
- **Brownfield** — a large body of work inside a codebase that already exists: a
  migration, a rewrite, a major feature, paying down a class of debt.

They differ in where the constraints come from, not in the shape of the plan —
the platform and what it must integrate with, or the code that is already there.
Both need success criteria, milestones and a work breakdown; the steps below say
where the two diverge.

## When to use

- The user describes an end goal and wants it turned into a plan: "I want X to
  exist", "we need to move off Y", "here's the pitch, how would we do it".
- The user wants to start something new — an app, service, CLI, library, or
  repository that does not exist yet — and needs it scoped before the first
  commit.
- The user asks for a roadmap, a breakdown of an epic or initiative, or how to
  sequence a large piece of work in an existing codebase.
- The work will span many changes and cannot land in one pull request.

Do not use this for a single bug or feature — that is `plan-work`, and running a
project plan over one change buries it in ceremony. Do not use it to stress-test
a plan the user already has; that is `grill-me`.

## Instructions

### 1. Scope it before planning it

A vague end goal is the normal input. Close the gap with one focused round of
questions, asked together rather than one at a time, and put your recommended
answer next to each so the user can accept rather than compose:

- **What is true when this is done?** Push for a condition that can be checked
  from the outside, not an activity that can be performed.
- **What is deliberately not included?** The non-goals prevent more scope creep
  later than any other question here.
- **What constrains it?** Deadline, people available, platforms, systems that
  cannot be changed, decisions already made elsewhere.
- **How big is the appetite?** A week, a quarter, and "whatever it takes" are
  three different projects for the same goal. Ask before choosing an approach,
  because the answer decides which approaches are even eligible.
- **What happens to the existing thing?** For a replacement or migration: does
  it run in parallel, get cut over, or stay for some users indefinitely.

For a greenfield project, also settle what a brownfield one already answers for
you:

- **Who runs it and where?** The deployment target, the platform, and who
  operates it once it exists. This constrains the stack more than taste does.
- **What does it have to interoperate with?** Existing services, auth, data
  formats, a house style. A new project is rarely as unconstrained as it looks.
- **Is the stack chosen, or is choosing it part of the project?** If it is open,
  say so in the plan and treat it as an early decision with an owner — not as
  something to settle silently by writing the first file.
- **Who is the first user, and when do they see it?** A greenfield project with
  no near-term user drifts. The answer sets the first milestone.

Do not ask what the codebase can answer. Ask only what changes the plan.

### 2. Establish the starting point

Find out what is actually there before planning against it.

**In an existing codebase**, read it. Find what the project can build on, what is
in the way, and the constraints the code imposes regardless of anyone's
preference. Cite files and lines — a plan grounded in the real system survives
contact with it.

**For a greenfield project** there is no code to read, but there is always a
starting point, and skipping this step is how a new project gets planned in a
vacuum. Establish instead:

- **Prior art.** A sibling repo, an existing service doing something similar, or
  a previous attempt at the same thing. Read it, and say what to copy and what
  to avoid.
- **House conventions.** The languages, frameworks, CI, and deployment the team
  already uses. Diverging is allowed but it is a decision, and it belongs in the
  plan as one.
- **The integration surface.** The APIs, schemas, and auth the new thing must
  speak to, which are as binding as any existing code would be.
- **What genuinely is unknown.** A new project's biggest risk is usually a
  question nobody has answered yet, not a line of code. Name those — they drive
  the milestone order in the next step.

Distinguish what you verified from what you assumed, and mark the assumptions.

### 3. Choose the shape, then the milestones

Decide the approach, and say what you rejected and why — at project scale these
are the expensive decisions to revisit.

Then break it into milestones, each defined by an **outcome** rather than by
activity, each leaving the system in a working state someone can look at.
Sequence them to **retire the biggest unknown first**: the milestone order that
learns the most, earliest, beats the one that feels most orderly. If a project
has a part nobody is sure is possible, that part goes first.

For a greenfield project, the first milestone is a **walking skeleton**: the
thinnest slice that runs end to end in its real environment — deployed, wired
up, and doing one trivial thing for real. It is tempting to make M1 "set up the
repo and the tooling", but scaffolding proves nothing and hides the integration
risks until late. A skeleton that runs retires the deployment, auth, and
build questions on day one, when they are still cheap.

Plan the first milestone tightly and later ones coarsely. Detail at distance is
fiction, and it gets rewritten twice.

### 4. Break it into work items

Number them. Each is one unit of work with a done-condition that fits in a
sentence — if it does not, split it. Note which milestone it belongs to and what
it depends on.

Size them so a single `plan-work` plan and a single pull request can cover one.
Do not write those plans now; the whole point of the split is that each item is
planned when it comes up, with what the earlier items taught.

### 5. Write the plan where it belongs

Follow `~/.claude/skills/docs/project-template.md` (repo path:
`docs/project-template.md`).

A project plan outlives the session and gets linked from many pull requests, so
it belongs in the repository — `docs/projects/<slug>.md` — not in a temp
directory. **Before writing it there, check whether the repository is public:**

```bash
gh repo view --json visibility -q .visibility   # if gh is available
git remote get-url origin                        # otherwise infer and ask
```

If the repository is public, or you cannot tell, stop and ask the user where the
plan should go before writing it. A project plan routinely contains deadlines,
staffing, commercial reasoning, and unreleased intentions that the code does not
— publishing it is not reversible. Offer, in order: an ignored path inside the
repo (add it to `.gitignore`), a private location outside the repo, or the
session scratchpad. Only commit a plan to a public repository when the user has
said so explicitly.

Tell the user the full path either way.

### 6. Iterate, then keep it alive

Hand over the path with a short summary: the approach in a couple of sentences,
the milestone sequence in one line, and the open questions. Do not paste the
plan into the conversation.

Edit the file in place as the user pushes back. Keep the open questions current,
and mark which ones block starting versus which can wait.

Once work begins, the plan is a live document: update work-item status as items
land, link their pull requests, and re-plan later milestones as earlier ones
teach you something. That re-planning is the design working, not a failure of
the original plan.

### 7. Audit at every milestone boundary

When a milestone's last item merges, audit before starting the next, and put the
audit in the plan as part of the sequence so it is scheduled rather than recalled.
Follow `~/.claude/skills/docs/milestone-audit.md` (repo path:
`docs/milestone-audit.md`): **audit by using the thing, not by reading the list**,
record the verdict beside the milestone, and schedule what it found as items.

## Guidelines

- Do not write implementation code, and do not write the per-item `plan-work`
  plans. Both are later steps, and doing them now wastes what the early work
  would have taught.
- Recommend an answer to every question you ask and every open question you
  leave. A question without a recommendation hands the work back to the user.
- Prefer the smallest project that reaches the stated goal. Note the adjacent
  ambitions under Out of scope instead of absorbing them — projects fail by
  accumulation far more often than by under-reach.
- Make success criteria checkable. "Better performance" cannot be delivered;
  "p95 under 400ms" can.
- Say when the goal is unclear enough that planning it would be theatre, and ask
  rather than producing a confident-looking plan over a guess.
- Audit each milestone by using the system, not by reading the work items.
- If the work turns out to fit in one change, say so and offer `plan-work`
  instead.
