# Tools

The scripts that land in `~/bin`:
shared ones from [`rcm/bin/`](/rcm/bin),
macOS-only ones from [`rcm/tag-macos/bin/`](/rcm/tag-macos/bin)
([`layout/tags/`](/handbook/layout/tags/README.md) is why).
What they need installed is
[`install/prerequisites/`](/handbook/install/prerequisites/README.md)'s.

Every tool is in one of three states:
**in use** below,
**under review** further down —
still installed, while their future is undecided —
and **retired**,
moved out of `rcm/` into [`obsolete/`](/obsolete/README.md),
whose own page catalogues them.
Where an entry defers to `-h`,
the script's help owns the detail and the entry stays a summary.

## In use

### Across every Git repository below the current directory

**`h`** finds every Git repository below the current directory
and executes a command in each of them.
Linked worktrees are included, since they carry a `.git` file.
Bare repositories are not:
they have no `.git` entry to be found by —
HEAD, config, objects and refs sit at the top of the directory instead —
so a bare clone stays out of the sweep,
and needs something other than a sweep to keep it up to date.
**`s`** prepends `git` — it is a wrapper around `h git`.
The switches:

* `-i` / `--interactive`: run the command in interactive mode,
  turn off parallel processing (with aliases `hi` and `si`)
* `-p` / `--paged`: show the output of the command in a pager
  (with aliases `hp` and `sp`)
* `-n` / `--dry-run`: show the command that would be executed,
  but do not execute it
* `-x` / `--log-commands`: also log the commands that are executed
* `-u` / `--unsorted`: skip the sort/dedup pass over the discovered
  repositories
