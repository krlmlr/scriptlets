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

## What single scripts assume

A GNU userland,
under Homebrew's `g` names where macOS ships something older,
and a handful of tools besides:

* `h` and `s` need `fd`, `gsed`, `gsort` and GNU `parallel`
* `fsed` needs `ag`, `gsed` and `gxargs`
* `pmake` needs `gmake` and `nproc`;
  `git-merge-into` and `reprex` need `gsed`
* `git-backup` needs `gcp`, `grealpath` and `gsed`,
  and `git-backup-all` adds GNU `parallel`,
  which `each` and `every` need as well
* `n` and `bkg` need `terminal-notifier`,
  and are installed on macOS only —
  as is `soffice-macos`, which drives LibreOffice
* `rpt` needs `inotifywait` and `unbuffer`
* `git-mmv` needs `mmv`;
  `imgdiff` needs ImageMagick, and `ogv-to-gif` adds `mplayer`
* `pdfcat` needs `pdftotext`; `gh-mirror` needs `wget`;
  `k` needs `kubectl`; `azure-resource-group-get-default` needs `jq`
* `air-format` needs `air`;
  `rh` needs R and RStudio,
  and `wmctrl` where an X11 window manager has a window to raise
* `zsh-startup-bench` needs `hyperfine` for its benchmark mode alone;
  reading the log and the `zprof` breakdown needs nothing but zsh

Which of them are in use and which are under review,
and what each one is for,
is [`tools/`](/handbook/tools/README.md)'s.

## Where they come from

One line for the scripts in use, one for the scripts under review.
The names were read off homebrew-core, Ubuntu 24.04 and Fedora 44,
and hold for those releases;
the `pacman` lines come from Arch's documentation rather than from a
machine, and are the ones nobody here has run.

**macOS, with Homebrew.**

```sh
brew install air coreutils fd findutils gnu-sed hyperfine \
  kubernetes-cli make mmv parallel poppler the_silver_searcher
brew install terminal-notifier                    # n and bkg, macOS alone
brew install expect imagemagick jq mplayer wget   # under review
```

**Debian and Ubuntu.**

```sh
apt install fd-find hyperfine mmv parallel poppler-utils \
  silversearcher-ag wmctrl
apt install expect imagemagick inotify-tools jq mplayer wget   # under review
```

**Fedora.**

```sh
dnf install fd-find hyperfine mmv parallel poppler-utils \
  the_silver_searcher wmctrl
dnf install expect ImageMagick inotify-tools jq wget2-wget     # under review
```

**Arch.**

```sh
pacman -S fd hyperfine parallel poppler the_silver_searcher wmctrl
pacman -S expect imagemagick inotify-tools jq mplayer wget     # under review
```

R, RStudio and LibreOffice are applications rather than packages of
that kind, and stay out of those lines:
`brew install r` and the `rstudio` and `libreoffice` casks on macOS,
`r-base` or `R` from the distribution on Linux.

## Where a package is not named after the command

* `fd` is `fd-find` on Debian, Ubuntu and Fedora —
  and Debian installs the binary as `fdfind`,
  which is not what `h` calls
* `ag` is `silversearcher-ag` on Debian and Ubuntu
* `pdftotext` is `poppler-utils`, and `poppler` on Arch and Homebrew
* `unbuffer` is `expect`, and `inotifywait` is `inotify-tools`
* ImageMagick's `compare`, `convert`, `display` and `montage`
  are `imagemagick` — `ImageMagick` on Fedora
* the GNU commands are `coreutils`, `findutils` and `make`,
  and `sed` is `gnu-sed` on Homebrew alone
* `kubectl` is `kubernetes-cli` on Homebrew,
  and `kubernetes<release>-client` on Fedora, a package per release
* `wget` on Fedora comes from `wget2-wget`
* `gh` is `github-cli` on Arch

## What the package manager does not have

* `air` — Posit's own installer, or mise
* RStudio — a `.deb` or `.rpm` from Posit, and the AUR on Arch
* `kubectl` on Debian and Ubuntu — Kubernetes' own apt repository
* `mmv` on Arch — the AUR; `mplayer` on Fedora — RPM Fusion
* `inotify-tools` on macOS — inotify is a Linux kernel interface,
  and the formula is Linux-only,
  so the watching half of `rpt` has no macOS spelling at all;
  its `unbuffer` does, from `expect`
* `terminal-notifier` anywhere but macOS,
  which is also the only place the scripts wanting it install
* a current R on Debian and Ubuntu:
  `r-base` trails the release, and CRAN's apt repository closes the gap

## What installing does not fix

**The `g` names have to be made on Linux.**
The GNU commands are the system's own there and carry no prefix,
while the scripts ask for `gsed`, `gsort`, `gcp` and `grealpath`,
so an install alone leaves `h` and `s`, `git-merge-into`, `reprex`,
`git-backup` and `git-backup-all` calling names that do not exist.
`~/.local/bin` is where links for them go:
the shipped profiles put it on the `PATH` beside `~/bin`,
and it is not rcm's, so an uninstall walks past them.

```sh
ln -s "$(command -v sed)" ~/.local/bin/gsed
```

`gmake` comes with Debian's and Fedora's `make` package;
Arch's does not install that name, so there it joins the list.

**ImageMagick is built without X11 on macOS**,
so the `display` that `imgdiff` ends in
has no window system to open there,
while `compare` and `montage` are unaffected.

**The Azure scripts drive an `azure` command** no manager here carries;
Homebrew's `azure-cli` installs `az`, which is a different one.

*To deepen: run the `pacman` lines on an Arch machine;
collect what the shipped configuration reaches for —
`delta`, `daff`, `git-lfs`, `tig`, `diffuse`, `zed`.*
