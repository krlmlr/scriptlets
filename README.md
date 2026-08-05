# scriptlets

A collection of tiny but helpful shell scripts and configuration files for personal use.
Tested with current Ubuntu and macOS.
Licensed under [GPL v3](http://www.gnu.org/copyleft/gpl.html).

To install all scripts to `~/bin` (by creating symbolic links),
install [rcm](https://github.com/thoughtbot/rcm),
clone the project and run `make` — or `mise run install`,
if you have [mise](https://mise.jdx.dev).
rcm is the only thing this needs; mise is optional.
Or run the [`bootstrap`](bootstrap) script:

```sh
curl -s https://raw.githubusercontent.com/krlmlr/scriptlets/main/bootstrap | sh
```

# Build and install

Installation is handled by [rcm](https://github.com/thoughtbot/rcm),
which creates the symbolic links.
Adding a file under `rcm/` and rerunning `mise run` is enough,
and [`mise run import`](#importing-a-file-you-already-have) moves an existing one in for you.

## Tasks

Each task is a script in [`mise-tasks/`](mise-tasks) — one file, one task —
reachable through [mise](https://mise.jdx.dev) or through `make`:

| Task | `make` | |
| --- | --- | --- |
| `mise run install` | `make` | link every file into the home directory |
| `mise run force` | `make force` | link every file, replacing ones that already exist |
| `mise run check` | `make check` | list the mapping without touching the filesystem |
| `mise run uninstall` | `make uninstall` | remove every symbolic link rcm owns |
| `mise run import <file>` | — | move a file in from the home directory |
| `mise run test` | — | run the checks against a throw-away home directory |
| `mise run test-container` | — | the same on Linux, from a machine that is not |

**mise is optional.**
Installing needs nothing but rcm and `make`:
`make install` runs [`mise-tasks/install`](mise-tasks/install),
the very file `mise run install` runs,
so there is one implementation of each task and two ways to reach it —
nothing that can drift.

Three tasks are mise-only, and `make` names them and stops rather than pretend:
`import` needs mise to parse its arguments,
and the two test targets run tasks themselves.
[`tests/checks/50-makefile.sh`](tests/checks/50-makefile.sh) checks what
construction cannot: that no task was added without a target to reach it by.

What mise adds, if you have it:
`mise tasks` lists the tasks with their descriptions,
`mise run` with no task at all opens a picker on a terminal —
no task is aliased to `default`, so a bare `mise run` asks rather than installs,
and [`tests/checks/15-tasks.sh`](tests/checks/15-tasks.sh) keeps it that way,
`mise run import` is the one task `make` cannot offer,
and the completion described [below](#picking-the-file).
Its one obligation is trust —
`mise trust` once per clone, or `mise run` refuses to read `mise.toml`.
[`bootstrap`](bootstrap) does that for you;
so does [`tests/run`](tests/run), for the throw-away home directory it installs into.

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
so a machine that came with its own `~/.profile` keeps it until `mise run force`.

`~/bin` stays the install target rather than `~/.local/bin`.
Moving would gain nothing on macOS, where neither directory is automatic,
and nothing on Ubuntu, where both already are.
It would cost a directory of our own:
`~/.local/bin` is shared with `pipx`, `uv` and `pip install --user`,
while `mise run uninstall` (`rcdn`) is best pointed at a directory only rcm writes to.

## Per-user overrides

A `tag-<NAME>/` directory holds files for one account:
[`rcm/tag-kirill/scriptlets/gitconfig`](rcm/tag-kirill/scriptlets/gitconfig)
installs to `~/scriptlets/gitconfig`.

[`rcm/rcrc`](rcm/rcrc) is sourced as shell, so it selects the tag itself:

```sh
TAGS="$(id -un) $OS_TAG"
```

An account with no matching `tag-` directory installs nothing extra.
`$OS_TAG` is the platform tag described in the next section.
Tags are not limited to user names:
`rcup -t work` selects a `tag-work/` directory *instead of* both of these,
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

## Importing a file you already have

```sh
mise run import ~/.foorc          # -> rcm/foorc, linked back as ~/.foorc
mise run import ~/bin/foo         # -> rcm/bin/foo, linked back as ~/bin/foo
mise run import -t "$(id -un)" ~/.foorc   # -> rcm/tag-<you>/foorc
```

The file moves into the repository and is linked back where it was;
`git add` is left to you, and the task prints the command.

rcm ships [`mkrc`](https://github.com/thoughtbot/rcm) for this,
and [`mise-tasks/import`](mise-tasks/import) exists because `mkrc` gets the
`UNDOTTED` names wrong:
`mkrc ~/bin/foo` moves the file to `rcm/bin/foo` correctly
but links it back as `~/.bin/foo`,
because rcup applies `UNDOTTED` when it walks the whole tree
and not when it is handed a single file.
The task picks the name the way the tree walk will, then lets rcup link.

It refuses a file that is already a symbolic link (imported once already),
one outside `$HOME`,
and one whose name has no leading dot and is not in `UNDOTTED` —
`~/notes.txt` would come back as `~/.notes.txt`,
so the name has to go into `UNDOTTED` in [`rcm/rcrc`](rcm/rcrc) first.

### Picking the file

mise has no file browser, and there is nothing to browse with.
What it does have:

- `mise run` with no task, on a terminal, opens a fuzzy picker over the task
  list — task names only, not their arguments.
- Argument completion, which is where the file comes in.
  `import` declares its completion in the `#USAGE` header,
  and offers the dotfiles in `$HOME` that are still regular files —
  a file already imported is a symbolic link, so it drops off the list by itself.

Completion needs two things:
the [`usage`](https://usage.jdx.dev) CLI, which is what generates it
(`mise use -g usage`),
and mise's completions loaded in your shell.
Without `usage` on the `PATH`, mise's completion script says so instead of completing.

For zsh, [`rcm/zshrc`](rcm/zshrc) does the loading, and does it lazily:
`mise completion zsh` shells out to `usage`,
which is a process or two at every shell start,
so a stub stands in until the first Tab on a `mise` command line
and hands over to the real completion from then on.
bash and fish are on their own — `mise completion bash` or `fish`.

## Files

- [`rcm/rcrc`](rcm/rcrc): sets `DOTFILES_DIRS`, `UNDOTTED` and `TAGS`,
  and is installed as `~/.rcrc`.
  Every task also points `RCRC` at this copy, so it takes effect
  even before — or instead of — an existing `~/.rcrc`.
- [`rcm/profile`](rcm/profile): installed as `~/.profile`,
  puts `~/bin` and `~/.local/bin` on the `PATH` and sources `~/.bashrc` under bash.
  Equivalent to Ubuntu's stock file, and the piece macOS lacks.
- [`rcm/zprofile`](rcm/zprofile): installed as `~/.zprofile`,
  hands `~/.profile` to zsh, which would not read it otherwise.
- [`rcm/zshrc`](rcm/zshrc): installed as `~/.zshrc`,
  starts the completion system and registers mise's completion lazily.
- [`rcm/zshenv`](rcm/zshenv): installed as `~/.zshenv`, read by every zsh
  before anything else.
  It loads the [startup profiler](#zsh-startup-profiling), and defines a no-op
  `zsh_startup_mark` where the profiler declines to,
  which is what keeps the marks in the other two files quiet
  when profiling is switched off — or when this file arrived without it.
- [`rcm/zsh-startup-profile.zsh`](rcm/zsh-startup-profile.zsh): installed as
  `~/.zsh-startup-profile.zsh` and sourced from the first line of `~/.zshenv`,
  which is what lets it time the whole rc chain.
  Described [below](#zsh-startup-profiling).
- [`rcm/log/dummy`](rcm/log): placeholder that brings `~/log` into existence.
  Keep the name dotless — rcm skips names starting with a dot.
- [`mise-tasks/`](mise-tasks): one script per task.
  [`lib.sh`](mise-tasks/lib.sh) holds the `REPO`, `RCRC` and `DOTFILES` they
  share, and is deliberately not executable: mise takes every executable here
  for a task.
- [`mise.toml`](mise.toml): what marks the directory as a mise project, and
  what `mise trust` trusts. The tasks are files, so it holds nothing else.
- [`Makefile`](Makefile): runs those same scripts for a machine without mise,
  and points at mise for the three that need it.
- [`mise-tasks/import`](mise-tasks/import): the one task too long for a
  one-liner, described [below](#importing-a-file-you-already-have).
- [`bootstrap`](bootstrap): one-shot setup.
  It requires `rcup`, and either `mise` or `make`,
  **deletes any existing `~/git/scriptlets`**,
  clones the repo there and installs —
  trusting the clone and running `mise run install` where there is mise,
  `make install` where there is not.

`rcm/rcrc` hardcodes `DOTFILES_DIRS="$HOME/git/scriptlets/rcm"`,
so a bare `rcup` or `lsrc` finds nothing unless the clone lives at `~/git/scriptlets`
(where `bootstrap` puts it); the tasks pass `-d` and work from any location.
`mise run uninstall` removes directories it leaves empty, walking up as far as `$HOME`
itself — harmless on a real home directory, which always has unrelated content,
but worth knowing in a container.
`mise run test` never installs into your own home directory:
it creates one of its own, which is also why it is safe to run anywhere.

## Prerequisites

[rcm](https://github.com/thoughtbot/rcm) is the one hard prerequisite.
[mise](https://mise.jdx.dev) (`curl https://mise.run | sh`, or Homebrew) is
optional — `make` installs without it, and only `import` and the tests need it.

The scripts themselves assume a GNU userland under Homebrew's `g` names:
`h` and `s` need `fd`, `gsed`, `gsort` and GNU `parallel`;
`fsed` needs `ag`, `gsed` and `gxargs`;
`pmake` needs `gmake`; `git-merge-into` needs `gsed`;
`n` and `bkg` need `terminal-notifier`, and are installed on macOS only;
`rpt` needs `inotifywait` and `unbuffer`;
`git-mmv` needs `mmv`; `imgdiff` needs ImageMagick.
`zsh-startup-bench` needs `hyperfine` for its benchmark mode alone
(`brew install hyperfine`, `apt install hyperfine`);
reading the log and the `zprof` breakdown needs nothing but zsh.

Putting `~/bin` on the `PATH` is not among the things left to you:
[`rcm/profile`](rcm/profile) and [`rcm/zprofile`](rcm/zprofile) do it,
on macOS as well as on Ubuntu — see [PATH](#path).

## Configuration files

Alongside the scripts in `rcm/bin/` and `rcm/tag-macos/bin/`,
these land in the home directory:

| File | Installed as | |
| --- | --- | --- |
| [`profile`](rcm/profile), [`zprofile`](rcm/zprofile) | `~/.profile`, `~/.zprofile` | login shells of any kind: `~/bin` and `~/.local/bin` on the `PATH` |
| [`bashrc`](rcm/bashrc), [`bash_profile`](rcm/bash_profile), [`bash_aliases`](rcm/bash_aliases) | `~/.bashrc`, `~/.bash_profile`, `~/.bash_aliases` | interactive bash: prompt, history, aliases |
| [`tag-macos/bash_aliases_os`](rcm/tag-macos/bash_aliases_os), [`tag-linux/bash_aliases_os`](rcm/tag-linux/bash_aliases_os) | `~/.bash_aliases_os` | the aliases, completions and bindings of one platform, sourced from `~/.bash_aliases` |
| [`zshenv`](rcm/zshenv), [`zshrc`](rcm/zshrc) | `~/.zshenv`, `~/.zshrc` | zsh: the profiler for every shell, completion and history for the interactive ones |
| [`zsh-startup-profile.zsh`](rcm/zsh-startup-profile.zsh) | `~/.zsh-startup-profile.zsh` | times every interactive zsh startup — [below](#zsh-startup-profiling) |
| [`autoscreen`](rcm/autoscreen) | `~/.autoscreen` | drop into `screen` automatically on an interactive SSH login |
| [`gitconfig`](rcm/gitconfig), [`gitaliases`](rcm/gitaliases) | `~/.gitconfig`, `~/.gitaliases` | Git settings and aliases; pulls in several optional `~/.gitconfig.*` includes |
| [`gitignore`](rcm/gitignore) | `~/.gitignore` | global excludes, wired up via `core.excludesfile` |
| [`ssh/config`](rcm/ssh/config) | `~/.ssh/config` | keep-alives plus `Include`s for Colima, OrbStack and the per-user overrides |
| [`Rprofile`](rcm/Rprofile) | `~/.Rprofile` | R defaults: CRAN mirror selection, `usethis`/`testthat`/`pillar` options, per-project `.lib` and `Makevars` hooks |
| [`air.toml`](rcm/air.toml) | `~/air.toml` | fallback config for the `air` R formatter — formats nothing unless a project overrides it |
| [`editorconfig`](rcm/editorconfig) | `~/.editorconfig` | indentation defaults |
| [`vimrc`](rcm/vimrc), [`tigrc`](rcm/tigrc) | `~/.vimrc`, `~/.tigrc` | vim and tig |
| [`tag-linux/toprc`](rcm/tag-linux/toprc) | `~/.toprc` | top; the format is the Linux one, so it installs there only |
| [`screenrc`](rcm/screenrc), [`tag-linux/screenrc-xpra`](rcm/tag-linux/screenrc-xpra) | `~/.screenrc`, `~/.screenrc-xpra` | GNU screen; the second starts an `xpra` server in a window on Linux, and is a placeholder on macOS |
| [`config/diffuse/diffuserc`](rcm/config/diffuse/diffuserc) | `~/.config/diffuse/diffuserc` | dark colour scheme for the Diffuse merge tool |
| [`tag-macos/finicky.js`](rcm/tag-macos/finicky.js) | `~/.finicky.js` | per-URL browser routing via Finicky; macOS only |
| [`git/R/`](rcm/git/R) | `~/git/R/` | CMake and build helpers for working on the R sources in CLion |

Several of these source files that this repository does *not* ship —
`~/git/bash-git-prompt`, `~/git/complete-alias` —
without guarding for their absence,
so a fresh shell reports errors until they exist or the lines are removed.
`~/.bash_secrets` used to be among them,
and is now sourced only if it is there:
it is the one of the three that a machine may legitimately never need,
and the error was reaching zsh as well,
which reads `~/.bash_aliases` through `~/.zshrc`.

## zsh startup profiling

Every interactive zsh times its own startup,
appends one line to `~/.local/state/zsh-startup.log`,
and says what it cost before the first prompt:

```
zsh startup 61 ms
     0.4 ms  zshenv           (+0.4)
     6.1 ms  zprofile         (+5.7)
     8.2 ms  zshrc            (+2.1)
    61.0 ms  first prompt     (+52.8)
```

Startup time is a number that only ever grows,
one `eval "$(… init -)"` at a time,
and it grows below the threshold anyone would notice on a single day.
Measuring it continuously, from real shells,
is the cheapest way to catch the line that cost 200 ms
on the day it was added rather than a year later.

[`rcm/zsh-startup-profile.zsh`](rcm/zsh-startup-profile.zsh) is the whole
mechanism, and [`rcm/zshenv`](rcm/zshenv) sources it on its first line —
`~/.zshenv` is the first file every zsh reads,
so nothing that runs later could see the time the earlier files took.
The last line of each of the three startup files calls `zsh_startup_mark`,
which appends to an array;
one `precmd` hook then prints the timeline before the first prompt
and unhooks itself.
There are no forks in any of it,
and a non-interactive shell — every script, every `zsh -c` —
returns after two builtin statements.

Each line is what that file had cost by the time it was *done*,
and the `(+…)` is that file's own share.
The last gap is the one no benchmark can see:
`first prompt` minus `zshrc` is everything the terminal itself does
after the configuration has finished —
shell integration, session restore, the terminal's own rc hooks.

`zsh -i -c 'exit 0'` never reaches a prompt,
so benchmark runs are absent from the log by construction.

### Turning it off

The knobs are environment variables,
and the place to set them on one machine is `~/scriptlets/zsh-startup`,
which the profiler sources before it does anything else.
That file is not shipped here —
it is yours, per machine, like `~/.bash_secrets` —
and it joins the `~/scriptlets/` files
that [per-user overrides](#per-user-overrides) already describes.
Anything exported before zsh starts works too,
which is what makes `ZSH_STARTUP_PROFILE=0 zsh` a one-shot escape.

| Set | Effect |
| --- | --- |
| `ZSH_STARTUP_BUDGET_MS=500` | say nothing unless a startup exceeds the budget; keep recording |
| `ZSH_STARTUP_BUDGET_MS=` | say nothing, ever; keep recording |
| `ZSH_STARTUP_MARKS=` | keep the one-line notice, drop the timeline below it |
| `ZSH_STARTUP_LOG=` | stop recording; keep the notice |
| `ZSH_STARTUP_PROFILE=0` | off entirely: nothing is loaded, nothing is timed, nothing is written |

So the usual progression is
`ZSH_STARTUP_BUDGET_MS=500` once the number is boring —
the log keeps filling, and only a regression speaks up —
and `ZSH_STARTUP_PROFILE=0` when even that is unwelcome.
The timeline is only ever printed under the notice it breaks down,
so silencing the notice silences both.

Off is off at the source: with `ZSH_STARTUP_PROFILE=0`
the profiler returns before it loads a module or defines a function,
and the no-op `zsh_startup_mark` in `~/.zshenv` absorbs the three marks
left behind in the startup files.
Removing the profiler for good is a matter of deleting
`rcm/zsh-startup-profile.zsh` and the `# >>> zsh startup profiling >>>` blocks —
run `mise run uninstall` *before* deleting the file,
or the symbolic link in `$HOME` is left dangling.

The log is append-only and never rotated —
one short line per shell, four tab-separated fields.
Trim it when it gets long:

```sh
tail -n 5000 ~/.local/state/zsh-startup.log > ~/.local/state/zsh-startup.log.tmp &&
  mv ~/.local/state/zsh-startup.log.tmp ~/.local/state/zsh-startup.log
```

### Reading the numbers

[`zsh-startup-bench`](rcm/bin/zsh-startup-bench) is the other half,
and it answers three different questions —
see [below](#zsh-startup-bench).

## Tests

`mise run test` installs everything into a throw-away home directory
and runs the checks in [`tests/checks`](tests/checks) against it.
The real home directory is never touched,
so the checks are safe to run on the machine you use.
`mise run test-container` does the same inside a container,
for a Linux run from a machine that is not Linux.

[`.github/workflows/test.yaml`](.github/workflows/test.yaml) runs them
on Ubuntu and on macOS.
Both matter:
on Ubuntu the scripts are found because the stock `~/.profile` finds them,
on macOS only because this repository ships the equivalent,
so a break in `rcm/profile` or `rcm/zprofile` shows up in the macOS job alone.

[`tests/run`](tests/run) needs `rcup` and `mise` on the `PATH` —
this is the one place mise is not optional, because the checks run tasks.
It creates the home directory
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
- `15-tasks`: a bare `mise run` offers the task list instead of running one.
- `20-install`: every destination rcm lists exists, configuration files are
  symbolic links, and installing twice changes nothing.
- `30-preexisting`: an account that came with its own `~/.bash_profile` keeps it,
  and `make force` is what makes the scripts reachable there.
  It brings its own home directory.
- `40-import`: `mise run import` puts a dotfile and an `UNDOTTED` name where
  they belong, refuses what it should, and leaves the real repository alone.
  It works on a copy, because importing *moves* files into the repository.
- `50-makefile`: the `Makefile` fallback agrees with the tasks it stands in
  for, and the targets it does not implement say so instead of pretending.
- `60-zsh-startup`: a zsh startup complains about nothing, and `~/.zshrc` binds
  `mise` to the stub — the generated completion is *not* loaded at startup, and
  the first completion loads it and rebinds to it.
- `65-zsh-startup-profile`: a shell that reaches a prompt is timed, recorded
  once and broken down by startup file; one that does not — a script, a
  `zsh -c`, a benchmark run — is left alone; and every documented way of
  [turning the profiling off](#turning-it-off) turns it off.
- `70-git-ssh-remote`: `git ssh-remote` converts the HTTPS GitHub remotes of a
  throw-away repository and leaves every other remote alone,
  through `~/bin` and through the `git sr` alias alike.
- `90-force`: `mise run force` replaces the files rcm skipped,
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
| `home/dot-finicky.js`, `home/dot-toprc` | `rcm/tag-macos/finicky.js`, `rcm/tag-linux/toprc` |
| `make` | `make` — unchanged, or `mise run install`, which runs the same script |
| `make build` (regenerate the installers) | — nothing to regenerate |
| `make run-force-install` | `mise run force` |
| — | `mise run uninstall`, `mise run check`, `mise run import` |

The principal differences:

- **rcm is a new prerequisite** — `apt install rcm`, `brew install rcm`.
  The targets are [tasks](#tasks) now, and `make` still reaches them;
  mise is optional, and adds `import`, the tests and completion.
- **`make-install`, `install` and `install-personalized` are gone.**
  The two installers were generated files that had to be refreshed with `make build`
  after every change; rcm links straight out of `rcm/`, so there is nothing to regenerate.
- **Uninstalling is now possible.**
  `mise run uninstall` (`rcdn`) unlinks everything rcm currently owns,
  and `mise run force` replaces existing files; the old installer could only add.
  Neither prunes orphans, though: a file deleted from `rcm/` leaves a dangling
  symlink in `$HOME`, so run `mise run uninstall` *before* removing one.
- **Existing files are no longer skipped in silence.**
  The old installer left any pre-existing file alone and moved on;
  `rcup` asks what to do with one that differs.
  A first run on a machine that already has a `~/.gitconfig` will stop and prompt.
- **The tag is chosen with `id -un` rather than `$USER`,**
  so it also works where `$USER` is unset, such as launchd jobs
  and some non-interactive sessions.
- **Single-platform files are no longer installed everywhere.**
  The old installers linked `home/dot-finicky.js` and `home/dot-toprc` on every machine;
  a second tag now keeps each to the system it works on.
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

## zsh-startup-bench

Three views of one question — what does starting a shell cost? —
on top of the [startup profiling](#zsh-startup-profiling)
that every interactive zsh does anyway.

```sh
zsh-startup-bench           # hyperfine: this configuration against the bare floor
zsh-startup-bench --zprof   # per-function breakdown of a single startup
zsh-startup-bench --log     # summarise the continuous log
```

`--log` is the number to trust:
it comes from real shells on this machine —
count, min, median, p90, max and mean,
broken down by terminal and by login versus interactive.
It is the only view that reflects a cold cache, a busy laptop,
or a terminal that starts a login shell where you expected an interactive one.

The benchmark compares three shells:
a login shell (what a new tab starts),
a plain interactive one (a `zsh` inside an existing tab),
and `zsh -f`, the same binary with no rc files at all.
The floor is what makes the rest legible —
40 ms of zsh plus 600 ms of our own configuration
is a different verdict from 640 ms of zsh.
The gap between the first two is a finding in itself:
only login shells read `/etc/zprofile` and `~/.zprofile`,
which on macOS fork `path_helper` and `brew shellenv`.
This mode is the one that needs `hyperfine`.

`--zprof` ranks the functions of a single startup.
Read the ranking, not the total:
loading `zprof` instruments every function call and inflates what it measures,
and it sees function calls *only* —
a top-level `eval`, a bare `source` or a fork never appears in the table.

`--runs` and `--top` set the benchmark's run count and the length of the
`zprof` table; `-h` prints the commentary above in full.

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

## git-ssh-remote

Rewrite the HTTPS URLs of a repository's GitHub remotes as their SSH equivalents,
turning `https://github.com/krlmlr/scriptlets.git` into `git@github.com:krlmlr/scriptlets.git`.
This is the repair for a clone made with the URL GitHub offers first,
which asks for a password on every push.
The `git sr` alias is the short spelling.

Named remotes are converted, all of them when none is named,
and fetch and push URLs alike — including every URL of a remote that has more than one.
Remotes that already speak SSH, and HTTPS remotes on other hosts, are left as they are.
Credentials in the URL (`https://token@github.com/...`) are dropped,
and so is a port, which says nothing about where SSH listens;
a missing `.git` suffix is added.

`-n` / `--dry-run` prints what would change and changes nothing;
`-a` / `--all-hosts` converts HTTPS remotes on any host, not GitHub alone,
which is what a GitHub Enterprise installation or a GitLab remote needs.
`-h` shows the help — spelled `--help`, git looks for a man page instead.

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
