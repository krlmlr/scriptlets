#!/bin/sh
# `make force` replaces the files rcm skipped because the account already had
# them -- on Ubuntu that is the handful seeded from /etc/skel, notably
# ~/.profile and ~/.bashrc. The scripts must still be found afterwards, which
# is the configuration a macOS account is in from the start: every file in the
# home directory comes from this repository.
#
# This check runs last on purpose: it is the only one that replaces files the
# earlier checks look at.

set -u

. "$(dirname -- "$0")/../lib.sh"

assert_ok "make force succeeds" make -C "$REPO" force

for name in profile zprofile bashrc bash_profile; do
    dest=$HOME/.$name
    if [ "$(readlink "$dest" 2>/dev/null)" = "$REPO/rcm/$name" ]; then
        pass "make force links ~/.$name into the repository"
    else
        fail "make force links ~/.$name into the repository" \
            "$(ls -l "$dest" 2>&1)"
    fi
done

for shell in sh bash zsh; do
    if ! command -v "$shell" >/dev/null 2>&1; then
        skip "$shell: not installed"
        continue
    fi

    assert_in_path "$shell: ~/bin is still on the PATH after make force" \
        "$HOME/bin" "$(login_path "$shell")"
done
