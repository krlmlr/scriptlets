# Importing a file you already have

`mise run import` moves a file from the home directory
into the repository and links it back where it was:

```sh
mise run import ~/.foorc          # -> rcm/foorc, linked back as ~/.foorc
mise run import ~/bin/foo         # -> rcm/bin/foo, linked back as ~/bin/foo
mise run import -t "$(id -un)" ~/.foorc   # -> rcm/tag-<you>/foorc
```

`git add` is left to you, and the task prints the command.

**Why not `mkrc`.**
rcm ships [`mkrc`](https://github.com/thoughtbot/rcm) for this,
and [`mise-tasks/import`](/mise-tasks/import) exists
because `mkrc` gets the `UNDOTTED` names wrong:
`mkrc ~/bin/foo` moves the file to `rcm/bin/foo` correctly
but links it back as `~/.bin/foo`,
because rcup applies `UNDOTTED` when it walks the whole tree
and not when it is handed a single file.
The task picks the name the way the tree walk will,
then lets rcup link.

**What it refuses:**
a file that is already a symbolic link
(imported once already, or not yours to move),
one outside `$HOME`,
and one whose name has no leading dot and is not in `UNDOTTED` —
`~/notes.txt` would come back as `~/.notes.txt`,
so the name has to go into `UNDOTTED` first
(the rule itself is
[`layout/mapping/`](/handbook/layout/mapping/README.md)'s).

## Picking the file

mise has no file browser, and there is nothing to browse with.
The bare `mise run` picker
([`install/tasks/`](/handbook/install/tasks/README.md))
offers task names only, not their arguments;
what mise does have is argument completion,
which is where the file comes in.
`import` declares its completion in the `#USAGE` header,
and offers the dotfiles in `$HOME` that are still regular files —
a file already imported is a symbolic link,
so it drops off the list by itself.

Completion needs two things:
the [`usage`](https://usage.jdx.dev) CLI,
which is what generates it (`mise use -g usage`),
and mise's completions loaded in your shell.
Without `usage` on the `PATH`,
mise's completion script says so instead of completing.
For zsh, the shipped `~/.zshrc` registers mise's completion lazily
([`config/completion/`](/handbook/config/completion/README.md));
bash and fish are on their own —
`mise completion bash` or `fish`.
