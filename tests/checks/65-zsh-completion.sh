#!/bin/sh
# What completes the git wrappers under zsh, and what no longer does.
#
# `g` and `s` are scripts, so nothing completes them by itself: ~/.zshrc binds
# git's completion to `g`, and a function of its own to `s`, which walks the
# flags of `h` and hands the rest back to git's completion.
#
# The last assertion is the other half of the same change. ~/.bash_aliases is
# read by both shells; its git completions are bash's, behind a $BASH_VERSION
# guard, and zsh must not be pulling them in through bashcompinit any more.
#
# The bindings are what is checked, not the candidates they produce: driving a
# real completion needs a pseudo-terminal and a repository to complete refs
# from, and a binding that is present is the part that regresses.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

# As in 60-zsh-startup: interactive, because ~/.zshrc is only read by
# interactive shells, and stderr dropped because a system-wide zshrc that runs
# compinit of its own is noisy about insecure directories.
probe() {
    zsh -ic "$1" 2>/dev/null | sed -n 's/^probe=//p' | tail -n 1
}

assert_equal "zsh has its own completion for git" \
    "_git" "$(probe 'print "probe=${_comps[git]}"')"

assert_equal "g completes like git" \
    "_git" "$(probe 'print "probe=${_comps[g]}"')"

assert_equal "s completes through a function of its own" \
    "_s" "$(probe 'print "probe=${_comps[s]}"')"

assert_equal "the git half of s is there to hand over to" \
    "1 1" \
    "$(probe 'print "probe=${+functions[_s_git_command]} ${+functions[_s_git_args]}"')"

assert_equal "zsh does not load bash's git completion" \
    "0" "$(probe 'print "probe=${+functions[__git_complete]}"')"
