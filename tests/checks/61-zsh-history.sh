#!/bin/sh
# The eternal history: what a day-file is called, what reaches the in-memory
# list, and what the rotation hook is allowed to write.
#
# The last of those is the one that earns a check. Rotation used to append, and
# what it appended was the preloaded history along with the day's own commands,
# so a day-file grew by the size of every day before it -- daily, compounding,
# and invisibly, because history that is never read back looks fine on disk.
# Nothing about a bigger file fails, which is why the guard has to be here.
#
# `zsh-history-repair` is the other half: the directories already written that
# way are repaired rather than abandoned, and the check covers what it promises
# -- one copy of each entry, in the day it was run on, and nothing touched that
# is not history.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

PATH="$HOME/bin:$PATH"
export PATH

dir=$HOME/.zsh_history.d

# ask INPUT -- what an interactive zsh prints for INPUT, `probe=` lines only.
#
# On a pipe rather than through `zsh -ic`: the history hooks run from precmd,
# and `-c` never reaches a prompt. Which is also why the match is not anchored
# -- a shell that reaches a prompt sends the prompt marks, and they arrive on
# the front of the line the answer is on. stderr is dropped, because a
# system-wide zshrc with opinions of its own is not ours to fix.
ask() {
    printf '%s\n' "$1" | zsh -i 2>/dev/null | sed -n 's/.*probe=//p' | tail -n 1
}

# seed DAY COMMAND -- one entry in DAY's file, stamped inside DAY.
#
# The epoch is noon UTC of a date far enough back that no timezone puts it on
# another day, so the file name and the stamp agree wherever this runs.
seed() {
    mkdir -p "$dir"
    printf ': %s:0;%s\n' "$2" "$3" >>"$dir/$1.log"
}

# --- the name of a day-file -------------------------------------------------
#
# `${(%):-%D{...}}` unquoted ends the expansion at %D's own brace and leaves the
# second one in the file name, which is how `2026-08-13}.log` came about. The
# date is spelled twice -- once where $HISTFILE is set, once in the rotation hook
# -- so the name is asked for twice: `zsh -ic` never reaches a prompt and so
# reports what ~/.zshrc set, and the directory afterwards reports what the hook
# did with it. Either spelling alone is a bug, and the hook silently corrects
# the other one, so neither question catches both.

rm -rf "$dir"

assert_match "the day-file ~/.zshrc names is the day and nothing else" \
    '*/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].log' \
    "$(zsh -ic 'print "probe=$HISTFILE"' 2>/dev/null | sed -n 's/.*probe=//p' | tail -n 1)"

rm -rf "$dir"

assert_equal "no day-file is written under any other name" \
    "" \
    "$(ask 'print "probe=done"' >/dev/null
    find "$dir" -type f | sed "s|$dir/||" |
        grep -v '^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\.log$' || true)"

# --- what the preload reaches -----------------------------------------------

rm -rf "$dir"
seed 2020-01-02 1577966400 'echo seeded-from-a-prior-day'

assert_equal "a prior day's commands are in the in-memory list" \
    "1" \
    "$(ask 'print "probe=$(fc -l 1 | grep -c seeded-from-a-prior-day)"')"

# Today's file is zsh's own $HISTFILE, and reading it a second time would put
# every entry in the list twice -- which the arrow keys walk through one
# duplicate at a time.
rm -rf "$dir"
mkdir -p "$dir"
today=$(zsh -c 'print -r -- ${(%):-"%D{%Y-%m-%d}"}')
printf ': %s:0;%s\n' 1577966400 'echo seeded-into-today' >>"$dir/$today.log"

assert_equal "today's file is read once, not twice" \
    "1" \
    "$(ask 'print "probe=$(fc -l 1 | grep -c seeded-into-today)"')"

# --- how far back the preload reaches ---------------------------------------
#
# Every day-file was read at every shell start, and the directory gains one a
# day, so the read grew with the account's age for entries the arrow keys never
# reach. It is bounded now, and the bound is what is checked: a slower shell
# fails nothing on its own.
#
# Thirty-one seeded days, and today's file counts toward the window too, so the
# newest thirty are today and the twenty-nine before it -- which reaches back
# to the third of the seeded month and no further.

rm -rf "$dir"

day=1
while [ "$day" -le 31 ]; do
    seed "2020-01-$(printf '%02d' "$day")" \
        "$((1577880000 + (day - 1) * 86400))" \
        "echo seeded-day-$(printf '%02d' "$day")"
    day=$((day + 1))
done

printf ': %s:0;%s\n' 1500000000 'echo seeded-from-legacy' >>"$dir/legacy.log"

assert_equal "the newest day-files are read" \
    "1 1" \
    "$(ask 'print "probe=$(fc -l 1 | grep -c seeded-day-31) $(fc -l 1 | grep -c seeded-day-03)"')"

assert_equal "the days beyond the window are not" \
    "0 0" \
    "$(ask 'print "probe=$(fc -l 1 | grep -c seeded-day-02) $(fc -l 1 | grep -c seeded-day-01)"')"

assert_equal "and neither is the migrated single-file history" \
    "0" \
    "$(ask 'print "probe=$(fc -l 1 | grep -c seeded-from-legacy)"')"

