# Shell history

Every command every interactive shell runs, kept forever,
one plain-text file per day under `~/.zsh_history.d`
and `~/.bash_history.d`.
Searching it is [`config/atuin/`](/handbook/config/atuin/README.md)'s;
this page is what the shells themselves keep, and what for.

**The shells' own history is not the same store as atuin's,
and both are wanted.**
atuin answers `Ctrl-R` from a database of its own.
The files here are what the arrow keys, `fc`, `history` and `!!` read,
what a `grep` reaches when atuin is not installed or cannot start,
and what survives an atuin that is one day replaced.

**Nothing here is a default.**
Stock zsh saves no history at all — `SAVEHIST` is `0`,
`HISTSIZE` is 30, and every option [`rcm/zshrc`](/rcm/zshrc) sets is off:
`EXTENDED_HISTORY` for the timestamp and elapsed time on each entry,
`SHARE_HISTORY` so concurrent shells append as they go and pick up
each other's lines,
`HIST_IGNORE_SPACE`, `HIST_IGNORE_DUPS` and `HIST_REDUCE_BLANKS`.
`HIST_IGNORE_ALL_DUPS` is unset explicitly although it is off already:
it would keep only the most recent instance of a command
and so destroy the counts,
and a line saying so is cheaper than rediscovering why it matters.

**The file name comes from prompt expansion, not from `date`.**
`${(%):-"%D{%Y-%m-%d}"}` is strftime without a process,
which matters because the rollover below runs it at every prompt.
The quotes are load-bearing:
without them the parameter expansion ends at the format's first `}`
and the second one lands in the file name.

**Rollover happens at the prompt, not at midnight.**
A shell left open overnight notices at its next prompt
that today's name has changed,
appends what it has with `fc -A` — never `fc -W`,
which would write the whole preloaded list into today's file —
and points `$HISTFILE` at the new day.

## What a shell reads at startup

The newest `$ZSH_HISTORY_PRELOAD_DAYS` day-files, 30 by default,
oldest first so the in-memory list ends up in the order the commands ran.
Today's file counts toward that number and is then skipped,
because zsh loads `$HISTFILE` itself
and reading it twice duplicates every entry —
so what a shell starts with is the twenty-nine days before today.
`legacy.log`, the migrated single-file history, is not preloaded at all.

Today's own commands arrive at the first prompt rather than at startup:
`SHARE_HISTORY` is what imports them, and a shell that never reaches a
prompt — `zsh -ic` — never has them.

The bound is the point.
`fc -R` costs about 0.09 ms per file — the cost is per file, not per line —
and the directory gains one every day:

| preloaded | at every shell start |
| --- | --- |
| 365 files | 33 ms |
| 1095 files | 94 ms |

Unbounded, a shell that starts instantly this year starts perceptibly
slower in three, for history the arrows will never reach.
What is not preloaded is not lost:
it is on disk, and it is what atuin searches.
Raising the number is a matter of exporting it before the shell starts;
the cost of doing so is the table above
([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md)
is how to measure it).

## What a leading space does, and does not

`HIST_IGNORE_SPACE` keeps a space-prefixed command out of the shell's
history. It does not keep it out of atuin's.
atuin records from a `preexec` hook, which receives the line as typed,
leading space and all,
and its own filters — `history_filter`, `cwd_filter`, `secrets_filter` —
are what it decides by;
the first two are empty unless `~/.config/atuin/config.toml` says otherwise.

So the habit still hides a command from `Ctrl-R`'s predecessor
while leaving it in the store `Ctrl-R` now searches.
A `history_filter` of `^\s` in that file is where the two would be made to
agree.

*To deepen: the bash half runs the same design through `PROMPT_COMMAND`
and `$(date)`, and is not written out here yet.*
