# scriptlets

A collection of tiny but helpful shell scripts and configuration files for personal use.
Tested with current Ubuntu and macOS.
Licensed under [GPL v3](http://www.gnu.org/copyleft/gpl.html).

To install all scripts to `~/bin` (by creating symbolic links), install [rcm](https://github.com/thoughtbot/rcm), clone the project and type `make`.
Or run the [`bootstrap`](bootstrap) script:

```sh
curl -s https://raw.githubusercontent.com/krlmlr/scriptlets/main/bootstrap | sh
```

# Build and install

Installation is handled by [rcm](https://github.com/thoughtbot/rcm),
which creates the symbolic links.
Adding a file under `rcm/` and rerunning `make` is enough.

## Layout

Everything that ends up in the home directory lives in [`rcm/`](rcm).
A name there gains a leading dot on the way to `$HOME`,
so `rcm/bashrc` becomes `~/.bashrc` and `rcm/ssh/config` becomes `~/.ssh/config`.

The exceptions are listed in the `UNDOTTED` variable in [`rcm/rcrc`](rcm/rcrc):
`air.toml`, `bin`, `git`, `log` and `scriptlets` keep their names,
so `rcm/bin/h` becomes `~/bin/h`.
Naming a directory covers everything below it.

`rcup` asks before replacing a file that already exists and differs
(`[ynaq]` — `n` and Enter skip it, `y` replaces one, `a` replaces all without backup, `q` aborts).
Identical files are linked silently, and files that do not exist yet are created without asking.

## Per-user overrides

A `tag-<NAME>/` directory holds files for one account:
[`rcm/tag-kirill/scriptlets/gitconfig`](rcm/tag-kirill/scriptlets/gitconfig)
installs to `~/scriptlets/gitconfig`.

[`rcm/rcrc`](rcm/rcrc) is sourced as shell, so it selects the tag itself:

```sh
TAGS="$(id -un)"
```

An account with no matching `tag-` directory installs nothing extra.
Tags are not limited to user names:
`rcup -t work` selects a `tag-work/` directory *instead of* the per-user one,
and a `host-<hostname>/` directory is picked up automatically like a tag.

The three files under `~/scriptlets/` are read by the configuration that ships here —
[`rcm/gitconfig`](rcm/gitconfig) includes `scriptlets/gitconfig`,
[`rcm/ssh/config`](rcm/ssh/config) includes `~/scriptlets/ssh-config`,
and [`rcm/Rprofile`](rcm/Rprofile) sources `~/scriptlets/Rprofile` if it exists.
Each tolerates the file being absent,
which is why an unknown account needs no tag directory.

## Per-platform overrides

Files that only work on one operating system live in
[`rcm/tag-macos/`](rcm/tag-macos) or [`rcm/tag-linux/`](rcm/tag-linux),
and are installed nowhere else.
[`rcm/rcrc`](rcm/rcrc) picks the tag from `uname -s`:

```sh
case "$(uname -s)" in
  Darwin) OS_TAG="macos" ;;
  Linux) OS_TAG="linux" ;;
  *) OS_TAG="" ;;
esac

TAGS="$(id -un) $OS_TAG"
```

A system that is neither gets no platform tag,
and therefore only the shared files.
Windows is out of scope.

| macOS only | Linux only |
| --- | --- |
| `finicky.js` — browser picker, macOS-only app | `toprc` — `top`'s Linux configuration format |
| `bin/n`, `bin/bkg` — notify via `terminal-notifier` | `screenrc-xpra` — starts an xpra X11 session |
| `bin/soffice-macos` — drives `/Applications/LibreOffice.app` | |
| `bash_aliases_os` — `csv`/`csv2`/`tsv`, `bit` completion | `bash_aliases_os` — `pxc`, `xo`, the `xclip` key bindings, `/usr/lib/ccache` |

The shared [`rcm/bash_aliases`](rcm/bash_aliases) sources `~/.bash_aliases_os`
if it exists, so each platform picks up its own aliases and nothing else.
`rcm/tag-macos/screenrc-xpra` is a placeholder:
`~/.screenrc` sources `.screenrc-xpra` unconditionally,
and screen complains about a missing file.

Everything that is portable stays shared,
including code that already adapts at runtime —
`bin/fsed` prefers `gsed` over `sed`,
`bin/rh` prefers `RStudio.app` over `rstudio`,
and `~/.bashrc` extends `PATH` only when `/opt/homebrew` exists.

An upgrade from a version without platform tags leaves the links that no longer apply behind,
dangling because their target moved into a tag directory.
`find ~ ~/bin -maxdepth 1 -xtype l` lists them, `-delete` removes them.

## Files

- [`rcm/rcrc`](rcm/rcrc): sets `DOTFILES_DIRS`, `UNDOTTED` and `TAGS`,
  and is installed as `~/.rcrc`.
  Every `make` target also points `RCRC` at this copy, so it takes effect
  even before — or instead of — an existing `~/.rcrc`.
- [`rcm/log/dummy`](rcm/log): placeholder that brings `~/log` into existence.
  Keep the name dotless — rcm skips names starting with a dot.
- [`Makefile`](Makefile): `make` links everything,
  `make force` replaces existing files,
  `make uninstall` runs `rcdn`,
  and `make check` lists the mapping without touching the filesystem.
- [`bootstrap`](bootstrap): one-shot setup.
  It requires `rcup` on `PATH`, **deletes any existing `~/git/scriptlets`**,
  clones the repo there and runs `make`.

`rcm/rcrc` hardcodes `DOTFILES_DIRS="$HOME/git/scriptlets/rcm"`,
so a bare `rcup` or `lsrc` finds nothing unless the clone lives at `~/git/scriptlets`
(where `bootstrap` puts it); `make` passes `-d` and works from any location.
`make uninstall` removes directories it leaves empty, walking up as far as `$HOME`
itself — harmless on a real home directory, which always has unrelated content,
but worth knowing in a container.
`make test` runs an install in a throwaway container, `make test-local` inside one.

## Prerequisites

Beyond [rcm](https://github.com/thoughtbot/rcm),
the scripts assume a GNU userland under Homebrew's `g` names:
`h` and `s` need `fd`, `gsed`, `gsort` and GNU `parallel`;
`fsed` needs `ag`, `gsed` and `gxargs`;
`pmake` needs `gmake`; `git-merge-into` needs `gsed`;
`n` and `bkg` need `terminal-notifier`; `rpt` needs `inotifywait` and `unbuffer`;
`git-mmv` needs `mmv`; `imgdiff` needs ImageMagick.

Nothing here puts `~/bin` on `PATH`.
On Ubuntu the distribution's own `~/.profile` happens to add it;
on macOS it does not, and zsh — the default login shell — reads none of the
bash files shipped here, so add `~/bin` to `PATH` yourself.

## Configuration files

Alongside the scripts in `rcm/bin/`, these land in the home directory:

| File | Installed as | |
| --- | --- | --- |
| [`bashrc`](rcm/bashrc), [`bash_profile`](rcm/bash_profile), [`bash_aliases`](rcm/bash_aliases) | `~/.bashrc`, `~/.bash_profile`, `~/.bash_aliases` | interactive bash: prompt, history, aliases |
| [`autoscreen`](rcm/autoscreen) | `~/.autoscreen` | drop into `screen` automatically on an interactive SSH login |
| [`gitconfig`](rcm/gitconfig), [`gitaliases`](rcm/gitaliases) | `~/.gitconfig`, `~/.gitaliases` | Git settings and aliases; pulls in several optional `~/.gitconfig.*` includes |
| [`gitignore`](rcm/gitignore) | `~/.gitignore` | global excludes, wired up via `core.excludesfile` |
| [`ssh/config`](rcm/ssh/config) | `~/.ssh/config` | keep-alives plus `Include`s for Colima, OrbStack and the per-user overrides |
| [`Rprofile`](rcm/Rprofile) | `~/.Rprofile` | R defaults: CRAN mirror selection, `usethis`/`testthat`/`pillar` options, per-project `.lib` and `Makevars` hooks |
| [`air.toml`](rcm/air.toml) | `~/air.toml` | fallback config for the `air` R formatter — formats nothing unless a project overrides it |
| [`editorconfig`](rcm/editorconfig) | `~/.editorconfig` | indentation defaults |
| [`vimrc`](rcm/vimrc), [`tigrc`](rcm/tigrc), [`toprc`](rcm/toprc) | `~/.vimrc`, `~/.tigrc`, `~/.toprc` | vim, tig and top |
| [`screenrc`](rcm/screenrc), [`screenrc-xpra`](rcm/screenrc-xpra) | `~/.screenrc`, `~/.screenrc-xpra` | GNU screen; the second starts an `xpra` server in a window |
| [`config/diffuse/diffuserc`](rcm/config/diffuse/diffuserc) | `~/.config/diffuse/diffuserc` | dark colour scheme for the Diffuse merge tool |
| [`finicky.js`](rcm/finicky.js) | `~/.finicky.js` | per-URL browser routing via Finicky (macOS) |
| [`git/R/`](rcm/git/R) | `~/git/R/` | CMake and build helpers for working on the R sources in CLion |

Several of these source files that this repository does *not* ship —
`~/.bash_secrets`, `~/git/bash-git-prompt`, `~/git/complete-alias` —
without guarding for their absence,
so a fresh shell reports errors until they exist or the lines are removed.

# Coming from the previous version

Everything lands where it always did, still as symbolic links,
so nothing in `$HOME` moves
and editing a file in the repository still takes effect immediately.
What changed is where the files sit *inside* the repository,
and what drives the installation.

The previous layout is preserved on the
[`home-grown`](https://github.com/krlmlr/scriptlets/tree/home-grown) branch.

| Before | Now |
| --- | --- |
| `home/dot-bashrc` | `rcm/bashrc` — rcm supplies the dot |
| `home/dot-ssh/config` | `rcm/ssh/config` |
| `home/bin/h` | `rcm/bin/h` — `bin` is in `UNDOTTED`, so the name is kept |
| `personalized/<USER>/gitconfig` | `rcm/tag-<USER>/scriptlets/gitconfig` |
| `make` | `make` — unchanged |
| `make build` (regenerate the installers) | — nothing to regenerate |
| `make run-force-install` | `make force` |
| — | `make uninstall`, `make check` |

The principal differences:

- **rcm is a new prerequisite** — `apt install rcm`, `brew install rcm`.
- **`make-install`, `install` and `install-personalized` are gone.**
  The two installers were generated files that had to be refreshed with `make build`
  after every change; rcm links straight out of `rcm/`, so there is nothing to regenerate.
- **Uninstalling is now possible.**
  `make uninstall` (`rcdn`) unlinks everything rcm currently owns,
  and `make force` replaces existing files; the old installer could only add.
  Neither prunes orphans, though: a file deleted from `rcm/` leaves a dangling
  symlink in `$HOME`, so run `make uninstall` *before* removing one.
- **Existing files are no longer skipped in silence.**
  The old installer left any pre-existing file alone and moved on;
  `rcup` asks what to do with one that differs.
  A first run on a machine that already has a `~/.gitconfig` will stop and prompt.
- **The tag is chosen with `id -un` rather than `$USER`,**
  so it also works where `$USER` is unset, such as launchd jobs
  and some non-interactive sessions.
- **`~/log/dummy` is now a symbolic link.**
  Previously `home/log/.dummy` was skipped and the directory created directly.

# Actively used tools

## Notifications

### n

Execute command in the foreground and show desktop notification after completion.
Notifies through `terminal-notifier`, so it is installed on macOS only.

### bkg

Execute command in the background and show desktop notification *in case of error*.
Installed on macOS only, for the same reason as `n`.

## h and s

Find every Git repository below the current directory and execute a command in each of them.
Linked worktrees are included, since they carry a `.git` file.
With `h`, the command is executed directly.
The `s` command prepends `git`, it is a wrapper around `h git` .
Supported switches:

- `-i` or `--interactive`: run the command in interactive mode, turn off parallel propcessing (with aliases `hi` and `si`)
- `-p` or `--paged`: show the output of the command in a pager (with aliases `hp` and `sp`)
- `-n` or `--dry-run`: show the command that would be executed, but do not execute it
- `-x` or `--log-commands`: also log the commands that are executed
- `-u` or `--unsorted`: skip the sort/dedup pass over the discovered repositories
- `--color=auto|always|never`, `--no-color`: control colored output. Default is `auto`: color is enabled when stdout is a TTY (or `--paged` is set), and disabled otherwise. The `NO_COLOR` environment variable (https://no-color.org/) also disables color unless `--color=always` is given.

`gita` both does too much and not enough, let's see how far I can get with home-grown scripts.

`g` is a simple forwarder to `git`.

FIXME: Integrate with `inside` and `every`

## rh

Start RStudio with an `.Rproj` project file found in the current directory.
If no project file is found, it is created using `usethis::use_rstudio()`.

## fsed

Run `gsed` over the whole tree below the current directory, `.git` excluded.
Files are discovered with `ag`.

## air-format

Run `air format` on a single file if the containing Git repository has an `air.toml` file.
Useful as a formatter in the RStudio IDE.

## git-mmv

Allows you to write `git mmv` to move several Git-controlled files at once, with the usual `mmv` syntax.

## git-merge-into

Merges the current branch into another branch without altering the current working copy.

## pmake

Parallel `make`, uses number of CPU cores as number of jobs.

## retry

Execute command until success, with increasing time intervals between failures.

## cgrep

Colorful `egrep` .

## pdfcat

Dump the text of a single PDF file to stdout, a thin wrapper around `pdftotext`.
The name is a misnomer: it concatenates nothing.

## git-bubble

How far can the most recent commit be pushed back up in the history without introducing merge conflicts?

FIXME: Add option to run code (check for semantic conflicts).

## git-bifurcate

Create a lightweight tag under `refs/tags/bif/<shortest-unique-prefix>` for every commit that has more than one child, so fork points show up in big-picture views (`git log --simplify-by-decoration --all`, `gitk --all`) without extra flags.
The short prefix is the minimum unique within the bifurcation set, so reruns rename tags (lengthen/shorten) as fork points are added or removed.
Commits already pointed at by an unrelated branch, tag, or remote ref are skipped to avoid duplicate decoration; annotated tags are dereferenced to their commit, so a `v1.0` release tag at a fork point is recognised.
`-r` / `--remove` deletes all tags in the namespace and leaves every other tag alone; `-q` / `--quiet` suppresses the summary line.

## soffice-macos

Launch LibreOffice/OpenOffice on macOS with proper environment setup.
Installed on macOS only, together with the `csv`, `csv2` and `tsv` aliases that use it.

## k

A simple forwarder to `kubectl`.

# To be reviewed

## Run commands in subdirectories

### inside

Execute command inside a subdirectory, given as first argument.

### every

Treat each line of the standard input as subdirectory to execute command in (via `inside`).

### each

Like `every`, but in parallel.

### everyfile

Execute command in each subdirectory (via `inside`).
FIXME: Currently assumes that the current directory only has subdirectories, not files.

### eachfile

Like `everyfile`, but in parallel.

## gh-mirror

Mirrors GitHub issues in a subdirectory of `.git` for offline use. A low-tech wrapper for `wget`.

## git-backup

Tracks the files that Git does *not* track in a shadow Git repository.

## git-backup-all

Treat a whole tree of Git repositories with `git-backup`.

## git-merge-update

Simplifies maintenance of "development" branches that contain several feature/bugfix branches.

## git-rsync

Allows repeated Git-less synchronization with remote locations via `rsync`.

## imgdiff and imgdiff-bg

Compare two images side by side and show differences in a middle pane. Requires ImageMagick. The `-bg` script exits immediately. Usage: `git difftool -x imgdiff-bg -y <image files>`. ([Source](http://www.akikoskinen.info/image-diffs-with-git))

## machine-load

Connects to remote machines and shows the top 5 processes by CPU consumption.

## ogv-to-gif

Convert a video to an animated GIF.
Currently broken: the script exits after the frame-export step, and the rest is unreachable.

## slecho

Echoes each of its parameters on a line of its own.

## rpt

Repeat a command (default: `make`) as soon as the contents of the current working directory change.

## reprex

Reproducible shell examples.

FIXME: This is likely better solved with `script` .

```sh
~ ( echo "echo a"; echo "echo b" ) | reprex
echo a
echo b
# a
# b
```

Step by step:

1. Type `reprex` on the shell.

2. Type `echo a` <enter> on the shell.

3. Output:

    ```sh
    echo a
    # a
    ```

4. Type `echo b` <enter> on the shell.

5. Output:

    ```sh
    echo b
    # b
    ```

6. Type <Ctrl + D> on the shell.

Not perfect, but a start.

## Azure utilities

### azure-resource-group-get-default

Get the default Azure resource group.

### azure-vm-deallocate

Deallocate an Azure VM, freeing up compute resources.

### azure-vm-set-size

Set the size (instance type) of an Azure VM.

### azure-vm-start

Start a stopped or deallocated Azure VM.

## git-config-parent

Configure Git to look for settings in parent directories.

## git-join-repos

Join multiple Git repositories into one while preserving history.

# Obsolete

In the [`obsolete`](obsolete) directory, catalogued in [`obsolete/README.md`](obsolete/README.md).



Copyright 2015-2025 Kirill Müller.
