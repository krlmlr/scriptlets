# The editor

What `$EDITOR` and `$VISUAL` name,
where the value is set and what it falls back to,
and the zsh widget that hands the command line being typed
to whatever they name.

**Both variables carry the same value,
and [`rcm/profile`](/rcm/profile) is where it is set:
`zed --wait`, or `vim` on a machine without the Zed command line.**
`~/.profile` is the file every login shell of this repository reaches —
bash through `~/.bash_profile`, zsh through `~/.zprofile`,
the chain [`layout/path/`](/handbook/layout/path/README.md) describes
for the `PATH` — so the editor is chosen once
and inherited by everything either shell goes on to start.
`~/.zshrc` would reach interactive zsh alone,
and an editor is asked for from far more places than that:
a `git commit` in a script, a `crontab -e` over ssh,
a bash that never became a zsh.

`$VISUAL` is not a courtesy copy.
git reads it before `$EDITOR` on any terminal that is not `dumb`,
and so does zsh's `edit-command-line`,
so a `$VISUAL` left standing is an `$EDITOR` nobody reads.
That is also why the block in [`rcm/zshrc`](/rcm/zshrc)
that hands the editor to the terminal it is running in —
VS Code and Positron, each opening the file in the window
the command was started from —
sets the two together.

**`--wait` is what makes Zed an editor here rather than a launcher.**
`zed FILE` hands the path to the instance already running and returns
immediately, and everything that asks for an editor reads the file back
as soon as the command it started has exited:
`git commit` would take the untouched template as the message,
and the widget below would take back the line it sent.
Both failures are silent, and neither leaves anything to notice later.
A value of more than one word suits both:
git runs the editor through the shell,
and zsh's own function splits the variable before running it.

**A machine without the Zed command line gets vim**,
which is what a Linux box, a container or an ssh session ends up with
unless Zed is installed on it.
The guard is `command -v zed`, a builtin in both shells,
so a login costs no process for asking
(the standard the whole zsh startup is held to is
[`config/zsh-startup/`](/handbook/config/zsh-startup/README.md)'s).
It asks for that name only:
Zed's Linux packages carry the command line themselves
and some distributions name it `zeditor`,
and a machine spelling it that way falls back to vim
until something links the name `zed` onto the `PATH`.

**On macOS the `zed` command comes from Zed itself.**
The application installs `/usr/local/bin/zed` when the `cli: install`
command is run from its command palette
([Zed's CLI reference](https://zed.dev/docs/reference/cli)),
and nothing in this repository installs, links or checks for it —
an account that has never run that command is an account
that gets the fallback.

**`^X^E` opens the command line being typed in that editor.**
[`rcm/zshrc`](/rcm/zshrc) autoloads zsh's own `edit-command-line`,
registers it as a widget and binds it;
the widget writes the line to a temporary file,
runs the editor on it,
and replaces the line with what the file holds when the editor exits —
the same requirement as `git commit`'s, from the other end.
`autoload` registers a name and reads nothing,
so a shell that never presses the key never opens the file.

**git is left to find the editor in the environment.**
[`rcm/gitconfig`](/rcm/gitconfig) sets no `core.editor`:
git's order is `$GIT_EDITOR`, then `core.editor`, then `$VISUAL`
and `$EDITOR`, so setting it would only mean a second place to change
the value and a second answer to `git var GIT_EDITOR`.
