#!/bin/sh
# ~/.zshrc registers mise's completion lazily: a stub stands in until the first
# Tab, which then loads the generated completion and hands over. Both halves are
# checked -- a stub that never loads the real thing completes nothing, and an
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

assert_equal "zsh binds mise to the lazy stub" \
    "_mise_lazy" "$(probe 'print "probe=${_comps[mise]}"')"

assert_equal "the generated completion is not loaded at startup" \
    "0" "$(probe 'print "probe=${+functions[_mise]}"')"

assert_equal "the first completion loads the real one and rebinds to it" \
    "_mise" "$(probe '_mise_lazy >/dev/null 2>&1; print "probe=${_comps[mise]}"')"
