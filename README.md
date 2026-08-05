# scriptlets

A collection of tiny but helpful shell scripts and configuration files
for personal use.
Tested with current Ubuntu and macOS.
Licensed under [GPL v3](http://www.gnu.org/copyleft/gpl.html).

## Install

To install all scripts to `~/bin` (by creating symbolic links),
install [rcm](https://github.com/thoughtbot/rcm),
clone the project and run `make` — or `mise run install`,
if you have [mise](https://mise.jdx.dev).
rcm is the only thing this needs; mise is optional.
Or run the [`bootstrap`](bootstrap) script:

```sh
curl -s https://raw.githubusercontent.com/krlmlr/scriptlets/main/bootstrap | sh
```

Existing files are kept unless you say otherwise,
and `mise run test` tries everything out
against a throw-away home directory first —
nothing it does touches yours.

## Documentation

Everything this repository documents is reachable from the
[handbook](handbook/README.md), a strict topic hierarchy:

* [installing and uninstalling](handbook/install/README.md) —
  the tasks, the bootstrap script,
  importing a dotfile you already have
* [how the repository maps onto `$HOME`](handbook/layout/README.md) —
  the dot rules, per-user and per-platform tags,
  how `~/bin` gets onto the `PATH`,
  and what changed since the home-grown layout
* [the configuration files](handbook/config/README.md) —
  what installs as what,
  zsh startup profiling, zsh completion
* [the tools](handbook/tools/README.md) —
  every script in `~/bin`, grouped and with its status;
  retired ones are catalogued in [`obsolete/`](obsolete/README.md)
* [the tests](handbook/testing/README.md) —
  the throw-away home directory, the checks, CI

Copyright 2015-2025 Kirill Müller.
