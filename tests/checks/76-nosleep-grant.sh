#!/bin/sh
# The rule `nosleep-grant` writes, checked without writing it.
#
# `--print` is what makes that possible, and it is there for the same reason it
# is useful here: a grant of root privileges should be readable before it is
# given. What the check watches is the width of the rule -- two commands, both
# spelled out, no wildcard -- because that is the property that makes the grant
# worth having rather than alarming.
#
# Nothing here touches /etc. The write path needs macOS and a password, and
# neither belongs in a check.

set -u

. "$(dirname -- "$0")/../lib.sh"

task=$REPO/mise-tasks/nosleep-grant

run() {
    output=$("$task" "$@" 2>&1)
    status=$?
}

# --- the rule ---------------------------------------------------------------

run --print
assert_equal "--print succeeds" "0" "$status"
assert_match "the rule is for whoever asked" "$(id -un) ALL=(root) NOPASSWD:*" \
    "$output"
assert_match "it grants disablesleep 1" "*/usr/bin/pmset -a disablesleep 1*" \
    "$output"
assert_match "it grants disablesleep 0" "*/usr/bin/pmset -a disablesleep 0*" \
    "$output"

# sudo compares given arguments literally, so a rule without a wildcard grants
# the two lines it names and nothing else. A wildcard would quietly widen it to
# every pmset setting there is.
case $output in
*'*'*)
    fail "the rule carries no wildcard" "$output"
    ;;
*)
    pass "the rule carries no wildcard"
    ;;
esac

assert_equal "the rule is one line" "1" "$(printf '%s\n' "$output" | wc -l | tr -d ' ')"

# A sudoers file that does not parse stops sudo from running at all, so the task
# validates before installing -- and what it validates is checked here.
if command -v visudo >/dev/null 2>&1; then
    tmp=$(mktemp "${TMPDIR:-/tmp}/nosleep-grant-check.XXXXXX")
    printf '%s\n' "$output" >"$tmp"
    assert_ok "the rule parses as sudoers" visudo -c -q -f "$tmp"
    rm -f "$tmp"
else
    skip "visudo: not installed"
fi

# --- where it refuses -------------------------------------------------------

# The write path is macOS's, and asks for a password. Off macOS the refusal is
# the whole behaviour and safe to run; on macOS it is left alone.
if [ "$(uname -s)" = Darwin ]; then
    skip "macOS: the write path wants a password, and no check may wait at one"
else
    run
    assert_equal "writing the rule off macOS fails" "1" "$status"
    assert_match "and says why" "*macOS*" "$output"
fi

run --nonsense
assert_equal "an unknown option fails" "1" "$status"
assert_match "an unknown option prints the usage" "Usage:*" "$output"

run --print --remove
assert_equal "two options fail" "1" "$status"
