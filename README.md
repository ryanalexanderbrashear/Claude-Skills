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
./tests/triage-ci-test.sh  # the log filtering and stale-base checks triage-ci prescribes
./tests/tracker-setup-test.sh # the item-to-ticket mapping a work breakdown needs
./tests/lint-skills.sh     # this repo's own conventions, across every skill
```

Both run in CI on every push and pull request, on Linux and macOS — the
userlands differ enough that a single runner would hide breakage.

`install-test.sh` covers the SEG-4821 regressions: a failed copy and an
interrupted run must both leave an already-installed skill exactly as it was.

`split-work-test.sh` covers the non-obvious git behavior the skill relies on,
including proof that `git fetch` before `git push --force-with-lease` defeats
the lease and destroys another person's commit.

`tracker-setup-test.sh` builds a breakdown whose item numbers are not its ticket
numbers — the ordinary case, since GitHub shares numbering with pull requests — and
proves that resolving dependencies by arithmetic wires every edge to a real but
unrelated ticket. The API accepts all of them, so there is no error to notice.

`triage-ci-test.sh` pins both mechanics that look right when they are wrong: the
ESC-based colour strip that silently changes nothing, and the stale-base check,
which reads a branch's distance from its base rather than the files it touched —
the file-list heuristic fails precisely where drift checks exist, because a branch
there normally does contain the generated file.

## Skills

The skills form a pipeline, though each works on its own:

**plan-project** → **file-issue** → **plan-work** → **grill-me** → implement → **create-pr** → **address-review**

- **plan-project** — turns a description of a project's end goal into a plan: checkable success criteria, milestones sequenced to retire the biggest unknown first, and a work breakdown filed as tickets that `plan-work` picks up one at a time. Covers both a new codebase started from nothing and a large body of work inside an existing one. Decides what gets built and in what order, and stops there.
- **file-issue** — files a bug or a discovered piece of work in the project's real tracker, found by reading the repo rather than assumed from the host, with the report in the reporter's words and the cause traced or explicitly marked unknown. Untracked work does not exist.
- **plan-work** — investigates one bug or feature, from a ticket or your description, and writes an implementation plan onto the ticket for you to review and iterate on before any code is written. Reproduces a bug before planning the fix, and grounds its findings in the code with file and line references. Names the README passages the change will make untrue, so updating them is a step in the plan rather than a discovery after merge.
- **grill-me** — interviews you relentlessly about a plan or design, one question at a time, until every branch of the decision tree is resolved. Use it on a plan you already have.
- **address-review** — reads the outstanding review feedback on a pull request, triages it into will-fix / already-correct / needs-discussion, applies the fixes, and replies on each thread. GitHub only.
- **triage-ci** — diagnoses a failing CI run and says whether it is a real failure, an environment difference, a stale base, a run that never started, or a suspected flake, with the evidence. Read-only.
- **regression-test** — writes the test that pins a bug, and proves it fails against the broken code before accepting it. A test that has never failed has never been shown to be a test.
- **commit** — writes the commit message for the staged changes, subject in the same format as a PR title, and advises on which commits should exist by the time the branch merges.
- **split-work** — separates tangled work into coherent commits or branches, records a rescue point first, and verifies the pieces add up to exactly the original content. Uses non-interactive git throughout.
- **create-pr** — opens a pull or merge request for the current branch on GitHub, GitLab, Bitbucket, or Azure DevOps, with the title and description written from the branch's own commits. Detects the default branch rather than assuming `main`, and detects when a branch is stacked on another unmerged branch so someone else's commits do not end up in your PR. Before drafting, it checks the README against the branch's own diff and fixes what the branch made stale.

Outside the pipeline:

- **resume-tailor** — tailors the master resume to a job description as a Google Doc copy. It reads the Career Inventory live, so the personal data stays in private documents and out of this repository, and it checks every claim against that inventory. Where the role asks for something the inventory cannot support, the skill reports a gap rather than writing around it.

## Docs

Shared reference material, installed alongside the skills so Claude can draw on it from any project. The templates are the substance of the skills — a skill decides what to do, the template decides what the result looks like.

- **[project-template.md](docs/project-template.md)** — the structure of a project plan: goal and success criteria, non-goals, constraints, starting point, approach, observability, outcome-defined milestones, risks, and open questions — with the work items themselves in the tracker rather than a table here. Observability is decided with the walking skeleton, because a request id costs one wrapper at M1 and every call site afterwards.
- **[plan-template.md](docs/plan-template.md)** — the structure of an implementation plan: problem, findings, root cause, approach, steps, testing, observability, risks, and open questions. Every plan assumes production code that someone will have to debug and audit — tests prove the change works on a machine you control, observability is how anyone finds out what it did on a machine you do not. Its sections map onto the PR template, so a good plan is most of the eventual PR description already written.
- **[pr-template.md](docs/pr-template.md)** — guidelines for writing a pull request, plus a copy-paste template. Covers title format (`SEG-7777 - Bugfix - Fix for the crashing issue`), description, screenshots, testing instructions, change splash zone, risk and rollback, and related links.
- **[tracker-setup.md](docs/tracker-setup.md)** — how a work breakdown becomes tickets: milestones, then every ticket, then the dependency links, three passes because each needs what the one before it created. Linking a dependency while filing looks equivalent and silently omits every edge whose blocker is filed later — which, since a plan is ordered by milestone rather than by dependency, is the edges that cross a boundary. Also why an item's number must never be treated as its ticket's.
- **[milestone-audit.md](docs/milestone-audit.md)** — how to audit a milestone before starting the next one: audit by using the system rather than reading the work items, the three questions to ask, where to record the verdict, and why an audit that finds nothing is usually an audit that did not happen.
- **[readme-check.md](docs/readme-check.md)** — the small README audit that runs at the end of every change: search the README for the names the diff changed, read only what matches, fix what this branch made stale, and file older drift. A README goes stale one merged change at a time; checking each change costs a few greps, where a full audit costs a session.
- **[skill-template.md](docs/skill-template.md)** — the shared layout every skill here follows, and the conventions for writing a new one.
