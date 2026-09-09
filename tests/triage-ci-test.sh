#!/usr/bin/env bash
#
# Guards the log-filtering command that triage-ci prescribes.
#
# GitHub's log API returns colour codes as LITERAL caret notation (^[[31m),
# not as ESC bytes. Every ESC-based strip therefore matches nothing and passes
# the text through unchanged — looking exactly like it worked. This pins both
# the behavior and the documentation, since a plausible-looking "fix" to the
# skill would silently do nothing.
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

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
