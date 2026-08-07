#!/bin/sh
# What `gh-repo-setup` would run, checked without running any of it.
#
# The logic under the two `gh` lines is the reading of a remote URL: which
# remote is asked, and how owner and name are recovered from every spelling a
# remote comes in. `--dry-run` puts both on stdout, so the check reads them
# there rather than at GitHub.
#
# Nothing here reaches GitHub, and nothing here needs `gh` installed: the
# repository is a throw-away one below $HOME, and its remotes are never
# contacted.

set -u

. "$(dirname -- "$0")/../lib.sh"

PATH="$HOME/bin:$PATH"
export PATH

work=$HOME/gh-repo-setup-check
rm -rf "$work"
git init -q "$work"

run() {
    output=$(cd "$work" && gh-repo-setup --dry-run "$@" 2>&1)
    status=$?
}

# slug_of URL -- what the script makes of a remote spelled that way.
slug_of() {
    git -C "$work" remote remove origin 2>/dev/null || true
    git -C "$work" remote add origin "$1"
    run
    printf '%s\n' "$output" | sed -n 's/^gh repo set-default //p'
}

# --- reading the remote -----------------------------------------------------

assert_equal "an SSH remote" "krlmlr/scriptlets" \
    "$(slug_of git@github.com:krlmlr/scriptlets.git)"
assert_equal "an HTTPS remote" "krlmlr/scriptlets" \
    "$(slug_of https://github.com/krlmlr/scriptlets.git)"
assert_equal "an HTTPS remote carrying a credential" "krlmlr/scriptlets" \
    "$(slug_of https://token@github.com/krlmlr/scriptlets)"
assert_equal "an ssh:// remote" "krlmlr/scriptlets" \
    "$(slug_of ssh://git@github.com/krlmlr/scriptlets.git)"
assert_equal "a remote without the .git suffix" "krlmlr/scriptlets" \
    "$(slug_of git@github.com:krlmlr/scriptlets)"

# A fork's `origin` is the fork, so the repository to configure is what
# `upstream` names wherever there is one.
git -C "$work" remote add upstream git@github.com:cynkra/scriptlets.git
run
assert_match "upstream wins over origin" "*gh repo set-default cynkra/scriptlets*" \
    "$output"
git -C "$work" remote remove upstream

# --- the options it sets ----------------------------------------------------

run
assert_equal "--dry-run succeeds" "0" "$status"
assert_match "the repository is addressed by owner and name" \
    "*gh repo edit krlmlr/scriptlets *" "$output"
assert_match "a pull request can be updated from the web" "*--allow-update-branch*" \
    "$output"
assert_match "a merged branch goes" "*--delete-branch-on-merge*" "$output"
assert_equal "and auto-merge stays off until it is asked for" "" \
    "$(printf '%s\n' "$output" | grep -o -- '--enable-auto-merge' || true)"

run --auto-merge
assert_match "--auto-merge enables it" "*--enable-auto-merge*" "$output"

# --- where it refuses -------------------------------------------------------

run --nonsense
assert_equal "an unknown option fails" "1" "$status"
assert_match "an unknown option prints the usage" "*Usage:*" "$output"

bare=$HOME/gh-repo-setup-check-remoteless
rm -rf "$bare"
git init -q "$bare"
output=$(cd "$bare" && gh-repo-setup --dry-run 2>&1)
status=$?
assert_equal "a repository without remotes fails" "1" "$status"
assert_match "and says which remotes it looked for" "*upstream or origin*" "$output"
