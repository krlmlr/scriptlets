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

The scripts assume a GNU userland,
and macOS is where that assumption costs something:
where a name is shared, what it ships is the older BSD command,
and some of what the scripts call it does not ship at all.
Homebrew answers both,
the GNU commands under the `g` names its formulae install them with —
which is why the scripts spell them `gsed`, `gsort`, `gxargs`.

The scripts in use want:

```sh
brew install air coreutils fd findutils gnu-sed hyperfine \
  kubernetes-cli make mmv parallel poppler the_silver_searcher
```

`n` and `bkg` install on macOS alone and want one formula more:

```sh
brew install terminal-notifier
```

The scripts under review want:

```sh
brew install expect imagemagick jq mplayer wget
```

Which script is in which state, and what each of them does, is
[`tools/`](/handbook/tools/README.md)'s.

| Formula | Installs | Wanted by |
| --- | --- | --- |
| `air` | `air`, the R formatter | `air-format` |
| `coreutils` | `gcp`, `grealpath`, `gsort`, and `nproc`, which needs no `g` because macOS ships nothing it would collide with | `h` and `s`, `pmake`, `git-backup`, `git-backup-all` |
| `expect` | `unbuffer` | `rpt` |
| `fd` | `fd` | `h` and `s` |
| `findutils` | `gxargs` | `fsed` |
| `gnu-sed` | `gsed` | `h` and `s`, `fsed`, `git-merge-into`, `git-backup`, `git-backup-all`, `reprex` |
| `hyperfine` | `hyperfine` | `zsh-startup-bench`, for its benchmark mode alone; the log and `zprof` views need nothing but zsh |
| `imagemagick` | `compare`, `convert`, `display`, `montage` | `imgdiff` and `imgdiff-bg`, `ogv-to-gif` |
| `jq` | `jq` | `azure-resource-group-get-default` |
| `kubernetes-cli` | `kubectl` | `k` |
| `make` | `gmake` | `pmake` |
| `mmv` | `mmv` | `git-mmv` |
| `mplayer` | `mplayer` | `ogv-to-gif` |
| `parallel` | GNU `parallel` | `h` and `s`, `each` and `every`, `git-backup-all` |
| `poppler` | `pdftotext` | `pdfcat` |
| `terminal-notifier` | `terminal-notifier` | `n`, `bkg` |
| `the_silver_searcher` | `ag` | `fsed` |
| `wget` | `wget` | `gh-mirror` |

**Some scripts want an application rather than a formula.**
`rh` wants R and RStudio —
`brew install r`, or CRAN's own installer,
and `brew install --cask rstudio`.
`soffice-macos` wants LibreOffice,
`brew install --cask libreoffice`,
whose `soffice` wrapper is the command the script calls.
`rh` also reaches for `wmctrl` to raise an RStudio window that is
already open, which is an X11 tool and finds one on Linux;
on macOS the lookup comes back empty
and the script launches `RStudio.app` instead.

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

*To deepen: the apt spellings of the same list,
and what the shipped configuration reaches for —
`delta`, `daff`, `git-lfs`, `tig`, `diffuse`.*
