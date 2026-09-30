#!/usr/bin/env bash
#
# Guards the one step in start-project that fails silently.
#
# A plan's work items are numbered 1..N. The issues created from them get whatever
# numbers the tracker assigns, and on GitHub that sequence is shared with pull
# requests and continues from whatever the repository already holds. So item N is
# almost never issue N — but wiring `--add-blocked-by` as if it were still names a
# REAL issue, so the API accepts it, nothing errors, and the graph reads as correct
# while pointing at unrelated work.
#
# Group 2 builds that exact situation and proves the naive resolution produces wrong
# edges that no error would reveal. Group 3 proves the mapped resolution is right.
# Group 4 pins what the skill prescribes, so a plausible-looking simplification of
# the two-pass rule cannot land quietly.
#
# Usage: ./tests/start-project-test.sh

set -uo pipefail

SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/start-project/SKILL.md"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

passed=0
failed=0
ok()    { printf '  \033[32mok\033[0m   %s\n' "$1"; passed=$((passed + 1)); }
bad()   { printf '  \033[31mFAIL\033[0m %s\n' "$1"; failed=$((failed + 1)); }
check() { if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi; }
group() { printf '\n%s\n' "$1"; }

# A plan table in the shape docs/project-template.md prescribes: item 2 depends on 1,
# item 3 on 2, item 4 on 1 and 2.
cat > "$WORK/plan.md" <<'PLAN'
| # | Work item | Milestone | Depends on | Status |
| --- | --- | --- | --- | --- |
| 1 | Walking skeleton | M1 | — | Not started |
| 2 | Persist a record | M1 | 1 | Not started |
| 3 | Read it back | M1 | 2 | Not started |
| 4 | Delete it | M2 | 1, 2 | Not started |
PLAN

# What the tracker actually assigned. The repository already had issues and a pull
# request, so creation started at 7 and skipped 9 — the ordinary case, not a contrived
# one.
cat > "$WORK/mapping.tsv" <<'MAP'
1	7
2	8
3	10
4	11
MAP

group "1. the fixture is the shape the template prescribes"
check "four work items parsed" \
  "$(awk -F'|' 'NF>5 && $2+0>0 {n++} END{print n+0}' "$WORK/plan.md")" "4"
check "four dependency edges in the plan" \
  "$(awk -F'|' 'NF>5 && $2+0>0 {gsub(/[^0-9,]/,"",$5); if ($5!="") {n+=gsub(/,/,",",$5)+1}} END{print n+0}' "$WORK/plan.md")" "4"
check "no issue number equals its item number" \
  "$(awk '$1==$2 {n++} END{print n+0}' "$WORK/mapping.tsv")" "0"

group "2. resolving without the mapping produces wrong edges, and no error"
# The naive pass: treat the plan's number as the issue number.
awk -F'|' 'NF>5 && $2+0>0 {
  item=$2+0; deps=$5; gsub(/[^0-9,]/,"",deps)
  if (deps=="") next
  n=split(deps,d,",")
  for (i=1;i<=n;i++) if (d[i]!="") print item"\t"d[i]
}' "$WORK/plan.md" > "$WORK/naive.tsv"
check "the naive pass emits an edge for every dependency" "$(wc -l < "$WORK/naive.tsv" | tr -d ' ')" "4"
# Every number it emits is a plausible issue number, which is why nothing complains.
check "every naive edge names a low, real-looking issue number" \
  "$(awk '$1<=11 && $2<=11 {n++} END{print n+0}' "$WORK/naive.tsv")" "4"
# And every one of them is wrong.
correct=$(awk 'NR==FNR{m[$1]=$2; next} {print m[$1]"\t"m[$2]}' "$WORK/mapping.tsv" "$WORK/naive.tsv" | sort)
wrong=$(comm -13 <(printf '%s\n' "$correct") <(sort "$WORK/naive.tsv") | wc -l | tr -d ' ')
check "all four naive edges differ from the correct ones" "$wrong" "4"

group "3. resolving through the mapping is right"
printf '%s\n' "$correct" > "$WORK/mapped.tsv"
check "same number of edges" "$(grep -c . "$WORK/mapped.tsv")" "4"
check "item 2 blocked by item 1 becomes issue 8 blocked by issue 7" \
  "$(grep -c '^8	7$' "$WORK/mapped.tsv")" "1"
check "item 3 blocked by item 2 becomes issue 10 blocked by issue 8" \
  "$(grep -c '^10	8$' "$WORK/mapped.tsv")" "1"
check "item 4's two blockers become issues 7 and 8" \
  "$(grep -cE '^11	(7|8)$' "$WORK/mapped.tsv")" "2"
check "no mapped edge names a number the tracker never assigned" \
  "$(awk '$1==9||$2==9||$1<7||$2<7 {n++} END{print n+0}' "$WORK/mapped.tsv")" "0"

group "4. the skill prescribes the two-pass rule and the read-back"
check "says dependencies are a second pass" \
  "$(grep -ci 'second pass' "$SKILL")" "1"
check "warns against assuming item N is issue N" \
  "$(grep -ci 'never by assuming item' "$SKILL")" "1"
check "requires the mapping to be recorded during creation" \
  "$(grep -ci 'Record the mapping' "$SKILL")" "1"
awk '/^```/{f=!f; next} f' "$SKILL" > "$WORK/blocks.txt"
# Presence in a RUNNABLE block, not a raw count: the flag is also named in Notes, and
# an exact total breaks whenever the prose changes without the command changing.
check "the dependency-writing flag is in a runnable code block" \
  "$([[ -n "$(grep -F -- '--add-blocked-by' "$WORK/blocks.txt")" ]] && echo yes)" "yes"
check "the read-back is in a runnable code block" \
  "$([[ -n "$(grep -F -- 'blockedBy,blocking' "$WORK/blocks.txt")" ]] && echo yes)" "yes"
# The same trap the other skills' tests guard: a filter or flag that silently does
# nothing, and interactive git, must not appear in a runnable block.
check "no known-broken construct in a runnable code block" \
  "$(grep -cE 'x1b|tail -r|git add -p|rebase -i' "$WORK/blocks.txt")" "0"

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
