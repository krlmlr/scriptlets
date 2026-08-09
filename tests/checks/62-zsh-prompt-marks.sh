#!/bin/sh
# The semantic prompt marks ~/.zshrc sends: the right bytes, from the right
# place, at the right moments, and only where something else is not sending
# them already.
#
# Where they are sent from is the part worth a check. A and B -- a prompt
# starts here, and ends here -- have to live in $PS1: the line editor erases
# from the cursor to the end of the screen before it draws a prompt, tmux
# forgets the lines that erase clears, and a mark sent from a precmd hook
# arrives just before it. The failure is quiet -- every prompt still looks
# marked, and only prompt-to-prompt jumping in tmux gives it away -- so it is
# checked here rather than noticed later.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

# marks INPUT -- the marks an interactive zsh sends while running INPUT, one
# line per command, with everything else stripped.
#
# No terminal is needed and none is faked: an interactive zsh reading a pipe
# still runs precmd and preexec around every command, and prints no prompt to
# get in the way. This is what makes it worth doing -- calling the hooks by
# hand would test the strings and not the chain, and the chain is where the
# claim is (~/.zshrc registers this precmd hook behind the history rotation,
# and relies on zsh restoring $? around each one).
#
# stdout only: the startup profiler reports on stderr, as does anything a
# system-wide zshrc has to say. cat -v so that a sequence can be written out
# in a check and compared as ordinary text.
#
# The working-directory reports ~/.zshrc sends from the same hooks are dropped
# rather than expected here -- they are 63-zsh-cwd-report.sh's -- and dropped
# by pattern rather than by counting, so anything else that appears on stdout
# still shows up in a failure. Their path is percent-encoded, so the ^ that
# cat -v writes control characters with cannot occur inside one.
marks() {
    esc=$(printf '\033')
    bel=$(printf '\007')
    printf '%s' "$1" |
        env -u ZDOTDIR TERM_PROGRAM= TMUX= zsh -i 2>/dev/null |
        sed "s/$esc]7;[^$bel]*$bel//g" |
        cat -v | tr -d '\n'
}

# probe CODE [NAME=VALUE...] -- what CODE prints in an interactive zsh started
# with those variables in the environment.
#
# $TERM_PROGRAM, $TMUX and $ZDOTDIR are named or dropped at every call, never
# inherited: the checks below turn on what the shell does with them, and a
# suite run from inside tmux -- or from a terminal that names itself -- would
# otherwise test the machine it runs on.
probe() {
    _code=$1
    shift
    env -u ZDOTDIR "$@" zsh -ic "$_code" 2>/dev/null |
        sed -n 's/^probe=//p' | tail -n 1
}

assert_equal "output starts where the command does, and the command end carries its status" \
    '^[]133;C^G^[]133;D;7^G' "$(marks 'sh -c "exit 7"
')"

# precmd runs before every prompt, not after every command. Sending the
# command-end mark from it unconditionally would report one before the first
# prompt of a session and one for every bare Enter, each carrying the status
# of the last real command -- one failed command painting three prompts red.
assert_equal "a bare Enter is not a command that ended" \
    '^[]133;C^G^[]133;D;1^G' "$(marks 'false


')"

# In $PS1, and inside %{...%}, which is what tells zsh they take up no
# columns. A opens the prompt, B closes it.
ps1=$(probe 'print "probe=$(print -rn -- $PS1 | cat -v)"' TERM_PROGRAM= TMUX=)

case $ps1 in
'%{^[]133;A^G%}'*'%{^[]133;B^G%}')
    pass "the prompt starts with the prompt-start mark and ends with the input-start mark"
    ;;
*)
    fail "the prompt starts with the prompt-start mark and ends with the input-start mark" \
        "PS1=$ps1"
    ;;
esac

# Adding to $PS1 is not idempotent on its own, and re-reading ~/.zshrc is a
# thing people do.
assert_equal "reading ~/.zshrc twice does not mark the prompt twice" \
    "1" \
    "$(probe 'source ~/.zshrc; print "probe=$(print -rn -- $PS1 | grep -o "133;A" | wc -l | tr -d " ")"' \
        TERM_PROGRAM= TMUX=)"

# ---------------------------------------------------------------------------
# Two shells that get no marks, each imitated by a $ZDOTDIR of its own.
#
# Ghostty injects an integration that sends the same sequences, so ours stay
# out of its way -- but the condition asks whether that integration is in
# *this* shell, not whether this is a Ghostty window. Ghostty exports
# $TERM_PROGRAM to every process it starts and injects the integration once,
# in the first shell, by pointing $ZDOTDIR at a directory of its own whose
# .zshenv registers a deferred-init precmd hook and hands $ZDOTDIR back.
# Both halves are then checkable: the shell Ghostty integrated, and any shell
# started inside it.
#
# The other is a shell with prompt escapes switched off, where the %{...%}
# that hides a mark would print as braces instead.
# ---------------------------------------------------------------------------
ghostty=$HOME/.ghostty-stand-in
nopercent=$HOME/.zsh-prompt-marks-check
mkdir -p "$ghostty" "$nopercent"

cat >"$ghostty/.zshenv" <<'EOF'
precmd_functions+=(_ghostty_deferred_init)
ZDOTDIR=$HOME
[[ -r $HOME/.zshenv ]] && source $HOME/.zshenv
EOF

cat >"$nopercent/.zshenv" <<'EOF'
unsetopt prompt_percent
ZDOTDIR=$HOME
[[ -r $HOME/.zshenv ]] && source $HOME/.zshenv
EOF

assert_equal "where Ghostty's integration is loaded, the marks are left to it" \
    "0 " \
    "$(probe 'print "probe=${+functions[_osc133_precmd]} ${${(M)PS1:#*133;A*}:+marked}"' \
        TERM_PROGRAM=ghostty TMUX= "ZDOTDIR=$ghostty")"

assert_equal "a shell started inside that one marks for itself" \
    "1 marked" \
    "$(probe 'print "probe=${+functions[_osc133_precmd]} ${${(M)PS1:#*133;A*}:+marked}"' \
        TERM_PROGRAM=ghostty TMUX=)"

# What an untouched prompt looks like is the machine's business, not this
# check's: zsh's own default is `%m%# `, macOS sets `%n@%m %1~ %# ` in
# /etc/zshrc, and a system that sets a third is not wrong. So the prompt of a
# shell that skipped the marks is what the prompt of a shell that left them
# out is compared against.
untouched=$(probe 'print "probe=$(print -rn -- $PS1 | cat -v)"' \
    TERM_PROGRAM=ghostty TMUX= "ZDOTDIR=$ghostty")

assert_equal "a prompt without escapes is left alone rather than filled with braces" \
    "$untouched" \
    "$(probe 'print "probe=$(print -rn -- $PS1 | cat -v)"' \
        TERM_PROGRAM= TMUX= "ZDOTDIR=$nopercent")"

rm -rf "$ghostty" "$nopercent"
