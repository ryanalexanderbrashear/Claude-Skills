#!/usr/bin/env bash
#
# Guards the two mechanics triage-ci prescribes that look right when wrong.
#
# 1. GitHub's log API returns colour codes as LITERAL caret notation (^[[31m),
#    not as ESC bytes. Every ESC-based strip therefore matches nothing and passes
#    the text through unchanged — looking exactly like it worked. This pins both
#    the behavior and the documentation, since a plausible-looking "fix" to the
#    skill would silently do nothing.
#
# 2. The stale-base check measures DISTANCE FROM THE BASE, not which files the
#    branch touched. The file-list heuristic is wrong precisely in repositories
#    that have drift checks, because a branch there normally does contain the
#    generated file — group 6 builds that case and proves it.
#
# Usage: ./tests/triage-ci-test.sh

set -uo pipefail

SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/triage-ci/SKILL.md"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

passed=0
failed=0
ok()    { printf '  \033[32mok\033[0m   %s\n' "$1"; passed=$((passed + 1)); }
bad()   { printf '  \033[31mFAIL\033[0m %s\n' "$1"; failed=$((failed + 1)); }
check() { if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi; }
group() { printf '\n%s\n' "$1"; }

# A log line in exactly the form `gh run view --log-failed` emits: literal
# caret-bracket escapes, and a job \t step \t timestamp prefix.
printf 'test (ubuntu-latest)\tinstall script\t2026-09-09T20:42:09.1941107Z   ^[[31mFAIL^[[0m assertion (expected '"'"'yes'"'"', got '"'"''"'"')\n' > "$WORK/line.txt"

group "1. fixture is in the shape gh actually returns"
check "contains literal caret notation" "$(grep -c '\^\[\[31m' "$WORK/line.txt")" "1"
check "contains no real ESC byte" "$(od -c "$WORK/line.txt" | grep -c '033')" "0"

group "2. the ESC-based strips are silent no-ops"
esc_sed=$(sed 's/\x1b\[[0-9;]*m//g' "$WORK/line.txt")
check "sed with \\x1b changes nothing" "$([ "$esc_sed" = "$(cat "$WORK/line.txt")" ] && echo unchanged)" "unchanged"
if command -v perl >/dev/null; then
  esc_perl=$(perl -pe 's/\e\[[0-9;]*m//g' "$WORK/line.txt")
  check "perl with \\e changes nothing" "$([ "$esc_perl" = "$(cat "$WORK/line.txt")" ] && echo unchanged)" "unchanged"
else
  ok "perl not present, skipped"
fi

group "3. the literal-caret strip works"
stripped=$(sed 's/\^\[\[[0-9;]*m//g' "$WORK/line.txt")
check "colour codes removed" "$(grep -c '\^\[\[' <<<"$stripped")" "0"
check "the message survives" "$(grep -c 'FAIL assertion' <<<"$stripped")" "1"

group "4. the prefix strip leaves the step name and message"
final=$(printf '%s\n' "$stripped" | sed 's/^\([^	]*\)	\([^	]*\)	[0-9T:.Z-]*Z /[\2] /')
check "timestamp gone" "$(grep -c '2026-09-09T' <<<"$final")" "0"
check "step name kept" "$(grep -c '\[install script\]' <<<"$final")" "1"

group "5. the skill documents the form that works"
check "prescribes the literal-caret strip" \
  "$(grep -cF 'sed '"'"'s/\^\[\[[0-9;]*m//g'"'"'' "$SKILL")" "1"
# The skill legitimately *mentions* the ESC forms when warning about them, so
# only the runnable code blocks are checked.
awk '/^```/{f=!f; next} f' "$SKILL" > "$WORK/blocks.txt"
check "no ESC-based strip inside a runnable code block" \
  "$(grep -cE 'x1b|perl -pe .s/.e' "$WORK/blocks.txt")" "0"
check "the working strip IS inside a runnable code block" \
  "$(grep -cF 'sed '"'"'s/\^\[\[' "$WORK/blocks.txt")" "1"

group "6. the stale-base check reads distance, not the file list"
# A repository with a generated file, a branch that regenerated it, and a base
# that has since moved: the exact shape a queue of one-at-a-time merges produces.
REPO="$WORK/repo"
git init -q -b main "$REPO"
(
  cd "$REPO" || exit 1
  git config user.email t@example.com && git config user.name Test
  printf 'generated: 1\n' > generated.txt
  git add -A && git commit -qm base
  git checkout -qb feature
  printf 'generated: 2\n' > generated.txt      # the branch DOES change it
  git add -A && git commit -qm 'feature regenerates the file'
  git checkout -q main
  printf 'generated: 3\n' > generated.txt      # and then something else merges
  git add -A && git commit -qm 'another PR lands'
  git checkout -q feature
)
behind=$(git -C "$REPO" rev-list --count "feature..main")
check "the branch is measurably behind its base" "$behind" "1"
touched=$(git -C "$REPO" diff --name-only main...feature | grep -c '^generated.txt$')
check "and it does contain the stale file, defeating the file-list test" "$touched" "1"
# The rebase that fixes it CONFLICTS, on the generated file itself — both sides
# regenerated it. So "just rebase" is not the whole instruction: the conflict is
# resolved by regenerating on top of the new base, not by choosing a side.
git -C "$REPO" rebase main >/dev/null 2>&1
rebasing=$([[ -d "$REPO/.git/rebase-merge" || -d "$REPO/.git/rebase-apply" ]] && echo yes)
check "the rebase conflicts on the generated file" "$rebasing" "yes"
check "and the distance is still there mid-conflict" \
  "$(git -C "$REPO" rev-list --count 'HEAD..main')" "0"
printf 'generated: 4\n' > "$REPO/generated.txt"   # what re-running the generator gives
git -C "$REPO" add generated.txt
GIT_EDITOR=true git -C "$REPO" rebase --continue >/dev/null 2>&1
check "regenerating on the new base clears the distance" \
  "$(git -C "$REPO" rev-list --count 'feature..main')" "0"

group "7. the skill prescribes the distance check, not the file list"
check "counts commits between HEAD and the base" \
  "$(grep -cF 'git rev-list --count "HEAD..origin/$BASE"' "$SKILL")" "1"
check "warns against the file-list test" \
  "$(grep -ci 'the file list is not' "$SKILL")" "1"
check "names the zero-step signature of a run that never started" \
  "$(grep -c 'steps=0' "$SKILL")" "1"

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
