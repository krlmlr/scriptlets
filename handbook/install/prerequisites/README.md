# Prerequisites

What must be installed before anything here works,
and what individual scripts assume beyond that.

[rcm](https://github.com/thoughtbot/rcm) is the one hard prerequisite —
`apt install rcm`, `brew install rcm`.
[mise](https://mise.jdx.dev)
(`curl https://mise.run | sh`, or Homebrew) is optional:
`make` installs without it,
and only `import` and the tests need it
([`install/tasks/`](/handbook/install/tasks/README.md) has the split).

The [GitHub CLI](https://cli.github.com) is needed by one script alone:
[`bootstrap-private`](/bootstrap-private) creates a repository with it,
and says what to do by hand where it is missing
([`layout/private/`](/handbook/layout/private/README.md)).

Putting `~/bin` on the `PATH` is not among the things left to you:
the shipped profiles do it, on macOS as well as on Ubuntu
([`layout/path/`](/handbook/layout/path/README.md)).

**What single scripts assume** — a GNU userland,
under Homebrew's `g` names where macOS ships something older:

* `h` and `s` need `fd`, `gsed`, `gsort` and GNU `parallel`
* `fsed` needs `ag`, `gsed` and `gxargs`
* `pmake` needs `gmake`; `git-merge-into` needs `gsed`
* `n` and `bkg` need `terminal-notifier`,
  and are installed on macOS only
* `rpt` needs `inotifywait` and `unbuffer`
* `git-mmv` needs `mmv`; `imgdiff` needs ImageMagick
* `zsh-startup-bench` needs `hyperfine` for its benchmark mode alone
  (`brew install hyperfine`, `apt install hyperfine`);
  reading the log and the `zprof` breakdown needs nothing but zsh

What each of those scripts is for is
[`tools/`](/handbook/tools/README.md)'s.
