#!/bin/sh
# The scripts must be reachable by name in a login shell, with nothing
# configured by hand. This is the property that quietly did not hold on macOS:
# a default installation puts no directory below $HOME on the PATH, because
# /usr/libexec/path_helper only ever reads /etc/paths and /etc/paths.d.
#
# The shells covered are the ones a fresh account may log in with: bash is the
# default on Ubuntu, zsh on macOS since Catalina, and /bin/sh stands in for
# everything that reads ~/.profile alone.

set -u

. "$(dirname -- "$0")/../lib.sh"

for shell in sh bash zsh; do
    if ! command -v "$shell" >/dev/null 2>&1; then
        skip "$shell: not installed"
        continue
    fi

    path=$(login_path "$shell")

    assert_in_path "$shell: ~/bin is on the PATH of a login shell" \
        "$HOME/bin" "$path"

    unresolved=
    for script in "$REPO"/rcm/bin/*; do
        name=${script##*/}
        resolved=$(
            PATH=$path
            command -v "$name" 2>/dev/null || true
        )
        if [ "$resolved" != "$HOME/bin/$name" ]; then
            unresolved="$unresolved $name"
        fi
    done

    if [ -z "$unresolved" ]; then
        pass "$shell: every script in rcm/bin resolves to ~/bin"
    else
        fail "$shell: every script in rcm/bin resolves to ~/bin" \
            "not resolved:$unresolved"
    fi
done

# Beyond being found, a script has to run. `g` forwards to git, which every
# machine running these checks has.
#
# Both versions are read inside the login shell, not one there and one here:
# the git a login shell finds is not always the git this script finds. On macOS
# it is Apple's, while the checkout was made with the one from Homebrew.
git_version=$(login_output bash 'git --version')

if [ -z "$git_version" ]; then
    fail "a script found on the PATH runs" "a login shell finds no git at all"
else
    assert_equal "a script found on the PATH runs" \
        "$git_version" "$(login_output bash 'g --version')"
fi