* `--color=auto|always|never`, `--no-color`: control colored output.
  Default is `auto`: color is enabled when stdout is a TTY
  (or `--paged` is set), and disabled otherwise.
  The [`NO_COLOR`](https://no-color.org/) environment variable also
  disables color unless `--color=always` is given.

The exit status is the parallel run's, not the repositories'.
Every generated command ends in the `sed` that names its output,
so a repository whose command failed says so in the output
and leaves `$?` at zero.
`-i` is the mode that stops at the first failure
and passes that status on,
so a script that needs to know reaches for it
rather than for the parallel default.

[`gita`](https://github.com/nosarthur/gita) both does too much and not
enough; these stay home-grown.
Not yet integrated with `inside` and `every`, which cover the
non-repository case under review below.

**`g`** is a simple forwarder to `git`.

### Git, one repository at a time

**`git-ff`** — fast-forward every branch that is behind the branch it
tracks, in one pass, fetching nothing:
`git fa` first, `git ff` second.
Two mechanisms, because neither reaches both halves.
A branch nothing has checked out is moved by pushing into the repository
itself, `git push . <upstream>:<branch>`,
which refuses anything that is not a fast-forward and so cannot go wrong;
a branch a worktree holds cannot be pushed to at all —
git declines to move the branch of any worktree, the current one and a
linked one alike, since the index and the working tree would stop
agreeing with it —
and is fast-forwarded from inside that worktree with `merge --ff-only`.
A worktree with uncommitted changes is skipped and named,
because a branch left behind in silence reads exactly like one that was
already up to date;
a branch that has diverged is not fast-forwardable and is left alone.
`-n` / `--dry-run` says what would happen.
`git ff` is the whole spelling — the old `fft` warns and forwards —
and the branches of *other* repositories are `s plf`'s, further up.

**`git-pr`** — open the pull request for the current branch, or update
the one that is already there: push the branch, let `gh` fill the body
from its commits, then correct the title to the first commit's subject
and close the issue the branch is named after.
The title needs correcting because `gh pr create --fill` reaches for the
branch name once a branch has more than one commit;
the issue comes out of that name, which is split on dashes,
its last field dropped as the suffix that keeps two branches about the
same issue apart,
and every field that is a number turned into a `Closes` line.
The branch it opens against is what the remote says its default branch
is — `upstream` before `origin`, since a fork's `origin` is the fork.
`-a` / `--auto-merge` ends in `gh pr merge --auto --squash`,
and is what the `pra` alias adds;
`-n` / `--dry-run` prints the commands instead of running them.

**`gh-repo-setup`** — set `gh`'s default repository, and GitHub's merge
options for the repository of the current directory:
a pull request that can be brought up to date from the web,
a branch that goes when it merges, and auto-merge.
All three are settings a repository offers rather than performs,
so the run after `gh repo fork` sets the same three:
a fork that never merges a pull request is no reason to leave one off.
Which repository that is comes from `upstream`,
or from `origin` where there is no `upstream`,
spelled as owner and name because `gh repo edit` refuses a bare one.

**`git-mmv`** — write `git mmv` to move several Git-controlled files
at once, with the usual `mmv` syntax.

**`git-merge-into`** — merge the current branch into another branch
without altering the current working copy.

**`git-bubble`** — how far can the most recent commit be pushed back
up in the history without introducing merge conflicts?
An option to run code, and so also catch semantic conflicts,
is still missing.

**`git-bifurcate`** — create a lightweight tag under
`refs/tags/bif/<shortest-unique-prefix>`
for every commit that has more than one child,
so fork points show up in big-picture views
(`git log --simplify-by-decoration --all`, `gitk --all`)
without extra flags.
The short prefix is the minimum unique within the bifurcation set,
so reruns rename tags as fork points are added or removed.
Commits already pointed at by an unrelated branch, tag, or remote ref
are skipped to avoid duplicate decoration;
annotated tags are dereferenced to their commit,
so a `v1.0` release tag at a fork point is recognised.
`-r` / `--remove` deletes all tags in the namespace and leaves every
other tag alone; `-q` / `--quiet` suppresses the summary line.

**`git-ssh-remote`** — rewrite the HTTPS URLs of a repository's GitHub
remotes as their SSH equivalents,
turning `https://github.com/krlmlr/scriptlets.git`
into `git@github.com:krlmlr/scriptlets.git`.
This is the repair for a clone made with the URL GitHub offers first,
which asks for a password on every push.
Named remotes are converted, all of them when none is named,
fetch and push URLs alike;
remotes that already speak SSH, and HTTPS remotes on other hosts,
are left as they are.
`-n` / `--dry-run` previews;
`-a` / `--all-hosts` converts any HTTPS host,
which is what GitHub Enterprise or a GitLab remote needs;
the finer rules — credentials, ports, the `.git` suffix —
are `-h`'s, not `--help`'s,
which git intercepts to look for a man page.

### zsh startup

**`zsh-compinit-refresh`** — rebuild zsh's completion dump now,
audit and all;
the daily-audit design it punctures is
[`config/completion/`](/handbook/config/completion/README.md)'s.

**`zsh-startup-bench`** — benchmark the shell startup, break one down
by function, or summarise the continuous log;
the three views, and the profiling they sit on, are
[`config/zsh-startup/`](/handbook/config/zsh-startup/README.md)'s,
and `-h` prints the commentary in full.

### zsh history

**`zsh-history-repair`** — leave a per-day history directory holding each
entry once, in the day it was run on;
it reports and changes nothing until `--apply`,
and keeps the originals when it does.
The layout it repairs to, and what a repair cannot recover, are
[`config/history/`](/handbook/config/history/README.md)'s.

### R

**`rh`** — start RStudio with an `.Rproj` project file found in the
current directory.
If no project file is found,
it is created using `usethis::use_rstudio()`.

**`air-format`** — run `air format` on a single file
if the containing Git repository has an `air.toml` file.
Useful as a formatter in the RStudio IDE.

### Notifications (macOS only)

**`n`** — execute a command in the foreground
and show a desktop notification after completion.
Notifies through `terminal-notifier`,
so it is installed on macOS only.

**`bkg`** — execute a command in the background
and show a desktop notification *in case of error*.
Installed on macOS only, for the same reason as `n`.

### Sleep (macOS only)

**`nosleep`** — stop the machine from sleeping, or let it sleep again.
`nosleep on` and `nosleep off` say which,
and a bare `nosleep` flips whichever way the machine currently sits,
reading the current state from `pmset -g`.
This is `pmset -a disablesleep` and deliberately not `caffeinate`:
the flag survives a closed lid,
which is the case the tool exists for.
Writing it needs root,
so the script names `sudo` rather than hope for a cached credential —
and a request for the state the machine is already in
changes nothing and asks for no password.
**`slf`** ("sleep forbid") and **`sla`** ("sleep allow")
are the two spellings at three letters,
for the times both are typed often.
Installed on macOS only, since `pmset` is macOS's.

`mise run nosleep-grant` retires the password prompt
([`install/tasks/`](/handbook/install/tasks/README.md)):
it writes a rule to `/etc/sudoers.d/nosleep`
that lets this account run `pmset -a disablesleep` with a 1 and with a 0,
and nothing else.
sudo compares the arguments it is given literally,
so a rule that spells them out grants those two lines alone —
not `disablesleep 2`, not another `pmset` setting.
`--print` shows the rule without writing it, `--remove` takes it back,
and `nosleep` needs none of it:
without the rule it asks for a password, as it always has.

### The rest

**`fsed`** — run `gsed` over the whole tree below the current
directory, `.git` excluded; files are discovered with `ag`.

**`pmake`** — parallel `make`,
uses the number of CPU cores as the number of jobs.

**`retry`** — execute a command until success,
with increasing time intervals between failures.

**`cgrep`** — colorful `egrep`.

**`pdfcat`** — dump the text of a single PDF file to stdout,
a thin wrapper around `pdftotext`.
The name is a misnomer: it concatenates nothing.

**`soffice-macos`** — launch LibreOffice/OpenOffice on macOS with
proper environment setup.
Installed on macOS only,
together with the `csv`, `csv2` and `tsv` aliases that use it.

**`k`** — a simple forwarder to `kubectl`.

## Under review

### Run commands in subdirectories

**`inside`** — execute a command inside a subdirectory,
given as first argument.
**`every`** treats each line of the standard input as a subdirectory
to execute the command in (via `inside`),
and **`each`** is the same in parallel.
**`everyfile`** executes the command in each subdirectory
(via `inside`), and **`eachfile`** is the same in parallel;
`everyfile` currently assumes that the current directory
only has subdirectories, not files.

### One by one

**`gh-mirror`** — mirrors GitHub issues in a subdirectory of `.git`
for offline use. A low-tech wrapper for `wget`.

**`git-backup`** — tracks the files that Git does *not* track
in a shadow Git repository.
**`git-backup-all`** treats a whole tree of Git repositories with it.

**`git-merge-update`** — simplifies maintenance of "development"
branches that contain several feature/bugfix branches.

**`git-rsync`** — allows repeated Git-less synchronization
with remote locations via `rsync`.

**`git-config-parent`** — configure Git to look for settings
in parent directories.

**`git-join-repos`** — join multiple Git repositories into one
while preserving history.

**`imgdiff`** and **`imgdiff-bg`** — compare two images side by side
and show differences in a middle pane; requires ImageMagick.
The `-bg` script exits immediately;
usage: `git difftool -x imgdiff-bg -y <image files>`
([source](http://www.akikoskinen.info/image-diffs-with-git)).

**`machine-load`** — connects to remote machines
and shows the top 5 processes by CPU consumption.

**`ogv-to-gif`** — convert a video to an animated GIF.
Currently broken: the script exits after the frame-export step,
and the rest is unreachable.

**`slecho`** — echoes each of its parameters on a line of its own.

**`rpt`** — repeat a command (default: `make`)
as soon as the contents of the current working directory change.

**`reprex`** — reproducible shell examples:
it reads commands, runs them,
and echoes the commands as typed
and their output as `#` comments,
until end of input —
so both piping a script through it and typing at it work:

```sh
~ ( echo "echo a"; echo "echo b" ) | reprex
echo a
echo b
# a
# b
```

Not perfect, but a start;
this is likely better solved with `script`.

**`azure-resource-group-get-default`**, **`azure-vm-deallocate`**,
**`azure-vm-set-size`**, **`azure-vm-start`** —
get the default Azure resource group,
and deallocate, resize, or start an Azure VM.
