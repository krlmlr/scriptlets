#!/bin/sh
# What `mise run install` promises, it delivers: every destination rcm lists is
# really there, the scripts are executable, and installing twice changes
# nothing.

set -u

. "$(dirname -- "$0")/../lib.sh"

mapping=$(mise -C "$REPO" run check 2>/dev/null)

missing=
for dest in $(printf '%s\n' "$mapping" | cut -d: -f1); do
    if [ ! -e "$dest" ]; then
        missing="$missing $dest"
    fi
done

if [ -z "$missing" ]; then
    pass "every destination rcm lists exists"
else
    fail "every destination rcm lists exists" "missing:$missing"
fi

# ~/.gitconfig is not part of /etc/skel anywhere, so it is always ours: a
# symbolic link, which is what makes editing a file in the repository take
# effect immediately.
if [ -L "$HOME/.gitconfig" ]; then
    pass "config files are symbolic links into the repository"
else
    fail "config files are symbolic links into the repository" \
        "$(ls -l "$HOME/.gitconfig" 2>&1)"
fi

# ~/log exists only because rcm/log/dummy drags it into being.
if [ -d "$HOME/log" ]; then
    pass "~/log is created"
else
    fail "~/log is created" "no such directory"
fi

not_executable=
for script in "$HOME"/bin/*; do
    if [ ! -x "$script" ]; then
        not_executable="$not_executable ${script##*/}"
    fi
done

if [ -z "$not_executable" ]; then
    pass "every script in ~/bin is executable"
else
    fail "every script in ~/bin is executable" "not executable:$not_executable"
fi

assert_ok "installing twice succeeds" mise -C "$REPO" run install
assert_equal "installing twice changes nothing" \
    "$mapping" "$(mise -C "$REPO" run check 2>/dev/null)"
