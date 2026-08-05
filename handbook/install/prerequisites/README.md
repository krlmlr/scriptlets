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

## What the scripts want

The scripts assume a GNU userland, and a handful of tools besides.
Linux carries nearly all of that in the distribution's own repositories,
under the plain names;
macOS ships the older BSD command wherever a name is shared,
and Homebrew is where both the GNU commands and the rest come from —
the GNU ones under the `g` names its formulae install them with,
which is how the scripts spell them.

| Command | `brew` | `apt` | `dnf` | `pacman` | Wanted by |
| --- | --- | --- | --- | --- | --- |
| `ag` | `the_silver_searcher` | `silversearcher-ag` | `the_silver_searcher` | `the_silver_searcher` | `fsed` |
| `air` | `air` | — | — | — | `air-format` |
| `compare`, `convert`, `display`, `montage` | `imagemagick` | `imagemagick` | `ImageMagick` | `imagemagick` | `imgdiff` and `imgdiff-bg`, `ogv-to-gif` |
| `fd` | `fd` | `fd-find`, installed as `fdfind` | `fd-find` | `fd` | `h` and `s` |
| `gcp`, `grealpath`, `gsort` | `coreutils` | `coreutils` | `coreutils` | `coreutils` | `h` and `s`, `git-backup`, `git-backup-all` |
| `gh` | `gh` | `gh` | `gh` | `github-cli` | `bootstrap-private` |
| `gmake` | `make` | `make` | `make` | `make` | `pmake` |
| `gsed` | `gnu-sed` | `sed` | `sed` | `sed` | `h` and `s`, `fsed`, `git-merge-into`, `git-backup`, `git-backup-all`, `reprex` |
| `gxargs` | `findutils` | `findutils` | `findutils` | `findutils` | `fsed` |
| `hyperfine` | `hyperfine` | `hyperfine` | `hyperfine` | `hyperfine` | `zsh-startup-bench`, for its benchmark mode alone; the log and `zprof` views need nothing but zsh |
| `inotifywait` | — | `inotify-tools` | `inotify-tools` | `inotify-tools` | `rpt` |
| `jq` | `jq` | `jq` | `jq` | `jq` | `azure-resource-group-get-default` |
| `kubectl` | `kubernetes-cli` | — | `kubernetes<release>-client` | `kubectl` | `k` |
| `mmv` | `mmv` | `mmv` | `mmv` | — (AUR) | `git-mmv` |
| `mplayer` | `mplayer` | `mplayer` | — (RPM Fusion) | `mplayer` | `ogv-to-gif` |
| `nproc` | `coreutils`, unprefixed — macOS ships nothing it would collide with | `coreutils` | `coreutils` | `coreutils` | `pmake` |
| `parallel` | `parallel` | `parallel` | `parallel` | `parallel` | `h` and `s`, `each` and `every`, `git-backup-all` |
| `pdftotext` | `poppler` | `poppler-utils` | `poppler-utils` | `poppler` | `pdfcat` |
| `R` | `r` | `r-base` | `R` | `r` | `rh` |
| `rstudio` | `--cask rstudio` | — | — | — (AUR) | `rh` |
| `soffice` | `--cask libreoffice` | — | — | — | `soffice-macos`, which installs on macOS alone |
| `terminal-notifier` | `terminal-notifier` | — | — | — | `n` and `bkg`, which install on macOS alone |
| `unbuffer` | `expect` | `expect` | `expect` | `expect` | `rpt` |
| `wget` | `wget` | `wget` | `wget2-wget` | `wget` | `gh-mirror` |
| `wmctrl` | — | `wmctrl` | `wmctrl` | `wmctrl` | `rh`, to raise an RStudio window that is already open — an X11 lookup, so Linux alone |

The `brew`, `apt` and `dnf` names were read off homebrew-core,
Ubuntu 24.04 and Fedora 44,
and hold for those releases;
the `pacman` column comes from Arch's documentation
rather than from a machine, and is the one nobody here has run.
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

## Linux, with the distribution's own

The GNU commands are the system's own here,
so what is left to install is short —
one line for the scripts in use, one for the scripts under review.

**Debian and Ubuntu.**

```sh
apt install fd-find hyperfine mmv parallel poppler-utils \
  silversearcher-ag wmctrl
apt install expect imagemagick inotify-tools jq mplayer wget
```

**Fedora.**

```sh
dnf install fd-find hyperfine mmv parallel poppler-utils \
  the_silver_searcher wmctrl
dnf install expect ImageMagick inotify-tools jq wget2-wget
```

**Arch.**

```sh
pacman -S fd hyperfine parallel poppler the_silver_searcher wmctrl
pacman -S expect imagemagick inotify-tools jq mplayer wget
```

**The `g` names have to be made.**
The GNU commands carry no prefix on Linux,
while the scripts ask for `gsed`, `gsort`, `gcp` and `grealpath`,
so an install alone leaves `h` and `s`, `git-merge-into`, `reprex`,
`git-backup` and `git-backup-all` calling names that do not exist.
Debian and Fedora install `gmake` themselves, from their `make` package;
Arch does not, so there that name joins the list.
Debian's `fd-find` is the same gap under another spelling —
it installs the binary as `fdfind`,
where Fedora's package of that name installs `fd`,
which is what `h` calls.
`~/.local/bin` is where links for all of them go:
the shipped profiles put it on the `PATH` beside `~/bin`,
and it is not rcm's, so an uninstall walks past them.

```sh
ln -s "$(command -v sed)" ~/.local/bin/gsed
```

**What no distribution here carries.**
`air` comes from Posit's own installer, or from mise;
RStudio as a `.deb` or `.rpm` from Posit, and from the AUR on Arch.
`kubectl` is Debian and Ubuntu's gap alone,
and Kubernetes' own apt repository is what fills it.
Debian's `r-base` trails the current R release —
CRAN's apt repository closes that gap.

*To deepen: run the `pacman` line on an Arch machine;
collect what the shipped configuration reaches for —
`delta`, `daff`, `git-lfs`, `tig`, `diffuse`.*
