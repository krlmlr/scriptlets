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
