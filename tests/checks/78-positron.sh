#!/bin/sh
# The pair of rcm hooks that keeps ~/bin/positron pointing at Positron's
# command line tool (handbook/install/hooks/README.md).
#
# Against a bundle built here rather than the real one: Positron is macOS-only
# and installed on neither CI runner, so a check that waited for it would never
# run. SCRIPTLETS_POSITRON_APP names the bundle, a stub `uname` says Darwin
# where the machine does not, and HOME is a directory of this check's own --
# the throw-away home is what the other checks read, and ~/bin is in it.

set -u

. "$(dirname -- "$0")/../lib.sh"

hooks=$REPO/rcm/hooks

work=$HOME/positron-check
rm -rf "$work"
mkdir -p "$work/bin" "$work/home"

app=$work/Applications/Positron.app
cli=$app/Contents/Resources/app/bin/code
link=$work/home/bin/positron

mkdir -p "${cli%/*}"
cat >"$cli" <<'STUB'
#!/bin/sh
echo "positron-cli $*"
STUB
chmod +x "$cli"

# Enough of uname for the one question the hook asks it.
cat >"$work/bin/uname" <<'STUB'
#!/bin/sh
[ "$1" = -s ] || exit 1
echo Darwin
STUB
chmod +x "$work/bin/uname"

# run HOOK -- the hook, on a Darwin that has the bundle, with $output and
# $status. `env` rather than an exported PATH, so the stub is in front of the
# real uname for the hook alone.
run() {
    output=$(PATH="$work/bin:$PATH" HOME=$work/home \
        SCRIPTLETS_POSITRON_APP=$app "$hooks/$1" 2>&1)
    status=$?
}

# --- off macOS --------------------------------------------------------------

# The hook is reached on every install, on every platform, and everything below
# this line is inside a bundle only macOS has.
if [ "$(uname -s)" = Darwin ]; then
    skip "off macOS the hook does nothing: this machine is macOS"
else
    output=$(HOME=$work/home SCRIPTLETS_POSITRON_APP=$app \
        "$hooks/post-up/positron" 2>&1)
    status=$?
    assert_equal "off macOS the hook succeeds" "0" "$status"
    assert_equal "off macOS the hook says nothing" "" "$output"
    if [ -e "$link" ] || [ -L "$link" ]; then
        fail "off macOS the hook links nothing" "$(ls -l "$link" 2>&1)"
    else
        pass "off macOS the hook links nothing"
    fi
fi

# --- linking ----------------------------------------------------------------

run post-up/positron
assert_equal "the hook succeeds" "0" "$status"
assert_equal "the link points at the tool in the bundle" \
    "$cli" "$(readlink "$link" 2>&1)"
assert_match "and the hook says what it linked" "linked *positron -> *code" \
    "$output"

# The name is the point: the tool inside the bundle is called `code`, which is
# VS Code's, and reaching Positron by that name would mean shadowing it.
assert_equal "the tool answers to the name it is linked under" \
    "positron-cli --version" "$(PATH="$work/home/bin:$PATH" positron --version)"

run post-up/positron
assert_equal "a second run succeeds" "0" "$status"
assert_equal "a second run says nothing" "" "$output"
assert_equal "and leaves the link alone" "$cli" "$(readlink "$link" 2>&1)"

# --- what it will not touch -------------------------------------------------

rm -f "$link"
echo 'mine' >"$link"

run post-up/positron
assert_equal "a file of the account's own is left alone" \
    "mine" "$(cat "$link")"
assert_equal "and the hook still succeeds" "0" "$status"
assert_match "and says why it did nothing" "*not ours*" "$output"

output=$(HOME=$work/home "$hooks/pre-down/positron" 2>&1)
assert_equal "uninstalling leaves it alone too" "mine" "$(cat "$link")"

rm -f "$link"

# --- the bundle going away --------------------------------------------------

run post-up/positron
rm -rf "$work/Applications"

run post-up/positron
if [ -L "$link" ]; then
    fail "a link into a bundle that is gone is removed" "$(ls -l "$link" 2>&1)"
else
    pass "a link into a bundle that is gone is removed"
fi
assert_match "and the hook says so" "removing *" "$output"

mkdir -p "${cli%/*}"
cat >"$cli" <<'STUB'
#!/bin/sh
echo "positron-cli $*"
STUB
chmod +x "$cli"

# --- uninstalling -----------------------------------------------------------

run post-up/positron

output=$(HOME=$work/home "$hooks/pre-down/positron" 2>&1)
status=$?
assert_equal "uninstalling succeeds" "0" "$status"
if [ -L "$link" ]; then
    fail "uninstalling removes the link" "$(ls -l "$link" 2>&1)"
else
    pass "uninstalling removes the link"
fi

# --- through the tasks ------------------------------------------------------

# Everything above runs the hooks directly, which says nothing about whether
# rcm reaches them: it runs the executable files below hooks/post-up and
# hooks/pre-down of the trees named in DOTFILES_DIRS, and that list is not the
# one -d gives it (handbook/install/hooks/README.md).
cycle=$work/cycle
mkdir -p "$cycle"

task() {
    PATH="$work/bin:$PATH" HOME=$cycle SCRIPTLETS_POSITRON_APP=$app \
        MISE_TRUSTED_CONFIG_PATHS=$REPO mise -q -C "$REPO" run "$1" \
        >/dev/null 2>&1 </dev/null
}

if task install; then
    assert_equal "mise run install links the tool" \
        "$cli" "$(readlink "$cycle/bin/positron" 2>&1)"
else
    fail "mise run install links the tool" "the task failed"
fi

if task uninstall; then
    if [ -e "$cycle/bin/positron" ] || [ -L "$cycle/bin/positron" ]; then
        fail "mise run uninstall takes the link away again" \
            "$(ls -l "$cycle/bin/positron" 2>&1)"
    else
        pass "mise run uninstall takes the link away again"
    fi
else
    fail "mise run uninstall takes the link away again" "the task failed"
fi

# --- what rcm needs of the files --------------------------------------------

# rcm runs the executable files below hooks/pre-up, hooks/post-up and their
# down counterparts, and passes over the rest without a word: a hook that lost
# its permission bit would stop running and nothing would say so.
not_executable=
for hook in "$hooks"/*-*/*; do
    [ -x "$hook" ] || not_executable="$not_executable ${hook#$REPO/}"
done

if [ -z "$not_executable" ]; then
    pass "every hook is executable"
else
    fail "every hook is executable" "not executable:$not_executable"
fi

# hooks/ is rcm's own name for that directory, and it installs nothing from it
# -- the shared file beside the hooks would otherwise land in the home
# directory as ~/.hooks/positron.sh.
if [ -e "$HOME/.hooks" ]; then
    fail "the hooks directory is not installed" "$(ls -ld "$HOME/.hooks" 2>&1)"
else
    pass "the hooks directory is not installed"
fi

rm -rf "$work"
