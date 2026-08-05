# scriptlets

A collection of tiny but helpful shell scripts and configuration files
for personal use.
Tested with current Ubuntu and macOS.
Licensed under [GPL v3](http://www.gnu.org/copyleft/gpl.html).

Everything here is documented in the [handbook](handbook/README.md),
a strict topic hierarchy;
this page is derived from it, and links where it would explain.

## Install

To install all scripts to `~/bin` (by creating symbolic links),
install [rcm](https://github.com/thoughtbot/rcm),
clone the project and run `make` — or `mise run install`,
if you have [mise](https://mise.jdx.dev).
rcm is the only thing this needs; mise is optional
([`install/`](handbook/install/README.md)).
Or run the [`bootstrap`](bootstrap) script:

```sh
curl -s https://raw.githubusercontent.com/krlmlr/scriptlets/main/bootstrap | sh
```

Files you already have are kept unless you say otherwise,
and `mise run test` rehearses everything
against a throw-away home directory first
([`testing/`](handbook/testing/README.md)) —
nothing touches yours.

## Prerequisites

The scripts want a GNU userland and a handful of tools besides.
Linux carries nearly all of that already;
macOS gets it from Homebrew, the GNU commands under their `g` names.
[`install/prerequisites/`](handbook/install/prerequisites/README.md)
has a line per package manager — `apt`, `dnf`, `pacman`, `brew` —
with what wants what, the names each one spells differently,
and what none of them carries.

## Inside

* [Tools](handbook/tools/README.md) that earn their keep:
  `h` and `s` run a command — or a Git command —
  in every repository below the current directory;
  `git ssh-remote` turns the HTTPS remotes a fresh clone comes with
  into SSH ones;
  `git bifurcate` tags the fork points of a history.
* [Every interactive zsh times its own startup](handbook/config/zsh-startup/README.md),
  says what it cost before the first prompt, and keeps a log,
  so the line that added 200 ms is caught the day it lands —
  and zsh's completion dump is
  [audited once a day, not once a shell](handbook/config/completion/README.md).
* [Configuration](handbook/config/README.md) for bash, zsh, Git, SSH,
  R, vim, screen and more,
  linked into place by rcm under
  [per-user and per-platform tags](handbook/layout/README.md),
  with `~/bin` put on the `PATH` on macOS too.
* [`mise run import`](handbook/install/import/README.md)
  moves a dotfile you already have into the repository
  and links it back where it was.

Copyright 2015-2025 Kirill Müller.
