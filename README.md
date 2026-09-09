# Claude-Skills
Collection of skills to be used with Claude that I have found to be useful.

## Usage

Clone the repository to a location of your choice, then run the included install script:

```bash
./install.sh
```

This copies each skill folder (any top-level directory containing a `SKILL.md`) plus the shared `docs/` folder into `~/.claude/skills`. New skills are discovered automatically — there is no list to keep up to date.

The script prompts before overwriting anything that already exists. To skip the prompts:

```bash
./install.sh --force
```

To install somewhere other than `~/.claude/skills`, set `CLAUDE_SKILLS_DIR`:

```bash
CLAUDE_SKILLS_DIR=/path/to/skills ./install.sh
```

## Skills

- **create-pr** — opens a pull or merge request for the current branch on GitHub, GitLab, Bitbucket, or Azure DevOps, with the title and description written from the branch's own commits using the template below.
- **plan-work** — investigates a bug or feature from a ticket or your description, then writes an implementation plan to a file for you to review and iterate on before any code is written.
- **grill-me** — interviews you relentlessly about a plan or design until every branch of the decision tree is resolved.

## Docs

Shared reference material, installed alongside the skills so Claude can draw on it from any project.

- **[pr-template.md](docs/pr-template.md)** — guidelines for writing a pull request, plus a copy-paste template. Covers title format (`SEG-7777 - Bugfix - Fix for the crashing issue`), description, screenshots, testing instructions, change splash zone, risk and rollback, and related links.
- **[plan-template.md](docs/plan-template.md)** — the structure of an implementation plan: problem, findings, root cause, approach, steps, testing, risks, and open questions. Its sections map onto the PR template, so a good plan is most of the eventual PR description.
- **[skill-template.md](docs/skill-template.md)** — the shared layout every skill in this repo follows, and the conventions for writing a new one.
