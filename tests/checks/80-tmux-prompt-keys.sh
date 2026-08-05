#!/bin/sh
# The copy-mode keys in ~/.tmux.conf, exercised as keys: a client is attached
# to a pane whose prompts are marked, `prefix o` and the copy-mode keys are
# pressed, and what lands on the clipboard is what gets checked. Running the
# command list by hand instead would pass just as well with the binding
# deleted.
#
# The prompts are synthetic -- a script printing the OSC 133 sequences a shell
# would print -- so this checks tmux's half alone, on a machine whose login
# shell is anything at all. What the shell sends is its own check.
#
# Two servers, both on sockets of their own (`-L`): the inner one holds the
# marked pane, the outer one runs a client attached to it, which is how a key
# press can be delivered without a terminal. A tmux the author is sitting in
# is neither read nor disturbed.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux: not installed"
    exit 0
fi

# 3.4 is where previous-prompt, next-prompt and their -o flag arrived. An
# unparseable version -- a `next-3.6` build, say -- is skipped rather than
# guessed at.
version=$(tmux -V 2>/dev/null | sed -n 's/^tmux \([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')

if [ -z "$version" ]; then
    skip "tmux: cannot tell the version from $(tmux -V 2>&1)"
    exit 0
fi

major=${version%%.*}
minor=${version#*.}

if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 4 ]; }; then
    skip "tmux $version: previous-prompt needs 3.4"
    exit 0
fi

assert_equal "~/.tmux.conf is installed" \
    "$REPO/rcm/tmux.conf" "$(readlink "$HOME/.tmux.conf" 2>/dev/null)"

inner=scriptlets-check-$$
outer=scriptlets-driver-$$
emitter=$HOME/.tmux-prompt-emitter
clipboard=$HOME/.tmux-prompt-clipboard
socket_dir=${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)

cleanup() {
    tmux -L "$outer" kill-server 2>/dev/null
    tmux -L "$inner" kill-server 2>/dev/null
    # Killing a server unlinks nothing; the socket file outlives it.
    rm -f "$socket_dir/$inner" "$socket_dir/$outer" "$emitter" "$clipboard"
}
trap cleanup EXIT INT TERM

# wait_for DESCRIPTION COMMAND -- run COMMAND until it succeeds, up to five
# seconds. Everything here waits on another process: a pane being drawn, a
# client attaching, a `copy-pipe` command that tmux runs asynchronously.
wait_for() {
    _waited=0
    while [ "$_waited" -lt 50 ]; do
        if eval "$2" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.1
        _waited=$((_waited + 1))
    done
    fail "$1" "still not true after five seconds"
    return 1
}

# --- the file itself parses -------------------------------------------------
#
# `new-session -f <file>` is no test of that: it starts and exits 0 whether the
# file is a tmux configuration, a shopping list, or absent. `source-file` says
# what it could not read, so an empty complaint is the assertion.
tmux -L "$inner" -f /dev/null new-session -d -s parse 2>/dev/null
complaint=$(tmux -L "$inner" source-file "$REPO/rcm/tmux.conf" 2>&1)
tmux -L "$inner" kill-server 2>/dev/null

assert_equal "the configuration file parses" "" "$complaint"

# --- a pane with prompts in it ---------------------------------------------
#
# $CASE picks what the last command left behind. The trailing `sleep` keeps
# the pane alive: a pane whose command has exited takes its history with it.
cat >"$emitter" <<'EOF'
#!/bin/sh
printf '\033]133;A\007$ first-command\n'
printf '\033]133;C\007one\ntwo\n'
printf '\033]133;D;0\007'
printf '\033]133;A\007$ second-command\n'
printf '\033]133;C\007THE LAST OUTPUT\n'
printf '\033]133;D;0\007'

case ${CASE:-finished} in
finished) printf '\033]133;A\007$ ' ;;
running) printf '\033]133;A\007$ third-command\n\033]133;C\007still going\n' ;;
esac

sleep 300
EOF

chmod +x "$emitter"

