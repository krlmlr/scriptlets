# Assertion helpers, sourced by every check in tests/checks.
#
# `tests/run` exports REPO, HOME (a throw-away home directory with the
# repository installed into it) and TEST_FAILURES.
# Failures are appended to the $TEST_FAILURES file rather than counted in a
# variable, because each check runs in its own process.

pass() {
    printf 'ok       %s\n' "$1"
}

fail() {
    printf 'NOT OK   %s\n' "$1"
    if [ $# -gt 1 ]; then
        printf '%s\n' "$2" | sed 's/^/         /'
    fi
    printf '%s\n' "$1" >>"$TEST_FAILURES"
}

skip() {
    printf 'skip     %s\n' "$1"
}

# assert_equal DESCRIPTION EXPECTED ACTUAL
assert_equal() {
    if [ "$2" = "$3" ]; then
        pass "$1"
    else
        fail "$1" "expected: $2
  actual: $3"
    fi
}

# assert_match DESCRIPTION PATTERN TEXT -- PATTERN is a shell glob, unquoted on
# purpose, so `Usage:*` matches a message whose tail is a path.
assert_match() {
    case $3 in
    $2)
        pass "$1"
        ;;
    *)
        fail "$1" "no match for: $2
  actual: $3"
        ;;
    esac
}

# assert_in_path DESCRIPTION DIRECTORY PATH_VALUE
assert_in_path() {
    case ":$3:" in
    *":$2:"*)
        pass "$1"
        ;;
    *)
        fail "$1" "PATH=$3"
        ;;
    esac
}

# login_output SHELL COMMAND -- what COMMAND prints in a login shell of SHELL.
#
# The marker line is what keeps banners and other login-time chatter (a bare
# `echo` in /etc/profile.d is enough) out of the answer; the leading newline
# covers chatter that ends without one. Only the last line of COMMAND's output
# survives, which is all any check here needs.
login_output() {
    "$1" -lc 'printf "\nscriptlets-output=%s\n" "$('"$2"')"' 2>/dev/null |
        sed -n 's/^scriptlets-output=//p' | tail -n 1
}

# login_path SHELL -- the PATH a login shell of SHELL arrives at.
login_path() {
    login_output "$1" 'printf %s "$PATH"'
}

# assert_ok DESCRIPTION COMMAND [ARGUMENT...]
assert_ok() {
    _description=$1
    shift
    if _output=$("$@" 2>&1); then
        pass "$_description"
    else
        fail "$_description" "$_output"
    fi
}
