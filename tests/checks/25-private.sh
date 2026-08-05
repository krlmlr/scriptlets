#!/bin/sh
# A private sidecar repository: a second dotfiles tree, merged into the same
# home directory (handbook/layout/private/README.md).
#
# rcm reads exactly one rcrc and applies DOTFILES_DIRS, UNDOTTED and TAGS to
# every tree it walks, so a sidecar cannot ship its own -- rcm/rcrc sources the
# fragment at the sidecar's root instead. That merge is what most of this
# checks, because it is the part rcm does not do itself.
#
# The check brings its own home directory and its own sidecar: it must not
# disturb the home directory the other checks look at, and the machine running
# it may well have a real sidecar that would otherwise take part.

set -u

. "$(dirname -- "$0")/../lib.sh"

other=$(mktemp -d "${TMPDIR:-/tmp}/scriptlets-private-home.XXXXXX")
side=$(mktemp -d "${TMPDIR:-/tmp}/scriptlets-private-repo.XXXXXX")

mkdir -p "$side/rcm/ssh" "$side/rcm/keys" "$side/rcm/hooks"

# A file the public tree does not have, in a seam it does declare.
printf '# private\n' >"$side/rcm/ssh/config-private"

# A top-level name the public UNDOTTED does not list: it keeps its spelling
# only if the fragment below is read, and only if it appends.
printf 'key\n' >"$side/rcm/keys/id"

# A name both trees have. The sidecar is walked first, so this one wins.
printf '# private tigrc\n' >"$side/rcm/tigrc"

printf 'UNDOTTED="$UNDOTTED keys"\n' >"$side/rcrc"

printf '#!/bin/sh\ntouch "$HOME/.sidecar-hook-ran"\n' >"$side/rcm/hooks/post-up"
chmod +x "$side/rcm/hooks/post-up"

(
    HOME=$other
    SCRIPTLETS_PRIVATE=$side
    export HOME SCRIPTLETS_PRIVATE

    assert_ok "mise run install succeeds with a sidecar" \
        mise -C "$REPO" run install

    assert_equal "a file only the sidecar has is installed" \
        "$side/rcm/ssh/config-private" \
        "$(readlink "$HOME/.ssh/config-private" 2>&1)"

    # The whole point of the fragment. rcm has a `<dir>:<glob>` syntax that
    # looks like it would scope UNDOTTED to one tree, but it reads the variable
    # as a single word, so one scoped entry silences every plain one -- which
    # is why the sidecar appends to the list rather than being given its own.
    if [ -e "$HOME/keys/id" ]; then
        pass "the sidecar's rcrc extends UNDOTTED"
    elif [ -e "$HOME/.keys/id" ]; then
        fail "the sidecar's rcrc extends UNDOTTED" "installed as ~/.keys/id"
    else
        fail "the sidecar's rcrc extends UNDOTTED" "not installed at all"
    fi

    assert_equal "the sidecar wins a name both trees have" \
        "$side/rcm/tigrc" "$(readlink "$HOME/.tigrc" 2>&1)"

    # ~/.rcrc is the one file that must keep coming from the public tree, and
    # the sidecar is walked ahead of it.
    assert_equal "~/.rcrc still comes from the public tree" \
        "$REPO/rcm/rcrc" "$(readlink "$HOME/.rcrc" 2>&1)"

    if [ -e "$HOME/.sidecar-hook-ran" ]; then
        pass "the sidecar's own rcm hooks run"
    else
        fail "the sidecar's own rcm hooks run" "the hook left no marker"
    fi

    if [ -e "$HOME/.hooks" ]; then
        fail "the sidecar's hooks directory is not installed" "~/.hooks exists"
    else
        pass "the sidecar's hooks directory is not installed"
    fi

    # Forgetting the sidecar here would strand every link it owns: nothing
    # prunes (handbook/layout/mapping/README.md).
    assert_ok "mise run uninstall succeeds with a sidecar" \
        mise -C "$REPO" run uninstall

    if [ -L "$HOME/.ssh/config-private" ]; then
        fail "mise run uninstall removes the sidecar's links too" \
            "$(ls -l "$HOME/.ssh/config-private" 2>&1)"
    else
        pass "mise run uninstall removes the sidecar's links too"
    fi
)

# An `rcrc` under the sidecar's rcm/ installs as ~/.rcrc, from the tree that is
# walked first -- so it would replace the file that configures rcm with the
# fragment that only extends it. The tasks refuse instead.
printf 'UNDOTTED="$UNDOTTED keys"\n' >"$side/rcm/rcrc"

if HOME=$other SCRIPTLETS_PRIVATE=$side mise -C "$REPO" run check >/dev/null 2>&1; then
    fail "an rcrc under the sidecar's rcm/ is refused" "the task ran anyway"
else
    pass "an rcrc under the sidecar's rcm/ is refused"
fi

rm -rf "$other" "$side"

# Which trees rcm acts on is decided in one place, and a task calling rcm
# directly would decide it again for itself -- an install that saw the sidecar
# and an uninstall that did not would strand every link the sidecar owns. The
# tests above cannot catch that: they exercise the tasks that go through
# rcm_run, not the one that stopped.
direct=
for script in "$REPO"/mise-tasks/*; do
    [ -x "$script" ] || continue

    if grep -Eq '^[[:space:]]*(exec[[:space:]]+)?(rcup|lsrc|rcdn)[[:space:]]' "$script"; then
        direct="$direct ${script##*/}"
    fi
done

if [ -z "$direct" ]; then
    pass "every task reaches rcm through rcm_run"
else
    fail "every task reaches rcm through rcm_run" "calls rcm directly:$direct"
fi