# The window is a number a shell can be told, and the default is the fact worth
# pinning: the shell says which it used by what it read.
assert_equal "the environment sets how many days are read" \
    "1 0" \
    "$(ZSH_HISTORY_PRELOAD_DAYS=3 ask 'print "probe=$(fc -l 1 | grep -c seeded-day-30) $(fc -l 1 | grep -c seeded-day-29)"')"

# --- the rotation hook writes nothing ---------------------------------------
#
# $HISTFILE is pointed at a day that is not today -- the state a shell is in
# when the date turns under it -- and the hook is then called by hand.
#
# All on one command line, and it has to be: the hook also runs from precmd, so
# anything spread over two lines has been rotated back before the second is
# read, and the branch under test never runs.
#
# The command itself is appended to whichever file was $HISTFILE when it was
# entered, which is today's. So nothing but the hook can write the stale file,
# and the seeded entries appearing in it is the regression.

rm -rf "$dir"
seed 2020-01-02 1577966400 'echo seeded-before-rotation'
seed 2020-01-03 1578052800 'echo also-seeded-before-rotation'

stale=$dir/1999-12-31.log

assert_equal "rotation does not write the preloaded history into the day it leaves" \
    "0" \
    "$(ask "HISTFILE=$stale; __zsh_history_rotate; print \"probe=\$(cat $stale 2>/dev/null | grep -c seeded-before-rotation || true)\"")"

assert_match "rotation leaves \$HISTFILE at today's file" \
    "*/$today.log" \
    "$(ask "HISTFILE=$stale; __zsh_history_rotate; print \"probe=\$HISTFILE\"")"

# --- zsh-history-repair -----------------------------------------------------

if [ ! -x "$HOME/bin/zsh-history-repair" ]; then
    fail "zsh-history-repair is installed" "not executable at ~/bin"
    exit 0
fi

pass "zsh-history-repair is installed"

# A directory in the state the old rotation left: day-files named with the
# stray brace, each carrying a verbatim copy of every day before it, one entry
# stranded in a file for a day it was not run on, and a file that is not
# history at all.
#
# The stamps are noon UTC on three consecutive days in 2020, so the day each
# entry belongs to is the same wherever this runs.
rm -rf "$dir"
mkdir -p "$dir"

one=1577966400  # 2020-01-02 12:00 UTC
two=1578052800  # 2020-01-03 12:00 UTC
three=1578139200 # 2020-01-04 12:00 UTC

{
    printf ': %s:0;echo one\n' "$one"
    printf ': %s:0;echo spans\\\n' "$one"
    printf 'two lines\n'
    printf ': %s:0;echo stranded\n' "$three"
} >"$dir/2020-01-02}.log"

{
    printf ': %s:0;echo one\n' "$one"
    printf ': %s:0;echo spans\\\n' "$one"
    printf 'two lines\n'
    printf ': %s:0;echo two\n' "$two"
} >"$dir/2020-01-03}.log"

printf 'an entry with no timestamp at all\n' >"$dir/legacy.log"
printf 'not history\n' >"$dir/notes.txt"

report=$(zsh-history-repair --apply "$dir" 2>&1)

# Four entries were run -- `one`, the one that spans two lines, `two`,
# `stranded` -- against the ten the copies made of them.
assert_equal "the repair drops the copies a rotation left behind" \
    "4" \
    "$(cat "$dir"/2020-01-0*.log | grep -c '^: ')"

assert_equal "each day-file holds the entries stamped inside that day" \
    "yes" \
    "$(if [ "$(grep -c "^: $one:" "$dir/2020-01-02.log")" = 2 ] &&
        [ "$(grep -c "^: $two:" "$dir/2020-01-03.log")" = 1 ] &&
        [ "$(grep -c "^: $three:" "$dir/2020-01-04.log")" = 1 ]; then
        echo yes
    else
        echo "no
$report"
    fi)"

# The continuation is how zsh writes a newline inside a command, so the two
# lines have to arrive together and in that order, or the command is two.
assert_equal "a command that spans lines survives whole" \
    ": $one:0;echo spans\\
two lines" \
    "$(sed -n '2,3p' "$dir/2020-01-02.log")"

assert_equal "the entries with no timestamp stay in legacy.log" \
    "an entry with no timestamp at all" \
    "$(cat "$dir/legacy.log")"

assert_equal "a file that is not history is left alone" \
    "not history" \
    "$(cat "$dir/notes.txt")"

assert_equal "the stray brace is gone from every name" \
    "" \
    "$(find "$dir" -name '*}*' | sed "s|$dir/||")"

assert_match "the originals are kept" \
    "*2020-01-02}.log*" \
    "$(find "$HOME" -name '2020-01-02}.log' -path '*.backup-*' | head -n 1)"

# Nothing left to do: the promise that makes it safe to run twice, and the one
# that says the repaired shape is the shape it aims for.
assert_match "running it again changes nothing" \
    "*0 duplicate entries dropped*" \
    "$(zsh-history-repair "$dir" | tr '\n' ' ')"

rm -rf "$dir" "$dir".backup-*
