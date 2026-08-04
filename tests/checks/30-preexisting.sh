#!/bin/sh
# An account that came with its own ~/.bash_profile is the one case where
# `make install` alone is not enough: bash reads ~/.bash_profile *instead of*
# ~/.profile, rcm leaves a file that already exists alone, and the scripts stay
# out of reach until `make force` replaces it.
#
# Fedora and Amazon Linux seed such a file, and so does the GitHub Actions
# Ubuntu runner -- stock Ubuntu and macOS do not. Both halves of the behaviour
# are deliberate, so this checks them instead of working around them.
#
# The check brings its own home directory: it must not disturb the one the
# other checks look at.

set -u

. "$(dirname -- "$0")/../lib.sh"

other=$(mktemp -d "${TMPDIR:-/tmp}/scriptlets-preexisting.XXXXXX")

(
    HOME=$other
    export HOME

    # The shape those systems ship: a login file that reaches ~/.bashrc and
    # never looks at ~/.profile.
    printf '# .bash_profile\n[ -f ~/.bashrc ] && . ~/.bashrc\n' >"$HOME/.bash_profile"

    assert_ok "make install succeeds on such an account" \
        make -C "$REPO" install

    if [ -L "$HOME/.bash_profile" ]; then
        fail "make install keeps the ~/.bash_profile the account came with" \
            "replaced by $(readlink "$HOME/.bash_profile")"
    else
        pass "make install keeps the ~/.bash_profile the account came with"
    fi

    assert_ok "make force succeeds on such an account" \
        make -C "$REPO" force

    assert_in_path "bash: ~/bin is on the PATH once make force replaced it" \
        "$HOME/bin" "$(login_path bash)"
)

rm -rf "$other"
