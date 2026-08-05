# zsh completion

`~/.zshrc` starts zsh's completion system with a dump
it audits once a day and trusts in between.

`compinit -i` does not skip the security audit,
it only stops it from asking:
compaudit still stats every directory in `$fpath`,
which on macOS means Homebrew's `site-functions`
and a good part of `/usr/share`.
`zsh-startup-bench --zprof`
([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md))
put `compinit` at 95% of the rc chain's function time,
and half of *that* was compaudit.
The audit is worth doing.
It is not worth doing at every single shell start.

So [`rcm/zshrc`](/rcm/zshrc) audits
when the dump is more than a day old,
and every shell in between takes `compinit -C`,
which trusts the dump and calls no compaudit at all.
The dump is compiled to wordcode as well —
zsh reads `zcompdump-<version>.zwc` in place of the dump
whenever it is newer,
and parsing the dump is most of what `-C` leaves behind.
Both live under `~/.cache/zsh/`,
next to a `.audited` stamp that dates the last audit.

The stamp is a separate file rather than the dump's own mtime
for a reason:
compinit rewrites the dump
only when the number of completion functions has changed,
so on a machine that installs nothing
the dump's mtime stands still —
and using it as the clock would mean auditing at every start
from the second day on.

**The tradeoff** is that a tool installed today
does not complete until tomorrow.
That is what
[`zsh-compinit-refresh`](/rcm/bin/zsh-compinit-refresh) is for:

```sh
zsh-compinit-refresh    # then `exec zsh`, or just open a new tab
```

It removes the dump, its wordcode and the stamp,
and lets a fresh interactive zsh build a new one through `~/.zshrc`,
so the rebuild has one implementation
and the script only decides when it runs.
The shell you run it from keeps the completions it started with —
they are loaded, not looked up — hence the `exec zsh`.
A leftover `~/.zcompdump` from before the dump moved into `~/.cache`
is removed too.

**Going further was declined.**
Not running `compinit` at all until the first Tab
is worth about another 10 ms and is awkward here:
`bashcompinit`, the `complete` calls `~/.bash_aliases` makes,
`compdef _mise_lazy mise` and `compdef g=git`
all need `compdef` to exist at startup,
so it takes a queueing `compdef` stub
and a Tab widget that replays the queue.
More to go wrong than the few lines the audit takes in `~/.zshrc`,
for a smaller win.

**mise's completion is registered lazily.**
`mise completion zsh` shells out to `usage`
([`install/import/`](/handbook/install/import/README.md)
is why the CLI is around at all),
which is a process or two at every shell start,
so a stub stands in until the first Tab on a `mise` command line
and hands over to the real completion from then on.

The whole arrangement is pinned by
[`tests/checks/60-zsh-startup.sh`](/tests/checks/60-zsh-startup.sh):
the dump written and compiled by the first shell,
trusted by the next,
re-audited once the stamp is a day old,
and rebuilt on demand by `zsh-compinit-refresh`.
