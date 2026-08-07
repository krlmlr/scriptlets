# Testing

`mise run test` installs everything into a throw-away home directory
and runs the checks in [`tests/checks`](/tests/checks) against it.
The real home directory is never touched,
so the checks are safe to run on the machine you use.
`mise run test-container` does the same inside a container,
for a Linux run from a machine that is not Linux.

[`tests/run`](/tests/run) needs `rcup` and `mise` on the `PATH` —
this is the one place mise is not optional,
because the checks run tasks
([`install/tasks/`](/handbook/install/tasks/README.md)).
It creates the home directory
and seeds it the way a stock account is seeded:
on Ubuntu with `.bashrc`, `.profile` and `.bash_logout`
from `/etc/skel`, which is what `useradd -m` copies,
on macOS with nothing at all.
The three are taken by name rather than wholesale,
because `/etc/skel` is also where an image builder drops extras —
the CI runner's `/etc/skel` carries a `~/.bash_profile`
no stock Ubuntu account has,
and seeding it would test the CI image instead of the platform.

`$XDG_CACHE_HOME` is pointed at that home directory too.
`$HOME` alone is not enough:
what a shell caches goes to `$XDG_CACHE_HOME` wherever that is set,
so on a machine that sets it
the checks would delete and rewrite the real user's cache
while believing they were working in a directory of their own.
The other XDG directories are deliberately left alone,
because mise reads its own configuration and state from them
and these checks run mise.

**In CI**,
[`.github/workflows/test.yaml`](/.github/workflows/test.yaml)
runs the suite on Ubuntu and on macOS.
Both matter:
on Ubuntu the scripts are found
because the stock `~/.profile` finds them,
on macOS only because this repository ships the equivalent,
so a break in the shipped profiles
([`layout/path/`](/handbook/layout/path/README.md))
shows up in the macOS job alone.

## The checks

Each file in `tests/checks` is a separate script
that sources [`tests/lib.sh`](/tests/lib.sh)
for `pass`, `fail` and the assertions,
and they run in name order:

- `05-handbook`: the handbook holds its shape —
  every directory has a `README.md`,
  every subdirectory is in its parent's list,
  every link resolves, and none reaches upward
  ([`meta/handbook/`](/handbook/meta/handbook/README.md)
  has the rules it enforces).
  It reads the repository, not the home directory,
  so it is first, before the installed checks.
- `06-timing`: the clock behind the durations answers in milliseconds —
  measured against a sleep rather than assumed,
  because a fallback that answered in seconds
  would fill the block with zeroes that read like measurements —
  and the block lines up the durations it is given.
  It calls the helpers directly,
  reading neither the repository nor the home directory,
  so it runs before the installed checks too.
- `07-git-aliases`: the trie in
  [`config/git-aliases/`](/handbook/config/git-aliases/README.md)
  is what the aliases render to,
  rather than a snapshot of what they once rendered to.
  It reads the repository alone, as the two before it do,
  and an alias added or renamed fails it until the page is regenerated.
- `10-path`: the scripts are on the `PATH` of a login shell,
  in every shell an account may log in with, and they run.
- `15-tasks`: a bare `mise run` offers the task list
  instead of running one.
- `20-install`: every destination rcm lists exists,
  configuration files are symbolic links,
  and installing twice changes nothing.
- `25-private`: a private sidecar repository
  ([`layout/private/`](/handbook/layout/private/README.md))
  is merged into the same home directory:
  its own files install, its `rcrc` fragment extends `UNDOTTED`
  instead of replacing it,
  it wins a name both trees have,
  its hooks run while the directory holding them is not installed,
  uninstalling reaches its links too,
  and an `rcrc` under its `rcm/` — which would install over `~/.rcrc` —
  is refused.
  It brings its own home directory and its own sidecar,
  because the machine running it may have a real one.
  It also reads the tasks rather than running them,
  for the one thing running them cannot show:
  that none of them reaches rcm on its own
  and so decides for itself which trees to act on
  ([`install/tasks/`](/handbook/install/tasks/README.md)).
