# Tasks

Installation is handled by [rcm](https://github.com/thoughtbot/rcm),
which creates the symbolic links;
the tasks wrap it so that adding a file under `rcm/`
and rerunning `mise run` is enough.
Each task is a script in [`mise-tasks/`](/mise-tasks) —
one file, one task —
reachable through [mise](https://mise.jdx.dev) or through `make`:

| Task | `make` | |
| --- | --- | --- |
| `mise run install` | `make` | link every file into the home directory |
| `mise run force` | `make force` | link every file, replacing ones that already exist |
| `mise run check` | `make check` | list the mapping without touching the filesystem |
| `mise run uninstall` | `make uninstall` | remove every symbolic link rcm owns |
| `mise run nosleep-grant` | `make nosleep-grant` | let `nosleep` flip the sleep flag without a password, on macOS ([`tools/`](/handbook/tools/README.md)) |
| `mise run import <file>` | — | move a file in from the home directory ([`install/import/`](/handbook/install/import/README.md)) |
| `mise run test` | — | run the checks against a throw-away home directory ([`testing/`](/handbook/testing/README.md)) |
| `mise run test-container` | — | the same on Linux, from a machine that is not |

**mise is optional.**
Installing needs nothing but rcm and `make`:
`make install` runs [`mise-tasks/install`](/mise-tasks/install),
the very file `mise run install` runs,
so there is one implementation of each task
and two ways to reach it — nothing that can drift.
Three tasks are mise-only,
and `make` names them and stops rather than pretend:
`import` needs mise to parse its arguments,
and the two test targets run tasks themselves.
[`tests/checks/50-makefile.sh`](/tests/checks/50-makefile.sh)
checks what construction cannot:
that no task was added without a target to reach it by.

**What mise adds, if you have it:**
`mise tasks` lists the tasks with their descriptions,
and `mise run` with no task at all opens a fuzzy picker on a terminal —
no task is aliased to `default`,
so a bare `mise run` asks rather than installs,
and [`tests/checks/15-tasks.sh`](/tests/checks/15-tasks.sh)
keeps it that way.
`mise run import` is the one task `make` cannot offer,
and completion comes along with it.
Its one obligation is trust —
`mise trust` once per clone,
or `mise run` refuses to read `mise.toml`.
The bootstrap script does that for you
([`install/bootstrap/`](/handbook/install/bootstrap/README.md));
so does the test harness,
for the throw-away home directory it installs into.

**The pieces.**
[`mise-tasks/lib.sh`](/mise-tasks/lib.sh) holds the `REPO`, `RCRC` and
`DOTFILES` the tasks share,
and is deliberately not executable:
mise takes every executable file there for a task.
[`mise.toml`](/mise.toml) is what marks the directory as a mise project,
and what `mise trust` trusts;
the tasks are files, so it holds nothing else.
The [`Makefile`](/Makefile) runs those same scripts
for a machine without mise,
and points at mise for the three that need it.
[`mise-tasks/import`](/mise-tasks/import) is the one task
too long for a one-liner.
Every task points `RCRC` at the repository's own copy of `rcrc`,
and the ones that invoke rcm pass `-d`,
so the tasks work from any clone location
and take effect even before — or instead of — an existing `~/.rcrc`
(the mapping that file drives is
[`layout/mapping/`](/handbook/layout/mapping/README.md)'s).

**Uninstalling has one edge.**
`mise run uninstall` (`rcdn`) removes directories it leaves empty,
walking up as far as `$HOME` itself —
harmless on a real home directory,
which always has unrelated content,
but worth knowing in a container.
