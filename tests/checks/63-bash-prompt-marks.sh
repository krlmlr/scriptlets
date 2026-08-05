#!/bin/sh
# The semantic prompt marks ~/.bashrc sends. What they mean and where each one
# has to come from is the same question the zsh check answers; bash answers it
# with different machinery, and this is what pins that machinery down.
#
# The marks come back on both streams -- bash prints PS0, like the prompt
# itself, to stderr, while what the prompt command prints goes to stdout -- so
# both are captured. On a terminal both are the terminal; the order they
# arrive in was checked against a real pty before it was relied on here.
#
# bash is pointed at the file this repository ships rather than at
# ~/.bashrc: the throw-away home is seeded with a stock ~/.bashrc, and rcm
# leaves a file that already exists alone, so the installed one is the
# account's own until `mise run force` replaces it (30-preexisting, 90-force).

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v bash >/dev/null 2>&1; then
    skip "bash: not installed"
    exit 0
fi

# marks INPUT [NAME=VALUE...] -- the OSC 133 sequences an interactive bash
# sends while reading INPUT, in order, written the way `cat -v` writes them.
#
# An interactive bash reading a pipe still runs its prompt command and expands
# PS0, which is what makes the whole chain checkable without a terminal.
# Everything that is not a mark -- the prompt, the echoed input, and whatever
# ~/.bashrc says about the clones it expects to find -- is dropped.
marks() {
    _input=$1
    shift
    printf '%s' "$_input" |
        env "$@" bash --rcfile "$REPO/rcm/bashrc" -i 2>&1 |
        cat -v |
        grep -o '\^\[\]133;[^^]*\^G' |
        tr '\n' ' ' |
        sed 's/ *$//'
}

assert_equal "a command line is marked start to finish, with its status" \
    '^[]133;A^G ^[]133;C^G ^[]133;D;7^G ^[]133;A^G' \
    "$(marks 'sh -c "exit 7"
' TERM_PROGRAM=)"

# The status has to survive the rest of $PROMPT_COMMAND: ~/.bashrc syncs the
# history there, and bash, unlike zsh, hands each part the status of the one
# before it.
assert_equal "the status is the command line's, not the history sync's" \
    '^[]133;D;3^G' \
    "$(marks 'sh -c "exit 3"
' TERM_PROGRAM= | sed 's/.*\(\^\[\]133;D;[0-9]*\^G\).*/\1/')"

# A prompt no command preceded gets a prompt mark and nothing else.
assert_equal "a bare Enter is not a command that ended" \
    '^[]133;A^G ^[]133;A^G ^[]133;A^G' \
    "$(marks '

' TERM_PROGRAM=)"

# ---------------------------------------------------------------------------
# Ghostty starts bash in POSIX mode with an integration script of its own,
# which sources the user's startup files and then marks the prompts itself.
# The script is still on the stack while ~/.bashrc runs, which is what ours
# looks for -- the function Ghostty installs does not exist yet at that point.
#
# The directory below imitates that: a file named as Ghostty's is, sourcing
# ~/.bashrc the way Ghostty sources it.
# ---------------------------------------------------------------------------
standin=$HOME/.ghostty-stand-in
mkdir -p "$standin"
cat >"$standin/ghostty.bash" <<EOF
. "$REPO/rcm/bashrc"
EOF

assert_equal "where Ghostty's integration is loaded, the marks are left to it" \
    "" \
    "$(printf 'true\n' |
        env TERM_PROGRAM=ghostty bash --rcfile "$standin/ghostty.bash" -i 2>&1 |
        cat -v | grep -o '\^\[\]133;[^^]*\^G' | tr '\n' ' ' | sed 's/ *$//')"

# $TERM_PROGRAM is exported to every process Ghostty starts, so it says
# nothing about whether this shell is the one it integrated.
assert_equal "a shell started inside that one marks for itself" \
    '^[]133;A^G ^[]133;C^G ^[]133;D;0^G ^[]133;A^G' \
    "$(marks 'true
' TERM_PROGRAM=ghostty)"

rm -rf "$standin"
