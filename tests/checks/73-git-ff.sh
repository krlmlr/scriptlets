#!/bin/sh
# `git ff` fast-forwards what can be fast-forwarded, by whichever of its two
# mechanisms the branch needs, and leaves the rest alone and named.
#
# The four states a branch can be in are built below and checked in one run:
# behind and checked out nowhere, behind and held by a linked worktree, held by
# a worktree with uncommitted changes, and diverged. The one that matters most
# is the second: `git push .` cannot touch it, which is the reason the script
# exists.
#
# Nothing here reaches the network. The "remote" is a second repository below
# $HOME and the clone is made from its path, so `git clone`, `git fetch` and
# the push into the repository itself all stay on this disk.

set -u

. "$(dirname -- "$0")/../lib.sh"

PATH="$HOME/bin:$PATH"
export PATH

# The throw-away home has no git identity, and neither does a CI runner: the
# repository's ~/.gitconfig only carries one for an account with a tag.
GIT_AUTHOR_NAME=check
GIT_AUTHOR_EMAIL=check@example
GIT_COMMITTER_NAME=check
GIT_COMMITTER_EMAIL=check@example
export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

work=$HOME/git-ff-check
rm -rf "$work"
mkdir -p "$work"

remote=$work/remote
clone=$work/clone

# --- a repository in every state the script distinguishes --------------------

git init -q -b main "$remote"
printf 'base\n' >"$remote/file"
git -C "$remote" add file
git -C "$remote" commit -q -m base

for branch in idle held dirty diverged; do
    git -C "$remote" switch -q -c "$branch" main
    printf '%s\n' "$branch" >>"$remote/file"
    git -C "$remote" commit -q -am "$branch"
done
git -C "$remote" switch -q main

git clone -q "$remote" "$clone"

# Each branch one commit behind the remote, and then the remote one ahead
# again, so that every one of them is behind by two.
for branch in idle held dirty diverged; do
    git -C "$clone" switch -q -c "$branch" "origin/$branch"
    git -C "$clone" reset -q --hard HEAD~1
done
git -C "$clone" switch -q main

for branch in idle held dirty diverged; do
    git -C "$remote" switch -q "$branch"
    printf 'more\n' >>"$remote/file"
    git -C "$remote" commit -q -am "$branch again"
done
git -C "$remote" switch -q main
git -C "$clone" fetch -q --all

git -C "$clone" worktree add -q "$work/held" held
git -C "$clone" worktree add -q "$work/dirty" dirty
printf 'uncommitted\n' >"$work/dirty/scratch"

git -C "$clone" switch -q diverged
printf 'local\n' >>"$clone/file"
git -C "$clone" commit -q -am "a commit the remote does not have"
git -C "$clone" switch -q main

# tracking BRANCH -- what `git branch -vv` says about it, upstream and all.
tracking() {
    git -C "$clone" for-each-ref --format='%(upstream:track,nobracket)' \
        "refs/heads/$1"
}

run() {
    output=$(git -C "$clone" ff "$@" 2>&1)
    status=$?
}

# --- the dry run says what it would do, and does none of it ------------------

run --dry-run
assert_equal "--dry-run succeeds" "0" "$status"
assert_match "it would push the branch nothing has checked out" \
    "*would push idle*" "$output"
assert_match "it would merge the branch a worktree holds" \
    "*would merge held*" "$output"
assert_equal "and it changed nothing" "behind 2" "$(tracking idle)"

# --- the run itself ----------------------------------------------------------

run
assert_equal "the run succeeds" "0" "$status"

assert_equal "a branch checked out nowhere reaches its upstream" "" \
    "$(tracking idle)"
assert_equal "so does one a linked worktree holds" "" "$(tracking held)"
assert_equal "and that worktree is at the new commit" \
    "$(git -C "$clone" rev-parse held)" "$(git -C "$work/held" rev-parse HEAD)"
assert_equal "with nothing left uncommitted in it" "" \
    "$(git -C "$work/held" status --porcelain)"

# The two it must not touch, and the reason it says so out loud: a branch left
# behind without a word is indistinguishable from one that was up to date.
assert_equal "a worktree with uncommitted changes is left behind" "behind 2" \
    "$(tracking dirty)"
assert_match "and named" "*dirty*$work/dirty*" "$output"
assert_equal "the file it had uncommitted is still there" "uncommitted" \
    "$(cat "$work/dirty/scratch")"

assert_equal "a diverged branch is left alone" "ahead 1, behind 2" \
    "$(tracking diverged)"
assert_equal "and is not mentioned" "" \
    "$(printf '%s\n' "$output" | grep diverged || true)"

# --- a second run --------------------------------------------------------

run
assert_equal "a second run succeeds" "0" "$status"
assert_equal "and fast-forwards nothing more" "" \
    "$(printf '%s\n' "$output" | grep -E 'pushed|merged' || true)"

# --- where it refuses -------------------------------------------------------

run --nonsense
assert_equal "an unknown option fails" "1" "$status"
assert_match "an unknown option prints the usage" "*Usage:*" "$output"
