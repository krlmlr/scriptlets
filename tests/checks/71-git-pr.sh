#!/bin/sh
# What `git pr` would run, checked without running any of it.
#
# `--dry-run` is what makes that possible, and everything worth checking is
# visible in it: the title comes from the first commit rather than the last,
# the `Closes` lines come from the branch name, and the trailing field of that
# name is a suffix rather than an issue number.
#
# Nothing here reaches GitHub. The repository is a throw-away one below $HOME,
# its remote is a name that is never contacted, and the default branch is
# written into the ref by hand -- `git remote set-head --auto` is the command
# that would ask the network for it.

set -u

. "$(dirname -- "$0")/../lib.sh"

PATH="$HOME/bin:$PATH"
export PATH

work=$HOME/git-pr-check
rm -rf "$work"
git init -q "$work"

git -C "$work" remote add origin git@github.com:krlmlr/scriptlets.git
git -C "$work" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

commit() {
    printf '%s\n' "$2" >"$work/file"
    git -C "$work" add file
    git -C "$work" commit -q -m "$1"
}

commit "base" one
git -C "$work" update-ref refs/remotes/origin/main HEAD

run() {
    output=$(git -C "$work" pr --dry-run "$@" 2>&1)
    status=$?
}

# --- a branch with an issue number ------------------------------------------

git -C "$work" switch -q -c topic-41-qkxmvp
commit "feat: the subject that becomes the title" two
commit "the second commit, which must not" three

run
assert_equal "--dry-run succeeds" "0" "$status"
assert_match "the branch is pushed with its upstream set" \
    "*git push --set-upstream origin HEAD*" "$output"
assert_match "the pull request is filled from the commits" \
    "*gh pr create --fill*" "$output"
assert_match "the title is the first commit's subject" \
    "*--title 'feat: the subject that becomes the title'*" "$output"
assert_match "the issue in the branch name is closed" "*--body 'Closes #41.'*" \
    "$output"
assert_match "and nothing is merged without being asked" "" \
    "$(printf '%s\n' "$output" | grep 'gh pr merge' || true)"

run --auto-merge
assert_match "--auto-merge ends in an auto-merge" "*gh pr merge --auto --squash*" \
    "$output"

# --- a branch without one ---------------------------------------------------

# The body `--fill` wrote from the commits is worth more than an empty one, so
# a branch name that yields no `Closes` line leaves it alone.
git -C "$work" switch -q -c a-branch-named-for-nothing refs/remotes/origin/main
commit "fix: something the branch name does not number" four

run
assert_match "a name without a number still gets a title" "*--title 'fix:*" \
    "$output"
assert_equal "and no body at all" "0" \
    "$(printf '%s\n' "$output" | grep -c -- '--body' | tr -d ' ')"

# The last field disambiguates two branches about the same issue, so it is a
# suffix even when it is a number.
git -C "$work" switch -q -c topic-2 refs/remotes/origin/main
commit "docs: a branch whose last field is a number" five

run
assert_equal "the trailing field is a suffix, not an issue" "" \
    "$(printf '%s\n' "$output" | grep -o -- '--body.*' || true)"

# --- where it refuses -------------------------------------------------------

run --nonsense
assert_equal "an unknown option fails" "1" "$status"
assert_match "an unknown option prints the usage" "*Usage:*" "$output"

git -C "$work" switch -q --detach refs/remotes/origin/main
output=$(git -C "$work" pr --dry-run 2>&1)
status=$?
assert_equal "a branch with no commits of its own fails" "1" "$status"
assert_match "and says so" "*no commits*" "$output"
