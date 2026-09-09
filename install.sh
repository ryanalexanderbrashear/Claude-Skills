#!/usr/bin/env bash
#
# Installs the skills in this repo into ~/.claude/skills
#
# Each top-level directory containing a SKILL.md is treated as a skill and is
# copied over, along with the shared docs/ folder.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

FORCE=0
if [[ "${1:-}" == "-f" || "${1:-}" == "--force" ]]; then
  FORCE=1
fi

mkdir -p "$DEST_DIR"

copy_dir() {
  local src="$1"
  local name
  name="$(basename "$src")"
  local dest="$DEST_DIR/$name"

  if [[ -e "$dest" && $FORCE -eq 0 ]]; then
    read -r -p "  $name already exists in $DEST_DIR. Overwrite? [y/N] " reply
    case "$reply" in
      [yY]*) ;;
      *) echo "  skipped $name"; return ;;
    esac
  fi

  rm -rf "$dest"
  cp -R "$src" "$dest"
  echo "  installed $name"
}

echo "Installing skills from $REPO_DIR into $DEST_DIR"

found=0
for dir in "$REPO_DIR"/*/; do
  dir="${dir%/}"
  [[ -f "$dir/SKILL.md" ]] || continue
  copy_dir "$dir"
  found=1
done

if [[ $found -eq 0 ]]; then
  echo "  no skill folders (directories containing SKILL.md) found"
fi

if [[ -d "$REPO_DIR/docs" ]]; then
  copy_dir "$REPO_DIR/docs"
fi

echo "Done."
