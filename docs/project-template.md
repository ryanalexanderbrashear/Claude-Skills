# Project Template

The structure for a project plan — work spanning many changes, sized in weeks
rather than hours. Used by the `plan-project` skill.

It covers both kinds of project: something new built from nothing, and a large
body of work inside a codebase that already exists. The sections are the same
for both; what changes is where the constraints come from, which the Starting
point section spells out.

A project plan answers three questions a single-change plan does not: what
"done" actually means, what order the work happens in, and what could make the
whole thing fail. It stops at the boundary of *how* each piece is built — that
belongs in a `plan-work` plan per work item, written when the item is next up.

Detail should decay with distance. Plan the first milestone tightly and later
ones coarsely; a fifth milestone specified to the file level is fiction, and
rewriting it after every discovery wastes the effort twice.

## Layout

```markdown
# <Project name>

**Status:** Draft | Approved | In progress | Done
**Source:** <ticket, epic, or "user description">
**Updated:** <date of the last substantive revision>

## Goal

<What is true when this is done, in a few sentences. Write it so that someone
can tell from the outside whether it happened.>

**Success criteria**

- <A condition that can be checked, not an activity that can be performed.
  "p95 login latency under 400ms", not "optimize the login path".>

## Non-goals

- <What someone could reasonably assume is included and is not. This section
  prevents more scope creep than any other.>

## Constraints

- <Deadline, team size, budget, platforms to support, systems that cannot be
  changed, compliance requirements, decisions already made elsewhere.>

## Starting point

<For work in an existing codebase: what exists today, established by reading the
code rather than by assumption — the components involved, what can be reused,
what is in the way. Cite `path/to/file.ts:42` where a specific thing matters.

For a new project: there is no code to read, but there is always a starting
point. Prior art worth copying or avoiding, the house conventions on stack and
deployment, the APIs and schemas it must speak to, and the questions nobody has
answered yet. A new project planned in a vacuum is planned wrong.>

## Approach

<The shape of the solution in a paragraph or two, then why this shape. Name the
alternatives considered and why each was rejected — at project scale these are
the decisions that are expensive to revisit.>

## Milestones

Each milestone is defined by an outcome, not by activity, and leaves the system
in a working state that someone could look at.

For a new project, M1 is a walking skeleton: the thinnest slice that runs end to
end in its real environment, not the scaffolding. Scaffolding proves nothing and
defers the integration risks; a skeleton that runs retires them immediately.

### M1 — <name>

**Outcome:** <what is true, and demonstrable, when this milestone lands.>
**Retires:** <the risk or unknown this resolves. Order milestones so the
biggest unknown is retired earliest.>

### M2 — <name>

**Outcome:** <…>
**Retires:** <…>

## Work items

Numbered so they can be referred to and claimed. Each is one unit of work with a
done-condition that fits in a sentence — if it does not, split it. Each becomes
a `plan-work` plan when it comes up, not before.

| # | Work item | Milestone | Depends on | Status |
| --- | --- | --- | --- | --- |
| 1 | <Short imperative name> | M1 | — | Not started |
| 2 | <…> | M1 | 1 | Not started |

<Under the table, a line or two on any item whose scope is not obvious from its
name.>

## Risks and unknowns

- **<Risk>** — <what it would cost, and what would reduce it. A risk with no
  response is just anxiety; say what you would do about it, or say that you are
  accepting it.>

## Open questions

1. <A decision the user needs to make, with your recommendation and the
   tradeoff. At project scale, mark the ones that block starting versus the
   ones that can be answered later.>

## Out of scope

- <Adjacent work deliberately excluded, and where it should go instead.>
```

## Keeping it alive

A project plan is read many times over its life, unlike a single-change plan
that is read once and executed. Keep it worth reading:

- Update **Status** on work items as they land, and add the PR link.
- When reality diverges from the plan, change the plan. A stale plan is worse
  than none, because people act on it.
- Re-plan later milestones as earlier ones teach you something. That is the
  point of the coarse detail, not a failure of the original plan.
- Move settled open questions into **Approach** or **Constraints** with the
  answer, rather than deleting them — the reasoning is the valuable part.
