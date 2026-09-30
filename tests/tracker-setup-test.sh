#!/usr/bin/env bash
#
# Guards the step in docs/tracker-setup.md that fails silently.
#
# A plan's work items are numbered 1..N. The tickets filed from them get whatever
# numbers the tracker assigns, and on GitHub that sequence is shared with pull
# requests and continues from whatever the repository already holds. So item N is
# almost never ticket N — but wiring `--add-blocked-by` as if it were still names a
# REAL ticket, so the API accepts it, nothing errors, and the graph reads as correct
# while pointing at unrelated work.
#
# Group 2 builds that situation and proves the naive resolution produces wrong edges
# that no error would reveal. Group 3 proves resolution through the recorded note is
# right. Group 4 pins what the doc and the skill prescribe, so a plausible-looking
# simplification of the three-pass rule cannot land quietly.
#
# Usage: ./tests/tracker-setup-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="$ROOT/docs/tracker-setup.md"
SKILL="$ROOT/plan-project/SKILL.md"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

passed=0
failed=0
ok()    { printf '  \033[32mok\033[0m   %s\n' "$1"; passed=$((passed + 1)); }
bad()   { printf '  \033[31mFAIL\033[0m %s\n' "$1"; failed=$((failed + 1)); }
check() { if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi; }
group() { printf '\n%s\n' "$1"; }

# A breakdown of four items. Item 4 is blocked by 1 and 2; item 3 by 2.
cat > "$WORK/items.tsv" <<'ITEMS'
1	Walking skeleton	M1
2	Persist a record	M1	1
3	Read it back	M1	2
4	Delete it	M2	1,2
ITEMS

# What the tracker actually assigned: the repository already had issues and a pull
# request, so filing started at 7 and skipped 9. The ordinary case, not a contrived one.
cat > "$WORK/note.tsv" <<'MAP'
1	7
2	8
3	10
4	11
MAP

group "1. the fixture is an ordinary breakdown"
check "four items" "$(grep -c . "$WORK/items.tsv")" "4"
check "four dependency edges" \
  "$(awk -F'\t' '$4!="" {n+=gsub(/,/,",",$4)+1} END{print n+0}' "$WORK/items.tsv")" "4"
check "no ticket number equals its item number" \
  "$(awk '$1==$2 {n++} END{print n+0}' "$WORK/note.tsv")" "0"

group "2. resolving by arithmetic produces wrong edges, and no error"
awk -F'\t' '$4!="" {n=split($4,d,","); for(i=1;i<=n;i++) print $1"\t"d[i]}' \
  "$WORK/items.tsv" > "$WORK/naive.tsv"
check "an edge for every dependency" "$(grep -c . "$WORK/naive.tsv")" "4"
# Every number it emits is a plausible ticket number, which is why nothing complains.
check "every naive edge names a real-looking ticket" \
  "$(awk '$1>=1 && $1<=11 && $2>=1 && $2<=11 {n++} END{print n+0}' "$WORK/naive.tsv")" "4"
correct=$(awk 'NR==FNR{m[$1]=$2; next} {print m[$1]"\t"m[$2]}' "$WORK/note.tsv" "$WORK/naive.tsv" | sort)
wrong=$(comm -13 <(printf '%s\n' "$correct") <(sort "$WORK/naive.tsv") | grep -c .)
check "all four naive edges differ from the correct ones" "$wrong" "4"

group "3. resolving through the recorded note is right"
printf '%s\n' "$correct" > "$WORK/mapped.tsv"
check "same number of edges" "$(grep -c . "$WORK/mapped.tsv")" "4"
check "item 2 blocked by 1 becomes ticket 8 blocked by 7" \
  "$(grep -c '^8	7$' "$WORK/mapped.tsv")" "1"
check "item 3 blocked by 2 becomes ticket 10 blocked by 8" \
  "$(grep -c '^10	8$' "$WORK/mapped.tsv")" "1"
check "item 4's two blockers become tickets 7 and 8" \
  "$(grep -cE '^11	(7|8)$' "$WORK/mapped.tsv")" "2"
check "no mapped edge names a number the tracker never assigned" \
  "$(awk '$1==9||$2==9||$1<7||$2<7 {n++} END{print n+0}' "$WORK/mapped.tsv")" "0"

group "4. the doc prescribes three passes, the note, and the read-back"
check "names the three passes" "$(grep -ci 'three passes' "$DOC")" "1"
check "says a dependency cannot name a ticket that does not exist" \
  "$(grep -ci 'cannot name a ticket that does not exist' "$DOC")" "1"
# Matched on a fragment that cannot wrap: the full sentence breaks across two lines,
# and grep is line-based, so the longer phrase fails against a doc that says it.
check "requires the item-to-ticket note during filing" \
  "$(grep -ci 'note which ticket number' "$DOC")" "1"
check "forbids resolving by arithmetic" \
  "$(grep -ci 'never resolve a dependency by arithmetic' "$DOC")" "1"
check "requires the graph to be read back" "$(grep -ci 'read the graph back' "$DOC")" "1"
awk '/^```/{f=!f; next} f' "$DOC" > "$WORK/blocks.txt"
check "the dependency-writing flag is in a runnable code block" \
  "$([[ -n "$(grep -F -- '--add-blocked-by' "$WORK/blocks.txt")" ]] && echo yes)" "yes"
check "the read-back command is in a runnable code block" \
  "$([[ -n "$(grep -F -- 'blockedBy,blocking' "$WORK/blocks.txt")" ]] && echo yes)" "yes"
check "no known-broken construct in a runnable code block" \
  "$(grep -cE 'x1b|tail -r|git add -p|rebase -i' "$WORK/blocks.txt")" "0"

group "5. plan-project routes to the doc rather than restating it"
check "step 4 names the three passes" "$(grep -ci 'three passes' "$SKILL")" "1"
check "step 4 points at the doc" "$(grep -cF 'docs/tracker-setup.md' "$SKILL")" "2"
check "the template no longer says to link while filing" \
  "$(grep -ci 'Set the dependencies as the' "$ROOT/docs/project-template.md")" "0"

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
