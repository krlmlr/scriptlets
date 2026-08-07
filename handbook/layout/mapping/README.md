# The mapping

Everything rcm links into the home directory lives in
[`rcm/`](/rcm).
A name there gains a leading dot on the way to `$HOME`,
so `rcm/bashrc` becomes `~/.bashrc`
and `rcm/ssh/config` becomes `~/.ssh/config`.

The exceptions are listed in the `UNDOTTED` variable in
[`rcm/rcrc`](/rcm/rcrc):
`air.toml`, `bin`, `git`, `log` and `scriptlets` keep their names,
so `rcm/bin/h` becomes `~/bin/h`.
Naming a directory covers everything below it.
The other direction has a rule too:
rcm skips names that already start with a dot inside `rcm/`,
which is why the placeholder that brings `~/log` into existence
is [`rcm/log/dummy`](/rcm/log/dummy), kept dotless.

`rcm/hooks/` is the one name rcm keeps for itself:
it runs what is below it, on every tree it walks, and installs none of it.
A hook is also the one thing here that can put something in the home
directory without a file behind it —
a symbolic link to a path outside the repository is a decision
that has to be made on the machine
([`install/hooks/`](/handbook/install/hooks/README.md)).

**`rcrc` itself** sets `DOTFILES_DIRS`, `UNDOTTED` and `TAGS`
(the tags are [`layout/tags/`](/handbook/layout/tags/README.md)'s),
and is installed as `~/.rcrc`.
`DOTFILES_DIRS` defaults there to `$HOME/git/scriptlets/rcm`,
so a bare `rcup` or `lsrc` finds nothing
unless the clone lives at `~/git/scriptlets`,
where the bootstrap script puts it
([`install/bootstrap/`](/handbook/install/bootstrap/README.md));
a value already in the environment wins instead,
which is how the tasks work from any location
([`install/tasks/`](/handbook/install/tasks/README.md) says how).

**What an install touches.**
`rcup` asks before replacing a file that already exists and differs
(`[ynaq]` — `n` and Enter skip it, `y` replaces one,
`a` replaces all without backup, `q` aborts).
Identical files are linked silently,
and files that do not exist yet are created without asking.
A declined prompt — or one that never reaches a terminal —
leaves the file as it was,
so a machine that came with its own `~/.profile` keeps it
until `mise run force` replaces the files rcm skipped.

**Nothing prunes.**
A file deleted from `rcm/` —
or moved where an account no longer installs it,
such as into a tag directory —
leaves a dangling symbolic link behind in `$HOME`.
Run `mise run uninstall` *before* removing the file;
after the fact,
`find ~ ~/bin -maxdepth 1 -xtype l` lists the strays
and `-delete` removes them.
