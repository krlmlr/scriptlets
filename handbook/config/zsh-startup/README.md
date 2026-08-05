# zsh startup profiling

Every interactive zsh times its own startup,
appends one line to `~/.local/state/zsh-startup.log`,
and says what it cost before the first prompt:

```
zsh startup 61 ms
     0.4 ms  zshenv           (+0.4)
     6.1 ms  zprofile         (+5.7)
     8.2 ms  zshrc            (+2.1)
    61.0 ms  first prompt     (+52.8)
```

Startup time is a number that only ever grows,
one `eval "$(… init -)"` at a time,
and it grows below the threshold anyone would notice on a single day.
Measuring it continuously, from real shells,
is the cheapest way to catch the line that cost 200 ms
on the day it was added rather than a year later.

## The mechanism

[`rcm/zsh-startup-profile.zsh`](/rcm/zsh-startup-profile.zsh)
is the whole mechanism, installed as `~/.zsh-startup-profile.zsh`,
and [`rcm/zshenv`](/rcm/zshenv) sources it on its first line —
`~/.zshenv` is the first file every zsh reads,
so nothing that runs later could see the time the earlier files took.
The last line of each of the three startup files calls
`zsh_startup_mark`, which appends to an array;
one `precmd` hook then prints the timeline before the first prompt
and unhooks itself.
There are no forks in any of it,
and a non-interactive shell — every script, every `zsh -c` —
returns after two builtin statements.
`~/.zshenv` also defines a no-op `zsh_startup_mark`
where the profiler declines to,
which is what keeps the marks in the startup files quiet
when profiling is switched off —
or when `~/.zshenv` arrived without the profiler beside it.

Each line is what that file had cost by the time it was *done*,
and the `(+…)` is that file's own share.
The last gap is the one no benchmark can see:
`first prompt` minus `zshrc` is everything the terminal itself does
after the configuration has finished —
shell integration, session restore, the terminal's own rc hooks.
`zsh -i -c 'exit 0'` never reaches a prompt,
so benchmark runs are absent from the log by construction.

## Turning it off

The knobs are environment variables,
and the place to set them on one machine is
`~/scriptlets/zsh-startup`,
which the profiler sources before it does anything else.
That file is not shipped here — it is yours, per machine
([`layout/tags/`](/handbook/layout/tags/README.md) has the
`~/scriptlets/` convention).
Anything exported before zsh starts works too,
which is what makes `ZSH_STARTUP_PROFILE=0 zsh` a one-shot escape.

| Set | Effect |
| --- | --- |
| `ZSH_STARTUP_BUDGET_MS=500` | say nothing unless a startup exceeds the budget; keep recording |
| `ZSH_STARTUP_BUDGET_MS=` | say nothing, ever; keep recording |
| `ZSH_STARTUP_MARKS=` | keep the one-line notice, drop the timeline below it |
| `ZSH_STARTUP_LOG=` | stop recording; keep the notice |
| `ZSH_STARTUP_PROFILE=0` | off entirely: nothing is loaded, nothing is timed, nothing is written |

So the usual progression is
`ZSH_STARTUP_BUDGET_MS=500` once the number is boring —
the log keeps filling, and only a regression speaks up —
and `ZSH_STARTUP_PROFILE=0` when even that is unwelcome.
The timeline is only ever printed under the notice it breaks down,
so silencing the notice silences both.

Off is off at the source: with `ZSH_STARTUP_PROFILE=0`
the profiler returns before it loads a module or defines a function,
and the no-op `zsh_startup_mark` in `~/.zshenv`
absorbs the three marks left behind in the startup files.
Removing the profiler for good is a matter of deleting
`rcm/zsh-startup-profile.zsh` and the
`# >>> zsh startup profiling >>>` blocks —
run `mise run uninstall` *before* deleting the file,
or the symbolic link in `$HOME` is left dangling.

The log is append-only and never rotated —
one short line per shell, four tab-separated fields.
Trim it when it gets long:

```sh
tail -n 5000 ~/.local/state/zsh-startup.log > ~/.local/state/zsh-startup.log.tmp &&
  mv ~/.local/state/zsh-startup.log.tmp ~/.local/state/zsh-startup.log
```

## Reading the numbers

[`zsh-startup-bench`](/rcm/bin/zsh-startup-bench)
answers three different questions
on top of the log the profiling keeps anyway:

```sh
zsh-startup-bench           # hyperfine: this configuration against the bare floor
zsh-startup-bench --zprof   # per-function breakdown of a single startup
zsh-startup-bench --log     # summarise the continuous log
```

`--log` is the number to trust:
it comes from real shells on this machine —
count, min, median, p90, max and mean,
broken down by terminal and by login versus interactive.
It is the only view that reflects a cold cache, a busy laptop,
or a terminal that starts a login shell
where you expected an interactive one.

The benchmark compares three shells:
a login shell (what a new tab starts),
a plain interactive one (a `zsh` inside an existing tab),
and `zsh -f`, the same binary with no rc files at all.
The floor is what makes the rest legible —
40 ms of zsh plus 600 ms of our own configuration
is a different verdict from 640 ms of zsh.
The gap between the first two is a finding in itself:
only login shells read `/etc/zprofile` and `~/.zprofile`,
which on macOS fork `path_helper` and `brew shellenv`.
This mode is the one that needs `hyperfine`
([`install/prerequisites/`](/handbook/install/prerequisites/README.md)).

`--zprof` ranks the functions of a single startup.
Read the ranking, not the total:
loading `zprof` instruments every function call
and inflates what it measures,
and it sees function calls *only* —
a top-level `eval`, a bare `source` or a fork
never appears in the table.

`--runs` and `--top` set the benchmark's run count
and the length of the `zprof` table;
`-h` prints the commentary above in full.
