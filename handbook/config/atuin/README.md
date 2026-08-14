# Ctrl-R with atuin

The history files keep everything;
[atuin](https://atuin.sh) is what makes everything searchable —
a database of its own, a full-screen search on `Ctrl-R`,
and, once `atuin login` has been run, the same history on every machine.
[`rcm/zshrc`](/rcm/zshrc) picks it up where it is installed
and does nothing at all where it is not,
leaving `Ctrl-R` to zsh.
What the shells keep for themselves — the files the arrows, `fc` and `!!`
read, and what a leading space does to each store — is
[`config/history/`](/handbook/config/history/README.md)'s.

**The generated init script is written to a file, not evaluated.**
`atuin init zsh` writes a shell script to standard output,
and the line atuin's documentation gives —
`eval "$(atuin init zsh)"` —
starts a process to produce that script at every interactive shell.
What it writes changes when atuin is upgraded or reconfigured
and not from one shell to the next,
so it goes to `${XDG_CACHE_HOME:-~/.cache}/zsh/atuin-init.zsh`,
is compiled to wordcode beside it,
and is sourced from there afterwards —
the same treatment, and for the same reason, as the completion dump
([`config/completion/`](/handbook/config/completion/README.md)).

The file is rewritten whenever it is older than the `atuin` binary
or than `~/.config/atuin/config.toml`.
Both matter: the `tmux`, `ai`, `pty_proxy` and `dotfiles` settings
all change what `atuin init` prints.
Neither test costs a process:
the path to the binary is one zsh has already resolved,
so an ordinary shell start is two stats and a `source`.

**An mtime is a proxy for a version rather than a promise of one.**
A tool behind a shim (mise, asdf) is upgraded
without the shim being touched,
and a binary unpacked from an archive can arrive
with an mtime older than the file it ought to replace.
Neither is noticed, and the answer to both —
and to anything else this gets wrong — is to delete the pair:

```sh
rm -f ${XDG_CACHE_HOME:-~/.cache}/zsh/atuin-init.zsh*
```

The next shell builds both files again.
Writing over the script instead
leaves the wordcode beside it older than the script it was compiled from,
so zsh goes back to parsing the script,
and nothing notices,
because the script is then newer than atuin as well.

**A rewrite that goes wrong leaves the working file alone.**
Everything happens to a file named for the shell doing the work,
renamed into place only once it is not empty and compiles;
the wordcode goes first, so no shell finds a new script
beside the wordcode of the one before it.
Both tests earn their place:
`atuin init` prints nothing and exits 0
when it finds its own paths broken,
and a write cut short leaves a script that does not parse,
so `zcompile` is the validation as much as the optimisation.
Sourcing is guarded on the same test rather than on the file's existence,
so a machine where the file could never be written in the first place —
a read-only cache directory, an atuin that has never worked —
gets a shell without `Ctrl-R` rather than an error before every prompt.

**One process is left, and it is atuin's rather than ours.**
The generated script asks for a session id (`atuin uuid`) as it is read,
once per interactive shell — nested ones included,
since it takes a new session id whenever `$SHLVL` has changed.

**`--disable-up-arrow` leaves the `Up` arrow to zsh.**
It walks the lines this session ran, in order,
which is a different question from the one `Ctrl-R` asks
and the one the shell answers better.
`Down` is never atuin's to take;
the flag also leaves `k` alone in vi command mode.
