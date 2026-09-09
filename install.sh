#!/usr/bin/env bash
#
# Installs the skills in this repo into ~/.claude/skills
#
# Each top-level directory containing a SKILL.md is treated as a skill and is
# copied over, along with the shared docs/ folder.
#
# A skill is staged and then swapped into place, never deleted first, so an
# interrupted or failed install leaves the previously installed copy intact.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

FORCE=0
if [[ "${1:-}" == "-f" || "${1:-}" == "--force" ]]; then
  FORCE=1
fi

mkdir -p "$DEST_DIR"

installed=()
skipped=()
failed=()

# Set while a swap is in flight, so the trap can undo a half-finished one.
staging=""
backup=""
backup_target=""

cleanup() {
  if [[ -n "$staging" && -e "$staging" ]]; then
    rm -rf "$staging"
  fi
  # If the destination was set aside but never replaced, put it back.
  if [[ -n "$backup" && -e "$backup" ]]; then
    if [[ -n "$backup_target" && ! -e "$backup_target" ]]; then
      mv "$backup" "$backup_target"
    else
      rm -rf "$backup"
    fi
  fi
  staging=""
  backup=""
  backup_target=""
}

on_signal() {
  cleanup
  echo "" >&2
  echo "Interrupted. No skill was left in a worse state than before." >&2
  exit 130
}

trap cleanup EXIT
trap on_signal INT TERM

fail() {
  local name="$1" reason="$2"
  cleanup
  echo "  FAILED $name — $reason" >&2
  failed+=("$name")
  return 1
}

# copy_dir <source dir> <require SKILL.md: 1|0>
copy_dir() {
  local src="$1"
  local require_skill="$2"
  local name
  name="$(basename "$src")"
  local dest="$DEST_DIR/$name"

  if [[ -e "$dest" && $FORCE -eq 0 ]]; then
    local reply
    # Default to skipping if stdin is closed, rather than aborting the run.
    read -r -p "  $name already exists in $DEST_DIR. Overwrite? [y/N] " reply || reply=""
    case "$reply" in
      [yY]*) ;;
      *) echo "  skipped $name"; skipped+=("$name"); return 0 ;;
    esac
  fi

  # Stage beside the destination — same filesystem, so the swap below is a
  # rename rather than a second copy.
  staging="$DEST_DIR/.$name.tmp.$$"
  rm -rf "$staging"
  if ! cp -R "$src" "$staging"; then
    fail "$name" "copy failed; existing install left untouched"
    return 1
  fi

  # A partial copy is worse than a missing one, because nothing signals it.
  if [[ $require_skill -eq 1 && ! -f "$staging/SKILL.md" ]]; then
    fail "$name" "staged copy has no SKILL.md; existing install left untouched"
    return 1
  fi
  if [[ -z "$(ls -A "$staging" 2>/dev/null)" ]]; then
    fail "$name" "staged copy is empty; existing install left untouched"
    return 1
  fi

  # Swap. Between these two renames the destination briefly does not exist;
  # two renames on one filesystem is as close to atomic as portable shell gets,
  # and the trap restores the backup if anything stops us in between.
  if [[ -e "$dest" ]]; then
    backup="$DEST_DIR/.$name.old.$$"
    backup_target="$dest"
    rm -rf "$backup"
    if ! mv "$dest" "$backup"; then
      backup=""
      backup_target=""
      fail "$name" "could not set the existing install aside; left untouched"
      return 1
    fi
  fi
  if ! mv "$staging" "$dest"; then
    fail "$name" "could not move the staged copy into place; restored previous"
    return 1
  fi
  staging=""

  # The install is committed at this point; report it before spending time
  # deleting the old copy, so an interrupt during that delete cannot make a
  # finished install look unfinished.
  echo "  installed $name"
  installed+=("$name")

  if [[ -n "$backup" ]]; then
    rm -rf "$backup"
    backup=""
    backup_target=""
  fi

  return 0
}

echo "Installing skills from $REPO_DIR into $DEST_DIR"

found=0
for dir in "$REPO_DIR"/*/; do
  dir="${dir%/}"
  [[ -f "$dir/SKILL.md" ]] || continue
  found=1
  # One failure must not stop the remaining skills from installing.
  copy_dir "$dir" 1 || true
done

if [[ $found -eq 0 ]]; then
  echo "  no skill folders (directories containing SKILL.md) found"
fi

if [[ -d "$REPO_DIR/docs" ]]; then
  copy_dir "$REPO_DIR/docs" 0 || true
fi

if [[ ${#failed[@]} -gt 0 ]]; then
  echo ""
  echo "Installed ${#installed[@]}, skipped ${#skipped[@]}, failed ${#failed[@]}: ${failed[*]}" >&2
  echo "Anything that failed was left as it was before this run." >&2
  exit 1
fi

echo "Done."
