#!/usr/bin/env bash
#
# Regression tests for install.sh.
#
# Written for SEG-4821: install.sh used to delete the destination before
# writing the replacement, so an interrupted or failed run left a skill
# missing or half-written. Tests 3 and 4 are that bug; the rest guard the
# behavior the fix had to preserve.
#
# Usage: ./tests/install-test.sh

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$REPO_DIR/install.sh"

WORK="$(mktemp -d)"
trap 'chmod -R u+rwX "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

passed=0
failed=0

ok()   { printf '  \033[32mok\033[0m   %s\n' "$1"; passed=$((passed + 1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; failed=$((failed + 1)); }
check() { if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi; }
group() { printf '\n%s\n' "$1"; }

# Build a fixture repo: two skills, a docs folder, and a non-skill folder.
make_repo() {
  local r="$1"
  rm -rf "$r"
  mkdir -p "$r/alpha" "$r/beta" "$r/docs" "$r/notaskill"
  printf 'alpha\n'     > "$r/alpha/SKILL.md"
  printf 'reference\n' > "$r/alpha/zz-ref.md"
  printf 'beta\n'      > "$r/beta/SKILL.md"
  printf 'guide\n'     > "$r/docs/guide.md"
  printf 'ignore me\n' > "$r/notaskill/README.md"
  cp "$INSTALL" "$r/install.sh"
  chmod +x "$r/install.sh"
}

residue() { ls -a "$1" 2>/dev/null | grep -cE '^\.(alpha|beta|docs)\.(tmp|old)\.'; }

REPO="$WORK/repo"
DEST="$WORK/dest"
make_repo "$REPO"
mkdir -p "$DEST"

group "1. clean install"
out="$(CLAUDE_SKILLS_DIR="$DEST" "$REPO/install.sh" -f 2>&1)"; rc=$?
check "exits 0" "$rc" "0"
check "installs alpha" "$([[ -f "$DEST/alpha/SKILL.md" ]] && echo yes)" "yes"
check "installs beta" "$([[ -f "$DEST/beta/SKILL.md" ]] && echo yes)" "yes"
check "installs docs" "$([[ -f "$DEST/docs/guide.md" ]] && echo yes)" "yes"
check "ignores non-skill folders" "$([[ -e "$DEST/notaskill" ]] && echo yes || echo no)" "no"

group "2. re-install over an existing install"
CLAUDE_SKILLS_DIR="$DEST" "$REPO/install.sh" -f >/dev/null 2>&1
check "exits 0" "$?" "0"
diff -r "$REPO/alpha" "$DEST/alpha" >/dev/null 2>&1
check "destination matches source" "$?" "0"
check "leaves no .tmp/.old residue" "$(residue "$DEST")" "0"

group "3. SEG-4821: a copy that fails must not destroy the installed skill"
if [[ "$(id -u)" -eq 0 ]]; then
  printf '  skip (running as root; chmod 000 would not block a read)\n'
else
  cp -R "$DEST/alpha" "$WORK/alpha-before"
  chmod 000 "$REPO/alpha/zz-ref.md"
  out="$(CLAUDE_SKILLS_DIR="$DEST" "$REPO/install.sh" -f 2>&1)"; rc=$?
  chmod 644 "$REPO/alpha/zz-ref.md"
  diff -r "$WORK/alpha-before" "$DEST/alpha" >/dev/null 2>&1
  check "installed skill is untouched" "$?" "0"
  check "exits non-zero" "$([[ $rc -ne 0 ]] && echo yes)" "yes"
  check "names the failure" "$(grep -c 'FAILED alpha' <<<"$out")" "1"
  check "other skills still install" "$(grep -c 'installed beta' <<<"$out")" "1"
  check "docs still installs" "$(grep -c 'installed docs' <<<"$out")" "1"
  check "leaves no residue" "$(residue "$DEST")" "0"
  rm -rf "$WORK/alpha-before"
fi

group "4. SEG-4821: an interrupt mid-copy must not destroy the installed skill"
# Fault injection: widen the staged-but-not-yet-swapped window, which is
# otherwise too brief to hit reliably (APFS copies are near-instant).
SLOW="$REPO/install-slow.sh"
sed 's|^  # A partial copy is worse|  sleep 3\n  # A partial copy is worse|' "$INSTALL" > "$SLOW"
chmod +x "$SLOW"
if ! grep -q 'sleep 3' "$SLOW"; then
  bad "fault injection did not apply — install.sh changed shape, update this test"
else
  printf 'alpha modified\n' > "$REPO/alpha/SKILL.md"
  cp -R "$DEST/alpha" "$WORK/alpha-before"
  # Job control matters here: a background job in a non-interactive shell
  # inherits SIGINT as ignored, and bash will not install a trap for an
  # ignored signal — so without `set -m` the child never sees the Ctrl-C.
  set -m
  CLAUDE_SKILLS_DIR="$DEST" "$SLOW" -f >/dev/null 2>&1 &
  pid=$!
  sleep 1
  kill -INT "$pid" 2>/dev/null
  wait "$pid"; rc=$?
  set +m
  check "exits 130" "$rc" "130"
  diff -r "$WORK/alpha-before" "$DEST/alpha" >/dev/null 2>&1
  check "installed skill is untouched" "$?" "0"
  check "leaves no residue" "$(residue "$DEST")" "0"
  printf 'alpha\n' > "$REPO/alpha/SKILL.md"
  rm -rf "$WORK/alpha-before"
fi

group "5. a file removed from the repo is removed from the install"
rm "$REPO/alpha/zz-ref.md"
CLAUDE_SKILLS_DIR="$DEST" "$REPO/install.sh" -f >/dev/null 2>&1
check "stale file is gone" "$([[ -e "$DEST/alpha/zz-ref.md" ]] && echo yes || echo no)" "no"
printf 'reference\n' > "$REPO/alpha/zz-ref.md"

group "6. the overwrite prompt"
out="$(printf 'n\ny\nn\n' | CLAUDE_SKILLS_DIR="$DEST" "$REPO/install.sh" 2>&1)"
check "n skips" "$(grep -c 'skipped alpha' <<<"$out")" "1"
check "y overwrites" "$(grep -c 'installed beta' <<<"$out")" "1"

group "7. closed stdin skips rather than aborting the run"
out="$(CLAUDE_SKILLS_DIR="$DEST" "$REPO/install.sh" </dev/null 2>&1)"; rc=$?
check "exits 0" "$rc" "0"
check "skips every skill" "$(grep -c 'skipped' <<<"$out")" "3"
check "still reaches the end" "$(grep -c 'Done.' <<<"$out")" "1"

group "8. a fresh destination that does not exist yet"
out="$(CLAUDE_SKILLS_DIR="$WORK/brand-new" "$REPO/install.sh" -f 2>&1)"; rc=$?
check "exits 0" "$rc" "0"
check "creates it and installs" "$([[ -f "$WORK/brand-new/alpha/SKILL.md" ]] && echo yes)" "yes"

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
