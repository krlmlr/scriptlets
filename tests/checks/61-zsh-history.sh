#!/bin/sh
# What an interactive zsh reads out of ~/.zsh_history.d at startup
# (config/history/): the newest few days and no more.
#
# The bound is the claim worth pinning. Reading every day-file ever written
# works, and goes on working, and costs one more file read at every shell
# start for every day that passes -- a regression nothing would report,
# because nothing fails.
#
# The history is fabricated: day-files named for 2020, so that whatever today
# is they sort below it, each holding one command that says which day it came
# from. `fc -l` is what the shell is asked, rather than $history, because it
# reports the list in order and an associative array does not.
#
# The question goes in on a pipe rather than through `zsh -ic`, which never
# reaches a prompt: SHARE_HISTORY imports today's file at the first one, so a
# shell that never gets there is missing exactly the part worth checking.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

dir=$HOME/.zsh_history.d
mkdir -p "$dir"
rm -f "$dir"/2020-*.log "$dir"/legacy.log

day=1
while [ "$day" -le 35 ]; do
    printf ': %s:0;echo day-%02d\n' "$((1700000000 + day))" "$day" \
        >"$dir/2020-01-$(printf '%02d' "$day").log"
    day=$((day + 1))
done

printf ': 1600000000:0;echo from-legacy\n' >"$dir/legacy.log"

# loaded PATTERN [NAME=VALUE...] -- how many entries an interactive zsh has in
# its history list matching PATTERN, once it has finished starting.
loaded() {
    _pattern=$1
    shift
    printf 'fc -l 1\n' | env "$@" zsh -i 2>/dev/null | grep -c "$_pattern"
}

assert_equal "the newest day-file is read" "1" "$(loaded 'day-35')"

# 35 files, a window of 30, and today's own file among them: the oldest stay
# on disk unread.
assert_equal "one beyond the window is not" "0" "$(loaded 'day-01')"

assert_equal "the migrated single-file history is not read either" \
    "0" "$(loaded 'from-legacy')"

# The default is a fact of its own: 30 files, today's counted among them and
# skipped, so the twenty-nine days before it are what a shell arrives with.
# The shell says so by what it reads, not by what the file says it reads.
assert_equal "the window is 30 files unless something says otherwise" \
    "1 0" "$(loaded 'day-07') $(loaded 'day-06')"

assert_equal "and the window is what the environment says when it says" \
    "0 1" \
    "$(loaded 'day-32' ZSH_HISTORY_PRELOAD_DAYS=3) $(loaded 'day-34' ZSH_HISTORY_PRELOAD_DAYS=3)"

# Today's file is the one zsh loads itself, so the preload has to leave it
# alone or every entry in it arrives twice.
# Anything before the marker on the line is the shell's own doing -- the
# prompt marks land on the same line as what a piped shell prints
# (config/prompt-marks/).
today=$(printf 'print -r -- "HISTFILE=${HISTFILE:t}"\n' |
    zsh -i 2>/dev/null | sed -n 's/.*HISTFILE=//p' | tail -n 1)
printf ': %s:0;echo from-today\n' "$(date +%s)" >>"$dir/$today"

assert_equal "today's file is read once, not twice" "1" "$(loaded 'from-today')"

# The name it is read from, which the rollover recomputes at every prompt and
# compares against: a stray brace there would mean a new file every day and a
# rollover that never settles.
case $today in
[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].log)
    pass "the day-file is named for the day and nothing else"
    ;;
*)
    fail "the day-file is named for the day and nothing else" "HISTFILE=$today"
    ;;
esac

rm -f "$dir"/2020-*.log "$dir"/legacy.log
