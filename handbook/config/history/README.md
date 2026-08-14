# The eternal history

Every command every interactive zsh runs is kept,
in one file per day under `~/.zsh_history.d`,
reachable from the shell for as far back as the in-memory list goes
and with `grep` for everything older.
[`rcm/zshrc`](/rcm/zshrc) is where it is set up,
and [`rcm/bashrc`](/rcm/bashrc) does the same job for bash.

## The layout

A day-file is named for the day it covers and holds that day's commands,
so no single file grows without bound
and a day nobody asks about is never read.
`legacy.log` beside them holds what a single-file `~/.zsh_history` had
before the directory existed;
it is moved there once, the first time the configuration runs.

The day is local time, and the name comes from prompt expansion
rather than from `date` —
this runs at every prompt,
and a fork there would be a fork per command.
The format string is quoted:
unquoted, the parameter expansion ends at the first `}` it meets,
which is the one belonging to `%D`,
and the second lands in the file name.
The date is spelled that way twice,
where `$HISTFILE` is set and again in the rotation hook,
and only one of the two shows up in the name a shell reports —
the hook quietly corrects the other,
which is why both spellings are checked
([`testing/`](/handbook/testing/README.md)).

## What is in memory, and what is on disk

`SHARE_HISTORY` appends each command to the day-file as it is entered
and imports what other shells have appended,
so concurrent sessions stay in sync with no hook of any kind —
which is what bash needs `PROMPT_COMMAND` for.
The consequence worth holding on to:
**the day's commands are on disk before any hook runs.**

Prior days are read back at startup, oldest first, with `fc -R`,
so that the in-memory list reaches further than today.
`$HISTFILE` is skipped there, because zsh reads it itself,
and reading it twice puts every entry in the list twice —
which the arrow keys then walk through one duplicate at a time.

**The read is eager, and cannot usefully be deferred to the first `Ctrl-R`.**
`fc -R` appends to the end of the in-memory list,
so a file read after a prompt has been reached
lands older commands *after* newer ones,
and the arrow keys walk them in that order.
`Ctrl-R` is also not the only thing that list serves:
`Up`, `Down`, `!!`, `fc` and `history` all read it and nothing else.
Deferring the cost therefore means giving up the in-memory list
and letting something outside the shell answer searches instead.

The cost is per line rather than per file —
measured with zsh 5.9 on Linux, about 13 ms and 5 MB of resident memory
per megabyte of history read,
so it is set by how much history there is
rather than by how many days it is spread over.
`HISTSIZE` and `SAVEHIST` are both set to ten million in
[`rcm/zshrc`](/rcm/zshrc),
which is what stops the list being trimmed at either end.

## Nothing is written when the day turns

The rotation hook runs from `precmd` and does one thing:
it points `$HISTFILE` at today,
so that a shell left open overnight starts writing to the new day
without being restarted.

**It may not write, and neither may anything else on that path.**
`fc -A` appends every entry zsh did not itself write,
which is the whole preloaded history and not just the day's commands,
so a write from this hook copies every prior day
into the file it is leaving —
and the next shell preloads that file too.
`fc -W` is worse, writing the entire list unconditionally.
Since `SHARE_HISTORY` has already put the day's commands in the day's file,
there is nothing left for either of them to protect.
A check pins it, because nothing about a bigger file fails on its own.

The same constraint does not reach bash,
whose `history -a` appends only the lines the session added
and excludes what `history -r` read —
which is why [`rcm/bashrc`](/rcm/bashrc) appends at every prompt
and this file never does.

## The counts are the point

`HIST_IGNORE_ALL_DUPS` is deliberately off.
It keeps only the most recent instance of a command,
which is exactly the frequency information that makes a kept history worth
keeping: which commands get typed often enough to deserve a script in `~/bin`
is a question only the counts can answer,
and the wrapper-script issues in this repository's tracker
were each found by counting a cluster here.
`HIST_IGNORE_DUPS` still collapses a command repeated back to back,
and `HIST_IGNORE_SPACE` keeps a command out of the history altogether
when it is typed with a leading space.

## Repairing a directory

A directory that was written while the rotation hook did append
holds each entry once for every day since it was run, and often more.
[`rcm/bin/zsh-history-repair`](/rcm/bin/zsh-history-repair) puts it back:
it leaves every timestamped entry exactly once,
in the file for the day it was run on and in the order it was run,
with `legacy.log` keeping the entries that carry no timestamp.
Its `-h` owns the detail, including where the originals are kept.

**What it cannot recover** is the difference between a copy and a genuine
repeat within one second:
entries are compared whole, timestamp and elapsed time included,
so two runs of one command in the same second that also took the same time
to run collapse into one.
`HIST_IGNORE_DUPS` had already dropped those where they were typed back to
back, which is most of them.