# start_pane CASE -- an inner server showing that pane, with a client of the
# outer server attached to it, and the clipboard file pre-seeded so that a
# copy that should not happen can be told from one that should.
start_pane() {
    tmux -L "$outer" kill-server 2>/dev/null
    tmux -L "$inner" kill-server 2>/dev/null
    printf 'PRE-EXISTING CLIPBOARD' >"$clipboard"

    # A server that is on its way out still answers on its socket, and a
    # new-session that arrives while it does dies with it.
    wait_for "the previous servers are gone" \
        "! tmux -L $inner has-session -t check && ! tmux -L $outer has-session -t driver" ||
        return 1

    tmux -L "$inner" -f "$HOME/.tmux.conf" new-session -d -s check -x 60 -y 12 \
        "env CASE=$1 $emitter" 2>/dev/null
    tmux -L "$inner" set -g copy-command "cat > $clipboard" 2>/dev/null
    tmux -L "$outer" new-session -d -s driver -x 60 -y 12 \
        "tmux -L $inner attach -t check" 2>/dev/null

    # The last thing the emitter writes is the mark the keys navigate by, so
    # waiting for the text before it would be waiting for half a pane.
    wait_for "the pane is drawn and marked" \
        "tmux -L $inner capture-pane -p -t check | grep -q 'THE LAST OUTPUT'" || return 1
    wait_for "a client is attached" \
        "tmux -L $outer list-panes -t driver -F '#{pane_dead}' | grep -q 0" || return 1
    sleep 0.3
}

# press KEY... -- through the attached client, so tmux resolves the key
# against its own tables. `send-keys` to the inner pane would type into the
# emitter instead and never reach a binding.
press() {
    for _key in "$@"; do
        tmux -L "$outer" send-keys -t driver "$_key" 2>/dev/null
        sleep 0.2
    done
}

clipboard_now() {
    cat "$clipboard" 2>/dev/null
}

# The line under the cursor, without what tmux draws over it: copy mode puts
# its position indicator at the top right, which lands in the line's text
# whenever the cursor is on the pane's first visible row.
cursor_line() {
    tmux -L "$inner" display -p -t check '#{copy_cursor_line}' 2>/dev/null |
        sed 's/ *\[[0-9]*\/[0-9]*\] *$//; s/ *$//'
}

# --- prefix o, on a command that finished ----------------------------------

if start_pane finished; then
    press C-b o
    wait_for "the copy reaches the clipboard command" \
        "grep -q 'THE LAST OUTPUT' $clipboard"

    assert_equal "prefix o copies the output of the last command" \
        "THE LAST OUTPUT" "$(clipboard_now)"

    assert_equal "and leaves copy mode" \
        "0" "$(tmux -L "$inner" display -p -t check '#{pane_in_mode}' 2>/dev/null)"
fi

# --- prefix o, with no prompt after the output -----------------------------
#
# The clipboard is the point of these two. Without the guard in the binding
# the selection ends a line above where it started, and tmux replaces whatever
# was on the clipboard with a stray newline.

if start_pane running; then
    press C-b o

    assert_equal "a command still running leaves the clipboard alone" \
        "PRE-EXISTING CLIPBOARD" "$(clipboard_now)"

    assert_equal "and still leaves copy mode" \
        "0" "$(tmux -L "$inner" display -p -t check '#{pane_in_mode}' 2>/dev/null)"
fi

# --- the copy-mode keys ----------------------------------------------------
#
# Pressed, not listed: `list-keys` output would agree with itself even if the
# key in the binding were a `Q`. `prefix [` is tmux's own way into copy mode.

if start_pane finished; then
    press C-b '[' '[' '['

    assert_equal "[ in copy mode walks back to the previous prompt" \
        '$ first-command' "$(cursor_line)"

    press ']'

    assert_equal "] walks forward again" \
        '$ second-command' "$(cursor_line)"
fi

# --- where a copy goes -----------------------------------------------------
#
# ~/.tmux-clipboard.conf is installed on macOS alone, and `source-file -q` is
# what lets the same ~/.tmux.conf work without it, so both halves are checked
# whichever platform this is running on. The pipe itself is covered above:
# `copy-command` is what the copy went through.

if [ -e "$HOME/.tmux-clipboard.conf" ]; then
    tmux -L "$inner" -f "$HOME/.tmux.conf" start-server 2>/dev/null

    assert_equal "the clipboard command is set where the file is installed" \
        "pbcopy" "$(tmux -L "$inner" show -gv copy-command 2>/dev/null)"
else
    tmux -L "$inner" kill-server 2>/dev/null
    tmux -L "$inner" -f "$HOME/.tmux.conf" start-server 2>/dev/null

    assert_equal "no clipboard file, no clipboard command, no error" \
        "" "$(tmux -L "$inner" show -gv copy-command 2>/dev/null)"
fi
