#!/bin/sh
# The startup profiler: it measures every interactive shell, it stays out of
# the way of every other one, and it can be switched off.
#
# All three halves are worth a check. A profiler that never records leaves the
# `--log` summary empty and nobody notices; one that records a `zsh -c` from an
# editor fills the log with shells nobody started; and one that cannot be
# switched off is a line of output at every prompt, for good.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

LOG="$HOME/zsh-startup-check.log"
export LOG
ZSH_STARTUP_LOG="$LOG"
export ZSH_STARTUP_LOG

# What a new terminal tab does: an interactive login shell that reaches a
# prompt, which is the moment the precmd hook fires and the whole mechanism
# runs. Stdin is a pipe rather than a terminal, which is as close as a check
# gets; what comes back is stderr, where the report goes.
startup() {
    : >"$LOG"
    printf 'exit\n' | zsh -li 2>&1 >/dev/null
}

log_lines() {
    if [ -s "$LOG" ]; then
        wc -l <"$LOG" | tr -d ' '
    else
        echo 0
    fi
}

# The timeline, as labels alone: `zshenv zprofile zshrc first prompt`.
timeline() {
    printf '%s\n' "$1" |
        sed -n 's/^ *[0-9][0-9.]* ms  *\([a-z][a-z ]*[a-z]\) *(.*/\1/p' |
        tr '\n' ' ' | sed 's/ *$//'
}

assert_equal "the profiler is installed" \
    "$REPO/rcm/zsh-startup-profile.zsh" \
    "$(readlink "$HOME/.zsh-startup-profile.zsh" 2>/dev/null)"

output=$(startup)

assert_equal "a shell that reaches a prompt is recorded once" 1 "$(log_lines)"

# stamp, milliseconds, terminal, kind -- tab separated, one line per shell, so
# that `cut -f2` and the awk in zsh-startup-bench keep working.
assert_equal "the log line carries stamp, milliseconds, terminal and kind" \
    "4 login" \
    "$(awk -F'\t' 'NR == 1 { printf "%d %s", NF, $4 }' "$LOG")"

if awk -F'\t' 'NR == 1 && $2 ~ /^[0-9]+$/ { found = 1 } END { exit !found }' "$LOG"; then
    pass "the logged duration is a whole number of milliseconds"
else
    fail "the logged duration is a whole number of milliseconds" "$(cat "$LOG")"
fi

assert_equal "the timeline names every startup file, in the order they are read" \
    "zshenv zprofile zshrc first prompt" "$(timeline "$output")"

case $output in
*"not found"*)
    fail "the startup says nothing about a missing command" "$output"
    ;;
*)
    pass "the startup says nothing about a missing command"
    ;;
esac

# The benchmark shape: `zsh -i -c` loads the whole rc chain but never reaches a
# prompt, which is what keeps hyperfine runs out of the production record.
: >"$LOG"
zsh -lic 'exit 0' >/dev/null 2>&1 || true
assert_equal "a shell that never reaches a prompt is not recorded" 0 "$(log_lines)"

: >"$LOG"
zsh -lc true >/dev/null 2>&1 || true
zsh -c true >/dev/null 2>&1 || true
assert_equal "a non-interactive shell is not recorded" 0 "$(log_lines)"

# The off switch, from the environment.
: >"$LOG"
off=$(printf 'exit\n' | ZSH_STARTUP_PROFILE=0 zsh -li 2>&1 >/dev/null)

assert_equal "ZSH_STARTUP_PROFILE=0 records nothing" 0 "$(log_lines)"
assert_equal "ZSH_STARTUP_PROFILE=0 prints no timeline" "" "$(timeline "$off")"

case $off in
*"not found"*)
    fail "the marks are harmless with the profiler switched off" "$off"
    ;;
*)
    pass "the marks are harmless with the profiler switched off"
    ;;
esac

# The off switch, from the file that outlives a shell -- the one a machine uses
# to opt out of what the shared dotfiles switch on.
local_config="$HOME/scriptlets/zsh-startup"
mkdir -p "$HOME/scriptlets"
saved=
if [ -e "$local_config" ]; then
    saved="$local_config.saved-by-check"
    mv "$local_config" "$saved"
fi
printf 'ZSH_STARTUP_PROFILE=0\n' >"$local_config"

off=$(startup)
assert_equal "~/scriptlets/zsh-startup records nothing when it switches the profiler off" \
    0 "$(log_lines)"
assert_equal "~/scriptlets/zsh-startup prints no timeline when it switches the profiler off" \
    "" "$(timeline "$off")"

# Quiet, but still measuring: the state a machine settles into once the number
# is boring.
printf 'ZSH_STARTUP_BUDGET_MS=\n' >"$local_config"
quiet=$(startup)
assert_equal "an empty budget says nothing" "" "$(timeline "$quiet")"
assert_equal "an empty budget keeps recording" 1 "$(log_lines)"

rm -f "$local_config"
if [ -n "$saved" ]; then
    mv "$saved" "$local_config"
fi

# The log is read back by the script that ships with it.
if [ -x "$HOME/bin/zsh-startup-bench" ]; then
    startup >/dev/null
    summary=$("$HOME/bin/zsh-startup-bench" --log 2>&1 || true)
    case $summary in
    *"shells   1"*)
        pass "zsh-startup-bench --log summarises the log"
        ;;
    *)
        fail "zsh-startup-bench --log summarises the log" "$summary"
        ;;
    esac
else
    fail "zsh-startup-bench is installed" "no $HOME/bin/zsh-startup-bench"
fi

# Where the log goes when nothing says otherwise. The directory does not exist
# on a fresh account, and the profiler is the one that has to create it.
(
    unset ZSH_STARTUP_LOG XDG_STATE_HOME
    rm -rf "$HOME/.local/state"
    printf 'exit\n' | zsh -li >/dev/null 2>&1

    if [ -s "$HOME/.local/state/zsh-startup.log" ]; then
        pass "the log lands in ~/.local/state by default"
    else
        fail "the log lands in ~/.local/state by default" \
            "$(ls -la "$HOME/.local" 2>&1)"
    fi
)

rm -f "$LOG"
