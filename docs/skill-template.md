# Skill Template

The shared layout for every skill in this repo. A skill is a folder at the
repository root containing a `SKILL.md`; the folder name and the frontmatter
`name` must match, and `install.sh` discovers it automatically.

Keep skills short. A skill is a prompt, not a manual — every line competes for
the model's attention, so cut anything the model would do correctly on its own.

`tests/lint-skills.sh` fails a skill at **300 lines** and notes one past **220**.
The note is the useful one: length is a proxy for "has this grown a second job?",
which is a judgement, so it reports and lets the author answer. The hard limit
only catches runaway. Neither number is a target — most skills here sit between
120 and 200, and the shortest is the one that needed the least.

## Layout

```markdown
---
name: <kebab-case-slug, identical to the folder name>
description: <One sentence on what the skill does.> Use when <the phrases and
  situations that should trigger it>.
---

# <Human-readable title>

<One or two sentences: the purpose, and what a finished result looks like.>

## When to use

- <Trigger: a request or situation this skill handles.>
- <Trigger.>

Do not use this for <the neighbouring case this is likely to be confused with,
and what to do instead>.

## Instructions

1. <Step, in the order it should happen.>
2. <Step.>

## Guidelines

- <A constraint, standard, or style rule that applies throughout.>
```

## Section rules

- **Frontmatter** — `name` and `description` only. The `description` is the
  sole thing the model sees when deciding whether to load the skill, so it must
  state both *what* the skill does and *when* to invoke it, including any
  literal phrase a user would say ("grill me"). Write it in the third person.
- **Title and purpose** — an H1 matching the skill's intent, then a purpose
  statement. No preamble about what a skill is.
- **When to use** — the trigger list, and, where the skill is easily confused
  with another, an explicit "do not use this for…" line.
- **Instructions** — numbered steps for a procedure, prose for a posture. A
  skill that shapes *how* the model behaves throughout a conversation should not
  be forced into a numbered list.
- **Guidelines** — the rules that hold across every step: what to confirm before
  acting, what to never do, tone, output format.

Optional sections, added only when they earn their place: **Examples** (concrete
input/output pairs), **Notes** (edge cases, platform differences), and
**Reference** (commands or paths worth spelling out exactly).

## Conventions

- Address the model directly in the imperative: "Ask the user…", not "The skill
  will ask the user…".
- Spell out exact commands where getting them wrong is likely; leave them out
  where the model can derive them.
- Say explicitly when to stop and confirm with the user. Anything outward-facing
  — opening a pull request, pushing, posting — needs confirmation before it
  happens.
- Reference shared docs by their installed path, `~/.claude/skills/docs/<file>`,
  with the repo-relative path as a fallback.
- **Shell snippets must work under both bash and zsh**, since the user's shell
  is whatever it is. The trap is word splitting: bash splits an unquoted
  `$var` into multiple arguments, zsh does not — so `cmd $args` passes one
  argument in zsh and several in bash. Both shells split unquoted command
  substitution, so `for x in $(cmd)` is safe. Write the snippet so it does not
  depend on the difference: quote what should stay one argument, and use an
  array or explicit words for what should be several. A snippet that silently
  does the wrong thing in one shell is worse than one that fails in both.
