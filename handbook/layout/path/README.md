# PATH

The scripts land in `~/bin`,
which no system puts on the `PATH` on its own.

Ubuntu's stock `~/.profile` prepends `~/bin` and then `~/.local/bin`
if the directories exist,
so `~/.local/bin` ends up in front of `~/bin`.
macOS has no counterpart:
`/usr/libexec/path_helper`,
run from `/etc/zprofile` and `/etc/profile`,
builds the `PATH` from `/etc/paths` and `/etc/paths.d`,
both system-wide, and never looks below `$HOME`.
Neither `~/bin` nor `~/.local/bin` is special there.

[`rcm/profile`](/rcm/profile) closes the gap.
Installed as `~/.profile`, it mirrors what Ubuntu does —
`~/bin` and `~/.local/bin` on the `PATH`,
`~/.bashrc` sourced under bash —
so `~/bin` works the same on both platforms,
and [`rcm/bash_profile`](/rcm/bash_profile) has the `~/.profile`
it sources.
[`rcm/zprofile`](/rcm/zprofile) does the same for zsh,
the default shell on macOS since Catalina,
which never reads `~/.profile` on its own.
Whether a pre-existing `~/.profile` survives an install is
[`layout/mapping/`](/handbook/layout/mapping/README.md)'s.

**`~/bin` stays the install target rather than `~/.local/bin`.**
Moving would gain nothing on macOS,
where neither directory is automatic,
and nothing on Ubuntu, where both already are.
It would cost a directory of our own:
`~/.local/bin` is shared with `pipx`, `uv` and `pip install --user`,
while `mise run uninstall` (`rcdn`) is best pointed at a directory
only rcm writes to.
