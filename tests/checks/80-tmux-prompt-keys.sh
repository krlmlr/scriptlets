#!/bin/sh
# The copy-mode keys in ~/.tmux.conf: bound where they can be reached, and
# landing where the prompt marks say they should.
#
# The prompts here are synthetic -- a script that prints the OSC 133 sequences
# a shell would print -- so this checks tmux's half alone, on a machine whose
# login shell is anything at all. What the shell sends is checked in
# 62-zsh-prompt-marks.sh.
#
# Everything runs on a socket of its own (`-L`), so a tmux the author is
# sitting in while the checks run is neither read nor disturbed.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux: not installed"
    exit 0
fi

# 3.4 is where previous-prompt and next-prompt arrived. An unparseable version
# -- a `next-3.6` build, say -- is skipped rather than guessed at.
version=$(tmux -V 2>/dev/null | sed -n 's/^tmux \([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')
major=${version%%.*}
minor=${version#*.}

if [ -z "$version" ]; then
    skip "tmux: cannot tell the version from $(tmux -V 2>&1)"
    exit 0
fi

if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 4 ]; }; then
    skip "tmux $version: previous-prompt needs 3.4"
    exit 0
fi

assert_equal "~/.tmux.conf is installed" \
    "$REPO/rcm/tmux.conf" "$(readlink "$HOME/.tmux.conf" 2>/dev/null)"

socket=scriptlets-check-$$
emitter=$HOME/.tmux-prompt-emitter

# Two commands with output, as a shell that marks its prompts would leave them
# on screen. The trailing `sleep` keeps the pane alive: a pane whose command
# has exited takes its history with it.
cat >"$emitter" <<'EOF'
#!/bin/sh
printf '\033]133;A\007$ first-command\n'
printf '\033]133;C\007one\ntwo\n'
printf '\033]133;D;0\007'
printf '\033]133;A\007$ second-command\n'
printf '\033]133;C\007THE LAST OUTPUT\n'
printf '\033]133;D;0\007'
printf '\033]133;A\007$ '
sleep 300
EOF
chmod +x "$emitter"

tmux -L "$socket" -f "$HOME/.tmux.conf" new-session -d -s check -x 80 -y 20 \
    "$emitter" 2>/dev/null

cleanup() {
    tmux -L "$socket" kill-server 2>/dev/null
    rm -f "$emitter"
}
trap cleanup EXIT INT TERM

if ! tmux -L "$socket" has-session -t check 2>/dev/null; then
    fail "the configuration file starts a session" \
        "$(tmux -L "$socket" -f "$HOME/.tmux.conf" new-session -d -s check 2>&1)"
    exit 1
fi

pass "the configuration file starts a session"

# The pane is written to by a process; wait for the last line rather than
# guessing at how long that takes.
waited=0
while [ "$waited" -lt 50 ]; do
    case $(tmux -L "$socket" capture-pane -p -t check 2>/dev/null) in
    *"THE LAST OUTPUT"*) break ;;
    esac
    sleep 0.1
    waited=$((waited + 1))
done

# ---------------------------------------------------------------------------
# Bound, and bound in both tables: tmux picks the table from `mode-keys`, whose
# default follows $EDITOR and $VISUAL, so a binding in copy-mode-vi alone is
# reachable only on a machine whose editor happens to be vi.
# ---------------------------------------------------------------------------
for table in copy-mode copy-mode-vi; do
    bound=$(tmux -L "$socket" list-keys -T "$table" 2>/dev/null |
        sed -n 's/.*send-keys -X \(previous-prompt\|next-prompt\)$/\1/p' |
        sort | tr '\n' ' ')
    assert_equal "$table binds [ and ] to prompt navigation" \
        "next-prompt previous-prompt " "$bound"
done

if tmux -L "$socket" list-keys -T prefix o >/dev/null 2>&1; then
    pass "prefix o is bound"
else
    fail "prefix o is bound" "$(tmux -L "$socket" list-keys -T prefix 2>&1)"
fi

# ---------------------------------------------------------------------------
# What the keys do. The command list is the one `prefix o` is bound to; a key
# press cannot be delivered to a session with no client attached, and what is
# worth checking here is the choreography rather than tmux's key lookup.
# ---------------------------------------------------------------------------
copy_last_output() {
    tmux -L "$socket" delete-buffer 2>/dev/null
    tmux -L "$socket" copy-mode -t check
    tmux -L "$socket" send -t check -X history-bottom
    tmux -L "$socket" send -t check -X previous-prompt -o
    tmux -L "$socket" send -t check -X begin-selection
    tmux -L "$socket" send -t check -X next-prompt
    tmux -L "$socket" send -t check -X cursor-up
    tmux -L "$socket" send -t check -X end-of-line
    tmux -L "$socket" send -t check -X copy-pipe-and-cancel
    tmux -L "$socket" show-buffer 2>/dev/null
}

assert_equal "the output of the last command is what gets copied" \
    "THE LAST OUTPUT" "$(copy_last_output)"

assert_equal "copying leaves copy mode" \
    "0" "$(tmux -L "$socket" display -p -t check '#{pane_in_mode}' 2>/dev/null)"

# previous-prompt walks the marked lines: from the prompt at the bottom to the
# one above it, and back down again.
prompt_walk() {
    tmux -L "$socket" copy-mode -t check
    tmux -L "$socket" send -t check -X history-bottom
    for command in "$@"; do
        tmux -L "$socket" send -t check -X "$command"
    done
    tmux -L "$socket" display -p -t check '#{copy_cursor_line}' 2>/dev/null
    tmux -L "$socket" send -t check -X cancel
}

assert_equal "previous-prompt lands on the prompt of the last command" \
    '$ second-command' "$(prompt_walk previous-prompt previous-prompt)"

assert_equal "next-prompt comes back down" \
    '$ second-command' \
    "$(prompt_walk previous-prompt previous-prompt previous-prompt next-prompt)"

# ---------------------------------------------------------------------------
# Where a copy goes. ~/.tmux-clipboard.conf is installed on macOS alone, and
# `source-file -q` is what lets the same ~/.tmux.conf work without it -- so
# both halves are checked, whichever platform this is running on.
# ---------------------------------------------------------------------------
if [ -e "$HOME/.tmux-clipboard.conf" ]; then
    assert_equal "the clipboard command is set where the file is installed" \
        "pbcopy" "$(tmux -L "$socket" show -gv copy-command 2>/dev/null)"
else
    assert_equal "no clipboard file, no clipboard command, no error" \
        "" "$(tmux -L "$socket" show -gv copy-command 2>/dev/null)"
fi

clip=$HOME/.tmux-clipboard-check
tmux -L "$socket" set -g copy-command "cat > $clip"
copy_last_output >/dev/null
assert_equal "a copy is piped through the clipboard command" \
    "THE LAST OUTPUT" "$(cat "$clip" 2>&1)"
rm -f "$clip"
