# Claude-Skills
Collection of skills to be used with Claude that I have found to be useful.

## Usage

Clone the repository to a location of your choice, then run the included install script:

```bash
./install.sh
```

This copies each skill folder (any top-level directory containing a `SKILL.md`) plus the shared `docs/` folder into `~/.claude/skills`. New skills are discovered automatically — there is no list to keep up to date.

A skill is staged and swapped into place rather than deleted first, so a failed or interrupted run never leaves a skill in a worse state than it was before. If one skill fails to install, the rest still install, the failure is named, and the script exits non-zero.

The script prompts before overwriting anything that already exists. To skip the prompts:

```bash
./install.sh --force
```

To install somewhere other than `~/.claude/skills`, set `CLAUDE_SKILLS_DIR`:

```bash
CLAUDE_SKILLS_DIR=/path/to/skills ./install.sh
```

## Tests

```bash
./tests/install-test.sh
```

Covers the install script end to end, including the SEG-4821 regressions: a
failed copy and an interrupted run must both leave an already-installed skill
exactly as it was.

## Skills

- **create-pr** — opens a pull or merge request for the current branch on GitHub, GitLab, Bitbucket, or Azure DevOps, with the title and description written from the branch's own commits using the template below.
- **plan-project** — turns a description of a project's end goal into a plan: success criteria, milestones sequenced to retire the biggest unknown first, and a numbered work breakdown that `plan-work` picks up item by item. Covers both a new codebase started from nothing and a large body of work inside an existing one.
- **plan-work** — investigates a bug or feature from a ticket or your description, then writes an implementation plan to a file for you to review and iterate on before any code is written.
- **grill-me** — interviews you relentlessly about a plan or design until every branch of the decision tree is resolved.

## Docs

Shared reference material, installed alongside the skills so Claude can draw on it from any project.

- **[pr-template.md](docs/pr-template.md)** — guidelines for writing a pull request, plus a copy-paste template. Covers title format (`SEG-7777 - Bugfix - Fix for the crashing issue`), description, screenshots, testing instructions, change splash zone, risk and rollback, and related links.
- **[project-template.md](docs/project-template.md)** — the structure of a project plan: goal and success criteria, non-goals, constraints, current state, approach, outcome-defined milestones, a work-item table, risks, and open questions.
- **[plan-template.md](docs/plan-template.md)** — the structure of an implementation plan: problem, findings, root cause, approach, steps, testing, risks, and open questions. Its sections map onto the PR template, so a good plan is most of the eventual PR description.
- **[skill-template.md](docs/skill-template.md)** — the shared layout every skill in this repo follows, and the conventions for writing a new one.
