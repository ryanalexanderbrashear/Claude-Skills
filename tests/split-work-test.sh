#!/usr/bin/env bash
#
# Regression tests for the git mechanics the split-work skill prescribes.
#
# These guard the non-obvious parts: the --unidiff-zero requirement, the
# content-equivalence check, and the --force-with-lease behavior that makes
# "fetch first to be safe" actively dangerous.
#
# Usage: ./tests/split-work-test.sh

set -uo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

passed=0
failed=0
ok()    { printf '  \033[32mok\033[0m   %s\n' "$1"; passed=$((passed + 1)); }
bad()   { printf '  \033[31mFAIL\033[0m %s\n' "$1"; failed=$((failed + 1)); }
check() { if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi; }
group() { printf '\n%s\n' "$1"; }

newrepo() {
  local d="$1"; rm -rf "$d"; mkdir -p "$d"; cd "$d" || exit 1
  git init -q -b main .; git config user.email t@t; git config user.name T
  git config commit.gpgsign false
}

group "1. split one commit into two, content preserved"
newrepo "$WORK/r1"
echo base > a.txt; echo base > b.txt; git add -A; git commit -qm base
RESCUE_PARENT=$(git rev-parse HEAD)
echo A >> a.txt; echo B >> b.txt; git add -A; git commit -qm "two concerns"
RESCUE=$(git rev-parse HEAD)
git reset --soft HEAD~1; git restore --staged b.txt; git commit -qm "change a"
git add b.txt; git commit -qm "change b"
check "produces two commits" "$(git rev-list --count "$RESCUE_PARENT"..HEAD)" "2"
check "content identical to the original" "$(git diff "$RESCUE" HEAD | wc -l | tr -d ' ')" "0"

group "2. split a mixed branch into two"
newrepo "$WORK/r2"
echo base > a.txt; echo base > b.txt; git add -A; git commit -qm base
git checkout -qb mixed
echo x1 >> a.txt; git commit -aqm "work X1"
echo y1 >> b.txt; git commit -aqm "work Y1"
echo x2 >> a.txt; git commit -aqm "work X2"
XS=$(git log --format='%H %s' main..mixed | grep ' work X' | awk '{print $1}' | tail -r 2>/dev/null || \
     git log --format='%H %s' main..mixed | grep ' work X' | awk '{print $1}' | tac)
git checkout -q -B only-x main
for c in $XS; do git cherry-pick "$c" >/dev/null 2>&1 || bad "cherry-pick conflicted on $c"; done
YS=$(git log --format='%H %s' main..mixed | grep ' work Y' | awk '{print $1}')
git checkout -q -B only-y main; git cherry-pick "$YS" >/dev/null 2>&1
check "only-x has both X commits" "$(git rev-list --count main..only-x)" "2"
check "only-y has the Y commit" "$(git rev-list --count main..only-y)" "1"
check "every original commit is accounted for" \
  "$(( $(git rev-list --count main..only-x) + $(git rev-list --count main..only-y) ))" \
  "$(git rev-list --count main..mixed)"

group "3. stage one hunk of a two-hunk file"
newrepo "$WORK/r3"
printf 'one\ntwo\nthree\n' > c.txt; git add -A; git commit -qm base
printf 'ONE\ntwo\nTHREE\n' > c.txt
check "default context merges the edits into one hunk" "$(git diff c.txt | grep -c '^@@')" "1"
check "-U0 separates them" "$(git diff -U0 c.txt | grep -c '^@@')" "2"
git diff -U0 c.txt > "$WORK/all.patch"
head -4 "$WORK/all.patch" > "$WORK/one.patch"
awk '/^@@/{n++} n==1' "$WORK/all.patch" >> "$WORK/one.patch"
git apply --cached "$WORK/one.patch" 2>/dev/null
check "apply --cached FAILS without --unidiff-zero" "$(git diff --cached -U0 | grep -c '^@@')" "0"
git apply --cached --unidiff-zero "$WORK/one.patch" 2>/dev/null
check "apply --cached succeeds WITH --unidiff-zero" "$(git diff --cached -U0 | grep -c '^@@')" "1"
check "the other hunk stays unstaged" "$(git diff -U0 c.txt | grep -c '^@@')" "1"

group "4. reflog recovers a destructive reset"
newrepo "$WORK/r4"
echo one > f.txt; git add -A; git commit -qm one
echo two >> f.txt; git commit -aqm two
LOST=$(git rev-parse --short HEAD)
git reset --hard -q HEAD~1
check "commit is gone from HEAD" "$(git rev-parse --short HEAD)" "$(git rev-parse --short HEAD)"
check "but reachable in the reflog" "$([ "$(git reflog | grep -c "$LOST")" -gt 0 ] && echo yes)" "yes"
git reset --hard -q "$LOST"
check "recovered by SHA" "$(git rev-parse --short HEAD)" "$LOST"

group "5. --force-with-lease: fetching defeats the protection"
REMOTE="$WORK/remote.git"
git init -q --bare -b main "$REMOTE"          # -b main: a bare repo defaults to master
newrepo "$WORK/c1"; git remote add origin "$REMOTE"
echo one > f.txt; git add -A; git commit -qm c1; git push -q -u origin main
cd "$WORK" || exit 1; git clone -q "$REMOTE" c2; cd c2 || exit 1
git config user.email t@t; git config user.name T
echo two >> f.txt; git commit -aqm "teammate work"; git push -q
TEAMMATE=$(git rev-parse HEAD)
check "fixture: teammate commit is on the remote" \
  "$(git --git-dir="$REMOTE" log --format=%H main | grep -c "$TEAMMATE")" "1"

cd "$WORK/c1" || exit 1
git commit -aqm "my rewrite" --allow-empty
out=$(git push --force-with-lease 2>&1)
check "rejected while the tracking ref is stale" "$(grep -c 'stale info' <<<"$out")" "1"

# The divergence check the skill prescribes: ls-remote reads the remote WITHOUT
# updating the tracking ref, so it still sees the teammate's commit.
REMOTE_SHA=$(git ls-remote origin refs/heads/main | awk '{print $1}')
STALE_SHA=$(git rev-parse origin/main)
check "ls-remote sees divergence that the stale tracking ref hides" \
  "$([ "$REMOTE_SHA" != "$STALE_SHA" ] && echo differs)" "differs"
check "and the remote SHA is the teammate's commit" "$REMOTE_SHA" "$TEAMMATE"

git fetch -q
git push --force-with-lease >/dev/null 2>&1
check "SUCCEEDS after a fetch — the trap" "$?" "0"
check "the teammate's commit is now gone from the remote" \
  "$(git --git-dir="$REMOTE" log --format=%H main | grep -c "$TEAMMATE")" "0"

cd /
printf '\n%s passed, %s failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
