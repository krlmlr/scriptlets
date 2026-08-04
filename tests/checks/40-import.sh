#!/bin/sh
# `mise run import` moves a file out of the home directory into the repository
# and links it back.
#
# The interesting case is an UNDOTTED name. rcm's own `mkrc` moves ~/bin/foo to
# rcm/bin/foo and then links it back as ~/.bin/foo, because rcup applies
# UNDOTTED when it walks the tree and not when it is handed a single file. The
# task exists to get that right, so it is checked here.
#
# The check works on a copy of the repository: importing *moves* files into it,
# and the real working tree must come out unchanged.

set -u

. "$(dirname -- "$0")/../lib.sh"

work=$(mktemp -d "${TMPDIR:-/tmp}/scriptlets-import.XXXXXX")
copy=$work/repo
home=$work/home

mkdir -p "$copy" "$home/bin"
cp -R "$REPO/." "$copy/"
rm -rf "$copy/.git"

(
    HOME=$home
    MISE_TRUSTED_CONFIG_PATHS=$copy
    export HOME MISE_TRUSTED_CONFIG_PATHS

    echo 'set number' >"$HOME/.foorc"
    printf '#!/bin/sh\necho hi\n' >"$HOME/bin/newscript"
    chmod +x "$HOME/bin/newscript"
    echo 'plain' >"$HOME/notes.txt"

    assert_ok "a dotfile is imported" \
        mise -C "$copy" run import "$HOME/.foorc"
    assert_equal "the dotfile links back into the repository" \
        "$copy/rcm/foorc" "$(readlink "$HOME/.foorc" 2>/dev/null)"

    assert_ok "a file below an UNDOTTED name is imported" \
        mise -C "$copy" run import "$HOME/bin/newscript"
    assert_equal "it keeps its name instead of gaining a dot" \
        "$copy/rcm/bin/newscript" "$(readlink "$HOME/bin/newscript" 2>/dev/null)"

    if [ -e "$HOME/.bin" ]; then
        fail "no dotted stray is left behind" "$(ls -la "$HOME/.bin")"
    else
        pass "no dotted stray is left behind"
    fi

    if mise -C "$copy" run import "$HOME/.foorc" >/dev/null 2>&1; then
        fail "importing an already-imported file is refused" "it succeeded"
    else
        pass "importing an already-imported file is refused"
    fi

    if mise -C "$copy" run import "$HOME/notes.txt" >/dev/null 2>&1; then
        fail "importing a name rcm would dot is refused" "it succeeded"
    else
        pass "importing a name rcm would dot is refused"
    fi
)

strays=
for path in rcm/foorc rcm/bin/newscript; do
    if [ -e "$REPO/$path" ]; then
        strays="$strays $path"
    fi
done

if [ -z "$strays" ]; then
    pass "nothing was imported into the real repository"
else
    fail "nothing was imported into the real repository" "found:$strays"
fi

rm -rf "$work"
