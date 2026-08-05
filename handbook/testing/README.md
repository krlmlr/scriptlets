# Testing

`mise run test` installs everything into a throw-away home directory
and runs the checks in [`tests/checks`](/tests/checks) against it.
The real home directory is never touched,
so the checks are safe to run on the machine you use.
`mise run test-container` does the same inside a container,
for a Linux run from a machine that is not Linux.

[`tests/run`](/tests/run) needs `rcup` and `mise` on the `PATH` —
this is the one place mise is not optional,
because the checks run tasks
([`install/tasks/`](/handbook/install/tasks/README.md)).
It creates the home directory
and seeds it the way a stock account is seeded:
on Ubuntu with `.bashrc`, `.profile` and `.bash_logout`
from `/etc/skel`, which is what `useradd -m` copies,
on macOS with nothing at all.
The three are taken by name rather than wholesale,
because `/etc/skel` is also where an image builder drops extras —
the CI runner's `/etc/skel` carries a `~/.bash_profile`
no stock Ubuntu account has,
and seeding it would test the CI image instead of the platform.

`$XDG_CACHE_HOME` is pointed at that home directory too.
`$HOME` alone is not enough:
what a shell caches goes to `$XDG_CACHE_HOME` wherever that is set,
so on a machine that sets it
the checks would delete and rewrite the real user's cache
while believing they were working in a directory of their own.
The other XDG directories are deliberately left alone,
because mise reads its own configuration and state from them
and these checks run mise.

**In CI**,
[`.github/workflows/test.yaml`](/.github/workflows/test.yaml)
runs the suite on Ubuntu and on macOS.
Both matter:
on Ubuntu the scripts are found
because the stock `~/.profile` finds them,
on macOS only because this repository ships the equivalent,
so a break in the shipped profiles
([`layout/path/`](/handbook/layout/path/README.md))
shows up in the macOS job alone.

## The checks

Each file in `tests/checks` is a separate script
that sources [`tests/lib.sh`](/tests/lib.sh)
for `pass`, `fail` and the assertions,
and they run in name order:

- `05-handbook`: the handbook holds its shape —
  every directory has a `README.md`,
  every subdirectory is in its parent's list,
  every link resolves, and none reaches upward
  ([`meta/handbook/`](/handbook/meta/handbook/README.md)
  has the rules it enforces).
  It reads the repository, not the home directory,
  so it is first, before the installed checks.
- `10-path`: the scripts are on the `PATH` of a login shell,
  in every shell an account may log in with, and they run.
- `15-tasks`: a bare `mise run` offers the task list
  instead of running one.
- `20-install`: every destination rcm lists exists,
  configuration files are symbolic links,
  and installing twice changes nothing.
- `30-preexisting`: an account that came with its own
  `~/.bash_profile` keeps it,
  and `make force` is what makes the scripts reachable there.
  It brings its own home directory.
- `40-import`: `mise run import` puts a dotfile and an `UNDOTTED` name
  where they belong, refuses what it should,
  and leaves the real repository alone.
  It works on a copy,
  because importing *moves* files into the repository.
- `50-makefile`: the `Makefile` fallback agrees with the tasks
  it stands in for,
  and the targets it does not implement say so instead of pretending.
- `60-zsh-startup`: a zsh startup complains about nothing,
  and `~/.zshrc` binds `mise` to the stub —
  the generated completion is *not* loaded at startup,
  and the first completion loads it and rebinds to it.
  It also covers the completion dump:
  written and compiled by the first shell, trusted by the next,
  re-audited once the stamp is a day old,
  and rebuilt on demand by `zsh-compinit-refresh`
  ([`config/completion/`](/handbook/config/completion/README.md)).
  The audit is observed through a sentinel written into the stamp,
  which the audit truncates —
  mtimes cannot tell a re-audit within the same second
  from no audit at all.
- `65-zsh-startup-profile`: a shell that reaches a prompt is timed,
  recorded once and broken down by startup file;
  one that does not — a script, a `zsh -c`, a benchmark run —
  is left alone;
  and every documented way of turning the profiling off
  ([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md))
  turns it off.
- `67-zsh-atuin`: the generated atuin init script
  ([`config/atuin/`](/handbook/config/atuin/README.md))
  is written to a file and sourced from there
  rather than produced at every shell,
  rewritten when the binary or the configuration file is newer than it,
  never replaced by an empty or half-written one,
  and absent without complaint where atuin is not installed.
  A stand-in `atuin` on the `PATH` counts its own runs
  and fails the ways the real one fails,
  so the checks neither need the real atuin nor want it —
  the one case that does need the machine's own answer,
  no atuin at all, is skipped where there is one.
- `70-git-ssh-remote`: `git ssh-remote` converts the HTTPS GitHub
  remotes of a throw-away repository
  and leaves every other remote alone,
  through `~/bin` and through the `git sr` alias alike.
- `90-force`: `mise run force` replaces the files rcm skipped,
  and the scripts are still found afterwards.
  It runs last because it is the one check
  that rewrites what the others read.

Adding a file to `tests/checks` is enough;
`tests/run 10-path` runs one check by name,
and `KEEP_TEST_HOME=1` leaves the home directory behind to look at.
