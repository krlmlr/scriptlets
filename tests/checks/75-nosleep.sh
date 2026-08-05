#!/bin/sh
# `nosleep` decides and `pmset` obeys, so the deciding is what is checked here:
# the two explicit spellings, the bare toggle, the no-op that asks for no
# password, and the arguments that are refused.
#
# Against stub `pmset` and `sudo` commands, for three reasons. The real ones
# would put the machine running the checks to sleep -- or keep it awake for
# good -- ask for a password no check may wait at, and exist on macOS alone,
# where this script installs but half of CI does not run. The stub records
# what it was told instead, and the logic is covered on both platforms.
#
# What is platform-specific here is the installation, checked at the end.

set -u

. "$(dirname -- "$0")/../lib.sh"

script=$REPO/rcm/tag-macos/bin/nosleep

work=$HOME/nosleep-check
rm -rf "$work"
mkdir -p "$work/bin"

STATE=$work/state
SUDO_LOG=$work/sudo-log
export STATE SUDO_LOG

# Enough of pmset for this: `-g` prints the flag the way macOS prints it, under
# the name a machine that has it set shows, and prints nothing at all before it
# is ever set -- the state a fresh machine is in.
cat >"$work/bin/pmset" <<'STUB'
#!/bin/sh
case "$1" in
-g)
    if [ -f "$STATE" ]; then
        printf 'System-wide power settings:\n SleepDisabled\t\t%s\n' "$(cat "$STATE")"
    fi
    ;;
-a)
    [ "$2" = disablesleep ] || exit 1
    printf '%s\n' "$3" >"$STATE"
    ;;
esac
STUB

cat >"$work/bin/sudo" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$SUDO_LOG"
exec "$@"
STUB

chmod +x "$work/bin/pmset" "$work/bin/sudo"

PATH=$work/bin:$PATH
export PATH

# run ARGUMENT... -- leaves what nosleep printed in $output, its status in
# $status, and both streams together because the usage line goes to stderr.
run() {
    output=$("$script" "$@" 2>&1)
    status=$?
}

state() {
    cat "$STATE" 2>/dev/null || echo unset
}

sudo_calls() {
    if [ -f "$SUDO_LOG" ]; then
        wc -l <"$SUDO_LOG" | tr -d ' '
    else
        echo 0
    fi
}

# --- the explicit spellings ------------------------------------------------

run on
assert_equal "nosleep on succeeds" "0" "$status"
assert_equal "nosleep on disables sleep" "1" "$(state)"
assert_equal "nosleep on says so" "sleep disabled" "$output"

run off
assert_equal "nosleep off succeeds" "0" "$status"
assert_equal "nosleep off enables sleep again" "0" "$(state)"
assert_equal "nosleep off says so" "sleep enabled" "$output"

# --- the bare toggle -------------------------------------------------------

run
assert_equal "bare nosleep toggles an enabled machine" "1" "$(state)"
assert_equal "bare nosleep says what it did" "sleep disabled" "$output"

run
assert_equal "bare nosleep toggles back" "0" "$(state)"
assert_equal "bare nosleep says that too" "sleep enabled" "$output"

# A machine where the flag was never set names it in no output at all, and is
# awake: the toggle has to read that as off rather than as unknown.
rm -f "$STATE"
run
assert_equal "bare nosleep reads an unset flag as enabled" "1" "$(state)"

# --- the no-op -------------------------------------------------------------

# Already there, so there is nothing to write and nothing to ask a password
# for. Both halves matter: the second is why this is not just an early exit.
rm -f "$SUDO_LOG"
run on
assert_equal "nosleep on twice succeeds" "0" "$status"
assert_equal "nosleep on twice says it is already there" \
    "sleep is already disabled" "$output"
assert_equal "a no-op runs no sudo" "0" "$(sudo_calls)"

# The contrast that gives the line above its meaning: a real change does reach
# sudo. Not where the checks themselves run as root -- a container -- and there
# the script is right to call pmset directly.
if [ "$(id -u)" = 0 ]; then
    skip "already root: the sudo prefix is not part of the change"
else
    rm -f "$SUDO_LOG"
    run off
    assert_equal "a real change goes through sudo" "1" "$(sudo_calls)"
fi

# --- the arguments that are refused ----------------------------------------

before=$(state)

run sometimes
assert_equal "an unknown argument fails" "1" "$status"
assert_match "an unknown argument prints the usage" "Usage:*" "$output"

run on off
assert_equal "two arguments fail" "1" "$status"
assert_match "two arguments print the usage" "Usage:*" "$output"

assert_equal "a refused argument changes nothing" "$before" "$(state)"

# --- where it installs -----------------------------------------------------

# pmset is macOS's, so the script is, and rcm has to keep it off everything
# else -- the property the platform tags exist for.
if [ "$(uname -s)" = Darwin ]; then
    if [ -x "$HOME/bin/nosleep" ]; then
        pass "nosleep is installed and executable on macOS"
    else
        fail "nosleep is installed and executable on macOS" \
            "$(ls -l "$HOME/bin/nosleep" 2>&1)"
    fi
else
    if [ -e "$HOME/bin/nosleep" ]; then
        fail "nosleep is not installed off macOS" "$HOME/bin/nosleep exists"
    else
        pass "nosleep is not installed off macOS"
    fi
fi

rm -rf "$work"
