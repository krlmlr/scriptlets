# The mapping

Everything that ends up in the home directory lives in
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

**`rcrc` itself** sets `DOTFILES_DIRS`, `UNDOTTED` and `TAGS`
(the tags are [`layout/tags/`](/handbook/layout/tags/README.md)'s),
and is installed as `~/.rcrc`.
It hardcodes `DOTFILES_DIRS="$HOME/git/scriptlets/rcm"`,
so a bare `rcup` or `lsrc` finds nothing
unless the clone lives at `~/git/scriptlets`,
where the bootstrap script puts it
([`install/bootstrap/`](/handbook/install/bootstrap/README.md));
the tasks pass `-d` and work from any location.

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
