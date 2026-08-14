# mise in the shell

[mise](https://mise.jdx.dev) puts the tools a directory asks for
on the `PATH`,
and it is activated in both interactive shells —
[`rcm/zshrc`](/rcm/zshrc) and [`rcm/bashrc`](/rcm/bashrc) —
from a generated script kept on disk.
Where it is not installed, neither section does anything.
mise's other role here, as the runner behind `mise run install`,
is [`install/tasks/`](/handbook/install/tasks/README.md)'s;
this page is only about the shell.

**The generated activation script is written to a file, not evaluated.**
`mise activate zsh` writes a shell script to standard output,
and the line mise's documentation gives —
`eval "$(mise activate zsh)"` —
starts a process to produce that script at every interactive shell.
What it writes changes when mise is upgraded,
and not from one shell to the next,
so it goes to a file under `${XDG_CACHE_HOME:-~/.cache}/`,
in zsh is compiled to wordcode beside it,
and is sourced from there afterwards —
the same treatment, and for the same reason, as the completion dump
([`config/completion/`](/handbook/config/completion/README.md)).

**The file is named for the binary it was generated from.**
`mise activate` writes the absolute path of its own binary into the
script, so a file generated from one mise is wrong for another:
sourced, it would keep calling the first,
however the `PATH` has since been ordered.
The path therefore goes into the file name,
its slashes turned into dashes —
`~/.cache/zsh/mise-activate-usr-local-bin-mise.zsh`
for a mise at `/usr/local/bin/mise` —
so a second mise, Homebrew's beside the one `mise.run` installed,
generates and reads a file of its own.

**A rewrite is due when the binary is newer than the file.**
That is one stat of a path the shell has already resolved,
against a file it is about to read;
neither shell forks to decide.
An mtime is a proxy for a version rather than a promise of one:
a mise unpacked from an archive can arrive
with an mtime older than the file it ought to replace,
and one reached through a shim is upgraded
without the shim being touched.
The answer to both — and to anything else this gets wrong —
is to delete the file:

```sh
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh/mise-activate-*.zsh* \
      "${XDG_CACHE_HOME:-$HOME/.cache}"/bash/mise-activate-*.bash
```

The next shell of each kind builds its own again.
Writing over the zsh script instead
leaves the wordcode beside it older than the script it was compiled from,
so zsh goes back to parsing the script,
and nothing notices,
because the script is then newer than mise as well.

**A rewrite that goes wrong leaves the working file alone.**
Everything happens to a file named for the shell doing the work,
renamed into place only once it is not empty and parses;
in zsh the wordcode goes first,
so no shell finds a new script beside the wordcode of the one before it.
zsh gets its parse check from `zcompile`, which it wants anyway;
bash pays a `bash -n` for the same answer,
and pays it on the rewrite alone,
which is once per mise rather than once per shell.
Sourcing is guarded on the same test rather than on the file's existence,
so a machine where the file could never be written in the first place —
a read-only cache directory, a mise that cannot run —
gets a shell without mise
rather than an error before every prompt.

## What this does not remove

The activation script mise generates calls `mise hook-env`
as it is sourced, from a `precmd` hook at every prompt,
and from a `chpwd` hook on every directory change —
the last standing in for that prompt's run rather than adding to it.
Those are what `mise activate` *is*,
and caching the script neither adds nor removes one:
counted with `strace` over an interactive zsh,
a warm shell that ran three commands and one `cd`
executed mise five times,
and the same shell built by `eval` executed it six.
The one this saves is the `activate` run,
and it is the one that happens before the first prompt,
which is where the shell's startup budget is
([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md)).

**Only interactive shells are activated.**
`~/.zshrc` and `~/.bashrc` are read by no others,
so a script, a `zsh -c` from an editor or a cron job
sees the `PATH` it would have seen without mise.

The arrangement is pinned by
[`tests/checks/68-zsh-mise.sh`](/tests/checks/68-zsh-mise.sh)
and [`tests/checks/69-bash-mise.sh`](/tests/checks/69-bash-mise.sh),
which put a stand-in `mise` on the `PATH`
rather than asking the machine's own
([`testing/`](/handbook/testing/README.md)).
