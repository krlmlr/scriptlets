#!/bin/sh
# The semantic prompt marks ~/.zshrc sends: the right bytes, from the right
# place, and only where something else is not sending them already.
#
# Where they are sent from is the part worth a check. A (a prompt starts here)
# has to live in $PS1: the line editor erases from the cursor to the end of the
# screen before it draws a prompt, tmux forgets the lines that erase clears,
# and a mark sent from a precmd hook arrives just before it. The failure is
# quiet -- every prompt still looks marked, and only prompt-to-prompt jumping
# in tmux gives it away -- so it is checked here rather than noticed later.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

# probe CODE [NAME=VALUE...] -- what CODE prints in an interactive zsh started
# with those variables in the environment.
#
# $TERM_PROGRAM and $TMUX are named at every call, never inherited: the checks
# below turn on what the shell does with them, and a suite run from inside tmux
# -- or from a terminal that names itself -- would otherwise test the machine
# it runs on.
#
# stderr is dropped for the same reason as in 60-zsh-startup.sh: a system-wide
# zshrc running a compinit of its own is noisy, and none of that is ours.
probe() {
    _code=$1
    shift
    env "$@" zsh -ic "$_code" 2>/dev/null | sed -n 's/^probe=//p' | tail -n 1
}

# cat -v throughout, so that an escape sequence can be written out in a check
# and compared as ordinary text.
assert_equal "the command-end mark carries the status of the command line" \
    '^[]133;D;7^G' \
    "$(probe 'sh -c "exit 7"; print "probe=$(_osc133_precmd | cat -v)"' \
        TERM_PROGRAM= TMUX=)"

assert_equal "the output-start mark is sent before the command runs" \
    '^[]133;C^G' \
    "$(probe 'print "probe=$(_osc133_preexec | cat -v)"' TERM_PROGRAM= TMUX=)"

assert_equal "both are registered as hooks" \
    "_osc133_precmd _osc133_preexec" \
    "$(probe 'print "probe=$precmd_functions[(r)_osc133_precmd] $preexec_functions[(r)_osc133_preexec]"' \
        TERM_PROGRAM= TMUX=)"

# The prompt-start mark opens $PS1, inside the %{...%} that tells zsh it takes
# up no columns. Neither of the two hooks above sends it -- the check on the
# command-end mark pins their whole output.
ps1=$(probe 'print "probe=$(print -rn -- $PS1 | cat -v)"' TERM_PROGRAM= TMUX=)

case $ps1 in
'%{^[]133;A^G%}'*)
    pass "the prompt starts with the prompt-start mark"
    ;;
*)
    fail "the prompt starts with the prompt-start mark" "PS1=$ps1"
    ;;
esac

# Prepending to $PS1 is not idempotent on its own, and re-reading ~/.zshrc is
# a thing people do.
assert_equal "reading ~/.zshrc twice does not mark the prompt twice" \
    "1" \
    "$(probe 'source ~/.zshrc; print "probe=$(print -rn -- $PS1 | grep -o "133;A" | wc -l | tr -d " ")"' \
        TERM_PROGRAM= TMUX=)"

# Ghostty injects an integration of its own that sends the same sequences, so
# ours stay out of its way -- but that injection reaches only the shell Ghostty
# starts itself, not one that tmux starts later.
assert_equal "under Ghostty, the marks are left to Ghostty" \
    "0" \
    "$(probe 'print "probe=${+functions[_osc133_precmd]}"' \
        TERM_PROGRAM=ghostty TMUX=)"

assert_equal "inside tmux under Ghostty, the shell marks for itself" \
    "1" \
    "$(probe 'print "probe=${+functions[_osc133_precmd]}"' \
        TERM_PROGRAM=ghostty TMUX=/tmp/tmux-0/default,1,0)"