- `27-bootstrap-private`: `bootstrap-private` creates a sidecar
  and converges on a re-run:
  a dry run changes nothing and names every file it would write,
  the first run leaves two commits on `main` —
  an empty `Initial commit` and the skeleton on top of it —
  with the fragment at the repository root and the hook executable,
  and a settled run creates nothing,
  invents no commit,
  and leaves a file edited by hand exactly as it was.
  GitHub is a stub answering the few `gh` calls the script makes,
  so a step that reaches for `gh` in a new way fails here
  rather than silently going untested.
- `30-preexisting`: an account that came with its own
  `~/.bash_profile` keeps it,
  and `make force` is what makes the scripts reachable there.
  It brings its own home directory.
- `40-import`: `mise run import` puts a dotfile and an `UNDOTTED` name
  where they belong, refuses what it should,
  and leaves the real repository alone.
  It works on a copy,
  because importing *moves* files into the repository.
- `50-makefile`: the `Makefile` fallback agrees with the tasks
  it stands in for,
  and the targets it does not implement say so instead of pretending.
- `55-editor`: `$EDITOR` and `$VISUAL` name a Zed told to wait
  in a login shell of each of the three kinds,
  git edits with the same value,
  `^X^E` is bound in an interactive zsh,
  and a `PATH` without Zed on it falls back to vim
  ([`config/editor/`](/handbook/config/editor/README.md)).
  The `--wait` is the half worth pinning:
  an editor that returns before the file is written
  discards the commit message and the command line without a word.
  It brings its own home directory and installs into it,
  because `~/.profile` carries the value
  and the throw-away home has the one `/etc/skel` seeded;
  and it stubs `zed`, which is on neither CI runner.
- `60-zsh-startup`: a zsh startup complains about nothing,
  and `~/.zshrc` binds `mise` to the stub —
  the generated completion is *not* loaded at startup,
  and the first completion loads it and rebinds to it.
  It also covers the completion dump:
  written and compiled by the first shell, trusted by the next,
  re-audited once the stamp is a day old,
  and rebuilt on demand by `zsh-compinit-refresh`
  ([`config/completion/`](/handbook/config/completion/README.md)).
  The audit is observed through a sentinel written into the stamp,
  which the audit truncates —
  mtimes cannot tell a re-audit within the same second
  from no audit at all.
- `62-zsh-prompt-marks`: the prompt marks
  ([`config/prompt-marks/`](/handbook/config/prompt-marks/README.md))
  are the bytes they should be, in the order they should be in;
  the command-end mark carries the status of the command line
  and is not sent for a prompt no command preceded;
  and the prompt marks are in `$PS1` rather than in a hook,
  where they would be erased again before anyone saw them.
  An interactive zsh reading a pipe runs the hooks and prints no prompt,
  which is what lets the chain be checked without a terminal.
  Reading `~/.zshrc` twice does not mark the prompt twice,
  a prompt with escapes switched off is left alone,
  and a shell with Ghostty's integration loaded leaves the marking to it
  while a shell started inside that one marks for itself.
- `65-zsh-startup-profile`: a shell that reaches a prompt is timed,
  recorded once and broken down by startup file;
  one that does not — a script, a `zsh -c`, a benchmark run —
  is left alone;
  and every documented way of turning the profiling off
  ([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md))
  turns it off.
- `67-zsh-atuin`: the generated atuin init script
  ([`config/atuin/`](/handbook/config/atuin/README.md))
  is written to a file and sourced from there
  rather than produced at every shell,
  rewritten when the binary or the configuration file is newer than it,
  never replaced by an empty or half-written one,
  and absent without complaint where atuin is not installed.
  A stand-in `atuin` on the `PATH` counts its own runs
  and fails the ways the real one fails,
  so the checks neither need the real atuin nor want it —
  the one case that does need the machine's own answer,
  no atuin at all, is skipped where there is one.
