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

- **grill-me** — interviews you relentlessly about a plan or design until every branch of the decision tree is resolved.
