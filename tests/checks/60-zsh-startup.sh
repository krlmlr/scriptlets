#!/bin/sh
# The zsh startup files: quiet, and lazy about mise's completion.
#
# Quiet, because a line that only works on one machine is easy to add and hard
# to notice -- the profiling marks called a function that only the author's
# profiler defines, so every zsh start elsewhere said `command not found`, once
# per startup file.
#
# Lazy, because ~/.zshrc registers mise's completion through a stub that stands
# in until the first Tab and then loads the generated completion. Both halves
# are checked: a stub that never loads the real thing completes nothing, and an
# eager load costs a `usage` run at every shell start, which is the thing being
# avoided.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

if ! command -v mise >/dev/null 2>&1; then
    skip "mise: not installed"
    exit 0
fi

# Interactive, because ~/.zshrc is only read by interactive shells. stderr is
# dropped: a system-wide zshrc that runs compinit of its own is noisy about
# insecure directories, and none of that is ours.
probe() {
    zsh -ic "$1" 2>/dev/null | sed -n 's/^probe=//p' | tail -n 1
}

assert_equal "~/.zshrc is installed" \
    "$REPO/rcm/zshrc" "$(readlink "$HOME/.zshrc" 2>/dev/null)"

# Interactive *and* login, so that all three files are read. Only complaints
# that name a file in this home directory count: a system-wide zshrc with
# opinions of its own is not ours to fix.
#
# The startup profiler is deliberately not silent, and does not show up here
# either way: `-c` never reaches a prompt, which is where it reports.
# tests/checks/65-zsh-startup-profile.sh covers what it says and when.
noise=$(zsh -ilc true </dev/null 2>&1 >/dev/null | grep -F "$HOME" || true)

if [ -z "$noise" ]; then
    pass "a zsh startup says nothing"
else
    fail "a zsh startup says nothing" "$noise"
fi

assert_equal "zsh binds mise to the lazy stub" \
    "_mise_lazy" "$(probe 'print "probe=${_comps[mise]}"')"

assert_equal "the generated completion is not loaded at startup" \
    "0" "$(probe 'print "probe=${+functions[_mise]}"')"

assert_equal "the first completion loads the real one and rebinds to it" \
    "_mise" "$(probe '_mise_lazy >/dev/null 2>&1; print "probe=${_comps[mise]}"')"

# ---------------------------------------------------------------------------
# The completion dump: audited once a day, trusted in between.
#
# `compinit -i` does not skip the security audit, it only stops it from asking,
# and compaudit stats every directory in $fpath -- half of what the whole rc
# chain spent. ~/.zshrc therefore audits only when the .audited stamp is more
# than a day old, and `compinit -C` trusts the dump for every shell in between.
#
# The stamp is written with `: >| $stamp`, which truncates it, so a sentinel
# written into it says exactly what happened: gone means the audit ran, intact
# means the dump was trusted. Timestamps could not tell the two apart -- a
# re-audit within the same second leaves the same mtime behind.
# ---------------------------------------------------------------------------

dump_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
rm -rf "$dump_dir"

zsh -ic true >/dev/null 2>&1

dump=
for candidate in "$dump_dir"/zcompdump-*; do
    case $candidate in
    *.zwc | *.audited | *'zcompdump-*') continue ;;
    esac
    [ -e "$candidate" ] && dump=$candidate
done

if [ -n "$dump" ]; then
    pass "the first interactive shell writes a completion dump"
else
    fail "the first interactive shell writes a completion dump" \
        "$(ls -la "$dump_dir" 2>&1)"
fi

if [ -n "$dump" ]; then
    # Wordcode, which is what zsh reads in place of the dump when it is newer.
    if [ -s "$dump.zwc" ]; then
        pass "the dump is compiled to wordcode"
    else
        fail "the dump is compiled to wordcode" "$(ls -la "$dump_dir" 2>&1)"
    fi

    printf 'sentinel\n' >"$dump.audited"
    zsh -ic true >/dev/null 2>&1
    assert_equal "a second shell trusts the dump instead of auditing again" \
        "sentinel" "$(cat "$dump.audited" 2>&1)"

    # More than a day old, so the audit is due again.
    touch -t 202001010000 "$dump.audited"
    zsh -ic true >/dev/null 2>&1
    assert_equal "a stamp older than a day makes the next shell audit" \
        "" "$(cat "$dump.audited" 2>&1)"

    # And the audit has to date itself, or every shell from the second day on
    # pays for one: compinit leaves the dump's own mtime alone when the set of
    # completion functions has not changed.
    printf 'sentinel\n' >"$dump.audited"
    touch -t 202001010000 "$dump.audited"
    zsh -ic true >/dev/null 2>&1
    zsh -ic true >/dev/null 2>&1
    printf 'sentinel\n' >"$dump.audited"
    zsh -ic true >/dev/null 2>&1
    assert_equal "the audit dates itself, so the next shell trusts the dump" \
        "sentinel" "$(cat "$dump.audited" 2>&1)"
fi

# The escape hatch, for the tool installed five minutes ago.
if [ -x "$HOME/bin/zsh-compinit-refresh" ]; then
    [ -n "$dump" ] && printf 'sentinel\n' >"$dump.audited"
    refresh=$("$HOME/bin/zsh-compinit-refresh" 2>&1) || refresh="FAILED: $refresh"

    case $refresh in
    *"wrote "*)
        pass "zsh-compinit-refresh rebuilds the dump"
        ;;
    *)
        fail "zsh-compinit-refresh rebuilds the dump" "$refresh"
        ;;
    esac

    if [ -n "$dump" ]; then
        assert_equal "zsh-compinit-refresh audits rather than trusting the stamp" \
            "" "$(cat "$dump.audited" 2>&1)"
    fi
else
    fail "zsh-compinit-refresh is installed" "no $HOME/bin/zsh-compinit-refresh"
fi