- `70-git-ssh-remote`: `git ssh-remote` converts the HTTPS GitHub
  remotes of a throw-away repository
  and leaves every other remote alone,
  through the `~/bin` the installation puts on the `PATH`.
- `71-git-pr`: what `git pr` would run, read off its `--dry-run`:
  the title is the first commit's subject rather than the last,
  the issue closed is the one the branch name numbers,
  and the trailing field of that name stays a suffix.
- `72-gh-repo-setup`: the owner and name `gh-repo-setup` recovers from
  every spelling a remote comes in,
  which remote it asks first,
  and the three options it sets.
  Neither check reaches GitHub, and neither needs `gh` installed:
  `--dry-run` puts the commands on stdout instead of running them.
- `73-git-ff`: `git ff` moves a branch nothing has checked out
  and one a linked worktree holds — the second is the case
  `git push .` cannot reach, and the reason the script exists —
  while a worktree with uncommitted changes and a diverged branch
  are left as they were.
  Its remote is a second repository below the throw-away home
  and the clone is made from that path,
  so the fetches and the push stay on this disk.
- `75-h`: `h` runs the command in every repository below the current
  directory, and each line of output says which one it came from.
  Both halves matter:
  a run that ends on the first repository prints nothing at all,
  which is also what an empty directory looks like,
  so the check names the repositories it expects to hear back from.
  The repository it is *standing in* is not among them,
  which is the other half of "below";
  `-n` emits the commands instead of running them;
  and `s` reaches the same repositories with `git` in front.
  It links the `fd`, `gsed` and `gsort` names Linux does not ship
  ([`install/prerequisites/`](/handbook/install/prerequisites/README.md))
  and skips where the commands behind them are missing too.
- `78-positron`: the hooks that keep `~/bin/positron` pointing at
  Positron's command line tool
  ([`install/hooks/`](/handbook/install/hooks/README.md))
  link it, leave it alone once it is right,
  keep a file of the account's own that is in the way,
  drop a link into a bundle that is gone,
  and take the link away again on the way out.
  It also drives one install and uninstall through the tasks,
  for the half running the hooks by hand cannot show:
  that rcm reaches them at all, from a clone anywhere.
  It builds a bundle of its own and stubs `uname`,
  because Positron is macOS-only and on neither CI runner,
  and brings its own home directory,
  the throw-away one being what the other checks read.
- `90-force`: `mise run force` replaces the files rcm skipped,
  and the scripts are still found afterwards.
  It runs last because it is the one check
  that rewrites what the others read.

Adding a file to `tests/checks` is enough;
`tests/run 10-path` runs one check by name,
and `KEEP_TEST_HOME=1` leaves the home directory behind to look at.

## Durations

A run ends with a block of durations —
the install it opens with, every check it ran, and the run as a whole —
printed before the verdict,
so a failing run says where its time went as well as a passing one.
The whole run is wall clock rather than the sum of the parts,
because it also covers making the throw-away home directory
and seeding it.

The block is what makes the numbers attributable in CI:
a job times its own steps,
and the entire suite is one step of one job,
so without it the slow check is invisible inside the fast-looking job.

There is no millisecond clock in POSIX `sh`
and none that every machine has,
so [`tests/timing.sh`](/tests/timing.sh) looks for one —
`date +%N` is GNU's, macOS does not have it,
and `perl` and `python3` both carry a sub-second clock —
and the order it tries is that file's.
A machine with nothing better than whole seconds is timed in them
and says so above the block,
rather than reporting a column of zeroes as if they were measurements.

`TEST_TIMING=0`, or an empty value, drops the block;
anything else, including leaving it unset, keeps it,
which is the default [`tests/run`](/tests/run) sets.
A run that will not print the durations does not measure them either.
