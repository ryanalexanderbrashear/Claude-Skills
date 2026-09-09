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
./tests/install-test.sh    # the install script, end to end
./tests/split-work-test.sh # the git mechanics split-work depends on
```

`install-test.sh` covers the SEG-4821 regressions: a failed copy and an
interrupted run must both leave an already-installed skill exactly as it was.

`split-work-test.sh` covers the non-obvious git behavior the skill relies on,
including proof that `git fetch` before `git push --force-with-lease` defeats
the lease and destroys another person's commit.

## Skills

The four skills form a pipeline, though each works on its own:

**plan-project** → **plan-work** → **grill-me** → implement → **create-pr** → **address-review**

- **plan-project** — turns a description of a project's end goal into a plan: checkable success criteria, milestones sequenced to retire the biggest unknown first, and a numbered work breakdown that `plan-work` picks up item by item. Covers both a new codebase started from nothing and a large body of work inside an existing one. Decides what gets built and in what order, and stops there.
- **plan-work** — investigates one bug or feature, from a ticket or your description, and writes an implementation plan to a file for you to review and iterate on before any code is written. Reproduces a bug before planning the fix, and grounds its findings in the code with file and line references.
- **grill-me** — interviews you relentlessly about a plan or design, one question at a time, until every branch of the decision tree is resolved. Use it on a plan you already have.
- **address-review** — reads the outstanding review feedback on a pull request, triages it into will-fix / already-correct / needs-discussion, applies the fixes, and replies on each thread. GitHub only.
- **regression-test** — writes the test that pins a bug, and proves it fails against the broken code before accepting it. A test that has never failed has never been shown to be a test.
- **commit** — writes the commit message for the staged changes, subject in the same format as a PR title, and advises on which commits should exist by the time the branch merges.
- **split-work** — separates tangled work into coherent commits or branches, records a rescue point first, and verifies the pieces add up to exactly the original content. Uses non-interactive git throughout.
- **create-pr** — opens a pull or merge request for the current branch on GitHub, GitLab, Bitbucket, or Azure DevOps, with the title and description written from the branch's own commits. Detects the default branch rather than assuming `main`, and detects when a branch is stacked on another unmerged branch so someone else's commits do not end up in your PR.

## Docs

Shared reference material, installed alongside the skills so Claude can draw on it from any project. The templates are the substance of the skills — a skill decides what to do, the template decides what the result looks like.

- **[project-template.md](docs/project-template.md)** — the structure of a project plan: goal and success criteria, non-goals, constraints, starting point, approach, outcome-defined milestones, a work-item table, risks, and open questions.
- **[plan-template.md](docs/plan-template.md)** — the structure of an implementation plan: problem, findings, root cause, approach, steps, testing, risks, and open questions. Its sections map onto the PR template, so a good plan is most of the eventual PR description already written.
- **[pr-template.md](docs/pr-template.md)** — guidelines for writing a pull request, plus a copy-paste template. Covers title format (`SEG-7777 - Bugfix - Fix for the crashing issue`), description, screenshots, testing instructions, change splash zone, risk and rollback, and related links.
- **[skill-template.md](docs/skill-template.md)** — the shared layout every skill here follows, and the conventions for writing a new one.
