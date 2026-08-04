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

## PATH

The scripts land in `~/bin`, which no system puts on the `PATH` on its own.

Ubuntu's stock `~/.profile` prepends `~/bin` and then `~/.local/bin`
if the directories exist,
so `~/.local/bin` ends up in front of `~/bin`.
macOS has no counterpart:
`/usr/libexec/path_helper`, run from `/etc/zprofile` and `/etc/profile`,
builds the `PATH` from `/etc/paths` and `/etc/paths.d`,
both system-wide,
and never looks below `$HOME`.
Neither `~/bin` nor `~/.local/bin` is special there.

[`rcm/profile`](rcm/profile) closes the gap:
it mirrors what Ubuntu does,
so `~/bin` works the same on both platforms
and [`rcm/bash_profile`](rcm/bash_profile) has the `~/.profile` it sources.
[`rcm/zprofile`](rcm/zprofile) does the same for zsh,
the default shell on macOS since Catalina,
which never reads `~/.profile` on its own.
rcm skips a file the account already has,
so a machine that came with its own `~/.profile` keeps it until `make force`.

`~/bin` stays the install target rather than `~/.local/bin`.
Moving would gain nothing on macOS, where neither directory is automatic,
and nothing on Ubuntu, where both already are.
It would cost a directory of our own:
`~/.local/bin` is shared with `pipx`, `uv` and `pip install --user`,
while `make uninstall` (`rcdn`) is best pointed at a directory only rcm writes to.

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

## Files

- [`rcm/rcrc`](rcm/rcrc): sets `DOTFILES_DIRS`, `UNDOTTED` and `TAGS`,
  and is installed as `~/.rcrc`.
  Every `make` target also points `RCRC` at this copy, so it takes effect
  even before — or instead of — an existing `~/.rcrc`.
- [`rcm/profile`](rcm/profile): installed as `~/.profile`,
  puts `~/bin` and `~/.local/bin` on the `PATH` and sources `~/.bashrc` under bash.
  Equivalent to Ubuntu's stock file, and the piece macOS lacks.
- [`rcm/zprofile`](rcm/zprofile): installed as `~/.zprofile`,
  hands `~/.profile` to zsh, which would not read it otherwise.
- [`rcm/log/dummy`](rcm/log): placeholder that brings `~/log` into existence.
  Keep the name dotless — rcm skips names starting with a dot.
- [`Makefile`](Makefile): `make` links everything,
  `make force` replaces existing files,
  `make uninstall` runs `rcdn`,
  `make check` lists the mapping without touching the filesystem,
  and `make test-local` runs the checks described below.
- [`bootstrap`](bootstrap): one-shot setup.
  It requires `rcup` on `PATH`, **deletes any existing `~/git/scriptlets`**,
  clones the repo there and runs `make`.

`rcm/rcrc` hardcodes `DOTFILES_DIRS="$HOME/git/scriptlets/rcm"`,
so a bare `rcup` or `lsrc` finds nothing unless the clone lives at `~/git/scriptlets`
(where `bootstrap` puts it); `make` passes `-d` and works from any location.
`make uninstall` removes directories it leaves empty, walking up as far as `$HOME`
itself — harmless on a real home directory, which always has unrelated content,
but worth knowing in a container.
`make test-local` never installs into your own home directory:
it creates one of its own, which is also why it is safe to run anywhere.

## Prerequisites

Beyond [rcm](https://github.com/thoughtbot/rcm),
the scripts assume a GNU userland under Homebrew's `g` names:
`h` and `s` need `fd`, `gsed`, `gsort` and GNU `parallel`;
`fsed` needs `ag`, `gsed` and `gxargs`;
`pmake` needs `gmake`; `git-merge-into` needs `gsed`;
`n` and `bkg` need `terminal-notifier`; `rpt` needs `inotifywait` and `unbuffer`;
`git-mmv` needs `mmv`; `imgdiff` needs ImageMagick.

Putting `~/bin` on the `PATH` is not among the things left to you:
[`rcm/profile`](rcm/profile) and [`rcm/zprofile`](rcm/zprofile) do it,
on macOS as well as on Ubuntu — see [PATH](#path).

## Configuration files

Alongside the scripts in `rcm/bin/`, these land in the home directory:

| File | Installed as | |
| --- | --- | --- |
| [`profile`](rcm/profile), [`zprofile`](rcm/zprofile) | `~/.profile`, `~/.zprofile` | login shells of any kind: `~/bin` and `~/.local/bin` on the `PATH` |
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

## Tests

`make test-local` installs everything into a throw-away home directory
and runs the checks in [`tests/checks`](tests/checks) against it.
The real home directory is never touched,
so the checks are safe to run on the machine you use.
`make test` does the same inside a container,
for a Linux run from a machine that is not Linux.

[`.github/workflows/test.yaml`](.github/workflows/test.yaml) runs them
on Ubuntu and on macOS.
Both matter:
on Ubuntu the scripts are found because the stock `~/.profile` finds them,
on macOS only because this repository ships the equivalent,
so a break in `rcm/profile` or `rcm/zprofile` shows up in the macOS job alone.

[`tests/run`](tests/run) creates the home directory
and seeds it the way a stock account is seeded:
on Ubuntu with `.bashrc`, `.profile` and `.bash_logout` from `/etc/skel`,
which is what `useradd -m` copies,
on macOS with nothing at all.
The three are taken by name rather than wholesale,
because `/etc/skel` is also where an image builder drops extras —
the CI runner's `/etc/skel` carries a `~/.bash_profile` no stock Ubuntu account has,
and seeding it would test the CI image instead of the platform.

Each file in `tests/checks` is a separate script
that sources [`tests/lib.sh`](tests/lib.sh) for `pass`, `fail` and the assertions,
and they run in name order:

- `10-path`: the scripts are on the `PATH` of a login shell, in every shell an
  account may log in with, and they run.
- `20-install`: every destination rcm lists exists, configuration files are
  symbolic links, and installing twice changes nothing.
- `30-preexisting`: an account that came with its own `~/.bash_profile` keeps it,
  and `make force` is what makes the scripts reachable there.
  It brings its own home directory.
- `90-force`: `make force` replaces the files rcm skipped,
  and the scripts are still found afterwards.
  It runs last because it is the one check that rewrites what the others read.

Adding a file to `tests/checks` is enough;
`tests/run 10-path` runs one check by name,
and `KEEP_TEST_HOME=1` leaves the home directory behind to look at.

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
Currently macOS only.

### bkg

Execute command in the background and show desktop notification *in case of error*.
Currently macOS only.

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
