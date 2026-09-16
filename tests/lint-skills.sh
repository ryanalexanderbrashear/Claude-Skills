#!/usr/bin/env bash
#
# Lints this repo's own conventions, which are documented in
# docs/skill-template.md and enforced nowhere else.
#
# These checks are mechanical on purpose. Anything needing judgement — whether a
# skill has quietly grown two jobs, whether a description competes with its
# neighbour — is a review question, not a lint. The one judgement-shaped measure
# here (description overlap) reports as a warning and never fails the build.
#
# Usage: ./tests/lint-skills.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

passed=0
failed=0
ok()    { printf '  \033[32mok\033[0m   %s\n' "$1"; passed=$((passed + 1)); }
bad()   { printf '  \033[31mFAIL\033[0m %s\n' "$1"; failed=$((failed + 1)); }
check() { if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi; }
group() { printf '\n%s\n' "$1"; }
warn()  { printf '  \033[33mwarn\033[0m %s\n' "$1"; }

# See the length check below for how these two are calibrated.
SKILL_LINE_LIMIT=300
SKILL_LINE_NOTICE=220

skills=()
for d in */; do
  d="${d%/}"
  [[ -f "$d/SKILL.md" ]] && skills+=("$d")
done

group "skills found"
check "at least one skill folder" "$([[ ${#skills[@]} -gt 0 ]] && echo yes)" "yes"
printf '  %s\n' "${skills[*]}"

for d in "${skills[@]}"; do
  f="$d/SKILL.md"
  group "$d"

  # Frontmatter: name must match the folder, and only name/description allowed.
  # docs/skill-template.md, "Section rules".
  name=$(awk -F': *' '/^name:/{print $2; exit}' "$f")
  check "frontmatter name matches folder" "$name" "$d"
  extra=$(awk 'NR>1 && /^---$/{exit} NR>1 && /^[a-z-]+:/{print $1}' "$f" | grep -cv '^name:\|^description:')
  check "no frontmatter fields beyond name and description" "$extra" "0"

  # The description is all the model sees when deciding to load the skill, so it
  # must say when to invoke, not only what it does.
  check "description present" "$(grep -c '^description:' "$f")" "1"
  check "description states a trigger" \
    "$(awk '/^description:/,/^---$/' "$f" | grep -ci 'use when\|use this when\|use it when')" "1"

  check "has an H1 title" "$([[ $(grep -c '^# ' "$f") -ge 1 ]] && echo yes)" "yes"
  for sec in "## When to use" "## Instructions" "## Guidelines"; do
    check "has section '$sec'" "$(grep -c "^$sec\$" "$f")" "1"
  done

  # Length is a proxy for "has this grown two jobs?", which is a judgement — so it
  # warns where judgement is wanted and fails only where the answer is obvious.
  #
  # The old single limit of 200 was calibrated when the longest skill was 191, and by
  # the time it was next measured `plan-project` was at 199 and `split-work` at 193:
  # two of ten within 4% of a ceiling that then had to be paid for out of unrelated
  # work. A limit the largest skills live against is a budget, not a smoke alarm.
  #
  # LIMIT is twice the median (~150), because a skill at twice the typical length is
  # plausibly two skills. NOTICE keeps the old number's signal without its veto.
  lines=$(grep -c '' "$f")
  if [[ $lines -ge $SKILL_LINE_LIMIT ]]; then
    bad "under $SKILL_LINE_LIMIT lines (is $lines)"
  elif [[ $lines -ge $SKILL_LINE_NOTICE ]]; then
    ok "under $SKILL_LINE_LIMIT lines (is $lines)"
    warn "$d is $lines lines — worth asking whether it has grown a second job"
  else
    ok "under $SKILL_LINE_LIMIT lines (is $lines)"
  fi

  check "listed in the README" "$(grep -c "^- \*\*$d\*\*" README.md)" "1"
done

group "shared docs"
for link in $(grep -o 'docs/[a-z-]*\.md' README.md | sort -u); do
  check "README link resolves: $link" "$([[ -f "$link" ]] && echo yes)" "yes"
done
for doc in $(git ls-files 'docs/*.md' 2>/dev/null); do
  check "tracked doc is linked from README: $doc" "$(grep -c "($doc)" README.md)" "1"
done

group "known shell traps in runnable code blocks"
# Each of these has already cost this repo a debugging session.
traps=0
for d in "${skills[@]}"; do
  hits=$(awk '/^```/{f=!f; next} f' "$d/SKILL.md" \
    | grep -nE 'x1b|tail -r|git add -p|rebase -i' \
    | grep -v 'GIT_SEQUENCE_EDITOR' || true)
  if [[ -n "$hits" ]]; then
    bad "$d contains a known-broken construct: $(head -1 <<<"$hits")"
    traps=$((traps + 1))
  fi
done
[[ $traps -eq 0 ]] && ok "no ESC-based strips, tail -r, git add -p, or bare rebase -i"

group "description overlap (warning only)"
# Selection runs off the description, so near-identical ones compete. This is a
# judgement call, so it reports and never fails.
python3 - "${skills[@]}" <<'PY' || true
import re, sys, itertools, pathlib
stop = set('the a an of to for and or in on with that it is use when user wants asks a not this'.split())
d = {}
for s in sys.argv[1:]:
    t = pathlib.Path(s, 'SKILL.md').read_text()
    m = re.search(r'^description: (.+?)(?=\n[a-z-]+:|\n---)', t, re.S | re.M)
    if m:
        d[s] = {w for w in re.findall(r'[a-z-]{4,}', ' '.join(m.group(1).split()).lower()) if w not in stop}
worst = sorted(((len(d[a] & d[b]), a, b) for a, b in itertools.combinations(sorted(d), 2)), reverse=True)[:1]
for n, a, b in worst:
    print(f"  \033[33mwarn\033[0m closest pair: {a} / {b} share {n} distinctive terms")
PY

printf '\n%s passed, %s failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
