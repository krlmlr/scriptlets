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

Putting `~/bin` on the `PATH` is not among the things left to you:
the shipped profiles do it, on macOS as well as on Ubuntu
([`layout/path/`](/handbook/layout/path/README.md)).

## What the scripts want

The scripts assume a GNU userland, and a handful of tools besides.
Debian and Ubuntu carry nearly all of that in their own repositories,
under the plain names;
macOS ships the older BSD command wherever a name is shared,
and Homebrew is where both the GNU commands and the rest come from —
the GNU ones under the `g` names its formulae install them with,
which is how the scripts spell them.

| Command | macOS, `brew install` | Debian and Ubuntu, `apt install` | Wanted by |
| --- | --- | --- | --- |
| `ag` | `the_silver_searcher` | `silversearcher-ag` | `fsed` |
| `air` | `air` | — | `air-format` |
| `compare`, `convert`, `display`, `montage` | `imagemagick` | `imagemagick` | `imgdiff` and `imgdiff-bg`, `ogv-to-gif` |
| `fd` | `fd` | `fd-find`, which installs it as `fdfind` | `h` and `s` |
| `gcp`, `grealpath`, `gsort` | `coreutils` | `coreutils`, as `cp`, `realpath`, `sort` | `h` and `s`, `git-backup`, `git-backup-all` |
| `gmake` | `make` | `make` | `pmake` |
| `gsed` | `gnu-sed` | `sed` | `h` and `s`, `fsed`, `git-merge-into`, `git-backup`, `git-backup-all`, `reprex` |
| `gxargs` | `findutils` | `findutils`, as `xargs` | `fsed` |
| `hyperfine` | `hyperfine` | `hyperfine` | `zsh-startup-bench`, for its benchmark mode alone; the log and `zprof` views need nothing but zsh |
| `inotifywait` | — | `inotify-tools` | `rpt` |
| `jq` | `jq` | `jq` | `azure-resource-group-get-default` |
| `kubectl` | `kubernetes-cli` | — | `k` |
| `mmv` | `mmv` | `mmv` | `git-mmv` |
| `mplayer` | `mplayer` | `mplayer` | `ogv-to-gif` |
| `nproc` | `coreutils`, unprefixed — macOS ships nothing it would collide with | `coreutils` | `pmake` |
| `parallel` | `parallel` | `parallel` | `h` and `s`, `each` and `every`, `git-backup-all` |
| `pdftotext` | `poppler` | `poppler-utils` | `pdfcat` |
| `R` | `r` | `r-base` | `rh` |
| `rstudio` | `--cask rstudio` | — | `rh` |
| `soffice` | `--cask libreoffice` | — | `soffice-macos`, which installs on macOS alone |
| `terminal-notifier` | `terminal-notifier` | — | `n` and `bkg`, which install on macOS alone |
| `unbuffer` | `expect` | `expect` | `rpt` |
| `wget` | `wget` | `wget` | `gh-mirror` |
| `wmctrl` | — | `wmctrl` | `rh`, to raise an RStudio window that is already open — an X11 lookup, so Linux alone |

Which script is in which state, and what each of them does, is
[`tools/`](/handbook/tools/README.md)'s.

## macOS, with Homebrew

The scripts in use:

```sh
brew install air coreutils fd findutils gnu-sed hyperfine \
  kubernetes-cli make mmv parallel poppler the_silver_searcher
```

`n` and `bkg` install on macOS alone and want one formula more:

```sh
brew install terminal-notifier
```

The scripts under review:

```sh
brew install expect imagemagick jq mplayer wget
```

**What Homebrew does not cover.**
`rpt` waits for a change with `inotifywait`,
and inotify is a Linux kernel interface:
the `inotify-tools` formula is Linux-only,
so the watching half of that script has no macOS spelling —
its `unbuffer` does, from `expect` above.
ImageMagick is built without X11 on macOS,
so the `display` that `imgdiff` ends in
has no window system to open there,
while `compare` and `montage` are unaffected.
The Azure scripts drive an `azure` command Homebrew does not carry;
its `azure-cli` formula installs `az`, which is a different command.

## Debian and Ubuntu, with apt

The GNU commands are the system's own here,
so what is left to install is short.
The scripts in use:

```sh
apt install fd-find hyperfine mmv parallel poppler-utils \
  silversearcher-ag wmctrl
```

The scripts under review:

```sh
apt install expect imagemagick inotify-tools jq mplayer wget
```

**The `g` names have to be made.**
Debian's `sed`, `sort`, `cp` and `realpath` are the GNU ones already
and carry no prefix,
while the scripts ask for `gsed`, `gsort`, `gcp` and `grealpath`,
so an install alone leaves `h` and `s`, `git-merge-into`, `reprex`,
`git-backup` and `git-backup-all` calling names that do not exist.
`fd-find` is the same gap under another name:
it installs the binary as `fdfind`, and `h` calls `fd`.
`~/.local/bin` is where links for them go —
the shipped profiles put it on the `PATH` beside `~/bin`,
and it is not rcm's, so an uninstall walks past them:

```sh
ln -s "$(command -v sed)" ~/.local/bin/gsed
```

`gmake` is the one that needs nothing:
Debian's `make` package installs that name itself.

**What apt does not carry.**
`air` comes from Posit's own installer, or from mise;
`kubectl` from Kubernetes' apt repository;
RStudio as a `.deb` from Posit.
The distribution's `r-base` trails the current R release —
CRAN's own apt repository is what closes that gap.

*To deepen: what the shipped configuration reaches for —
`delta`, `daff`, `git-lfs`, `tig`, `diffuse`.*
