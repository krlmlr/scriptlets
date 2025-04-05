# scriptlets

A collection of tiny but helpful shell scripts for personal use.
Tested with current Ubuntu and macOS.
Licensed under [GPL v3](http://www.gnu.org/copyleft/gpl.html).

To install all scripts to `~/bin` (by creating symbolic links), clone the project and type `make`. Or run the [`bootstrap`](bootstrap) script:

```sh
curl -s https://raw.githubusercontent.com/krlmlr/scriptlets/main/bootstrap | sh
```

# Actively used tools

## Notifications

### n

Execute command in the foreground and show desktop notification after completion.
Currently macOS only.

### bkg

Execute command in the background and show desktop notification *in case of error*.
Currently macOS only.

## h and s

Iterate over all worktrees under the current Git repository and execute a command in each of them.
With `h`, the command is executed directly.
The `s` command prepends `git`, it is a wrapper around `h git` .
Supported switches:

- `-i` or `--interactive`: run the command in interactive mode, turn off parallel propcessing
- `-n` or `--dry-run`: show the command that would be executed, but do not execute it
- `-p` or `--paged`: show the output of the command in a pager
- `-x` or `--log-commands`: also log the commands that are executed

`gita` both does too much and not enough, let's see how far I can get with home-grown scripts.

`g` is a simple forwarder to `git`.

FIXME: Integrate with `inside` and `every`

## k

A simple forwarder to `kubectl`.

## rh

Start RStudio with an `.Rproj` project file found in the current directory.
If no project file is found, it is created using `usethis::use_rstudio()`.

## git-mmv

Allows you to write `git mmv` to move several Git-controlled files at once, with the usual `mmv` syntax.

## git-merge-into

Merges the current branch into another branch without altering the current working copy.

## pmake

Parallel `make`, uses number of CPU cores as number of jobs.

## retry

Execute command until success, with increasing time intervals between failures.

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

## slecho

Echoes each of its parameters on a single line.

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

# Obsolete

## is-unmetered

Exits with 0 if and only if the connection is configured as an unmetered connection.

## mail-after

Executes a script and e-mails the status and output to the current user after completion.

## tbca

Creates a new mail in Thunderbird with attachments (given as parameters).

## xpra-attach-ssh

A simple wrapper around `xpra attach`, useful to [integrate xpra with GNU Screen](http://krlmlr.github.io/2013/08/07/integrating-xpra-with-screen/).

## Open my GUI here

### texstudio-here

Start a new instance of texstudio with a `.txss` session file found in the current directory.

## copy-real-path

Copies its argument to the clipboard.

## ghpsd

GitHub Pages in a separate directory. Allows efficiently maintaining and synchronizing the contents of the `gh-pages` branch in a [subdirectory of the main branch](http://rafeca.com/2012/01/17/automate-your-release-flow/).  Supports subcommands `init`, `repair` (in case you want to undo `init`, works only before pushing), `merge` and `checkout`.

Use `ghpsd init` for creating an empty `gh-pages` subdirectory that will hold the contents of your `gh-pages` branch. After adding to this subdirectory, use `ghpsd merge` for updating the `gh-pages` branch. Note that you still have to `push` to GitHub.

It works by cloning a copy of the repo into a shadow subdirectory named `.gh-pages` (which is added to `.gitignore`, too); this makes updating the `gh-pages` branch work seamless.  Call `ghpsd checkout` to recreate the hidden `.gh-pages` folder, this clones locally and does not require network access.

You can also add the call `ghpsd merge` to your commit hook.

## encfs-local

`encfs` command with support for relative paths.

## i4 and i4c

Indent current clipboard contents by four spaces and copy back to clipboard, the latter script places two hashes in front.

## soR

Executes an R script in a way that its contents and output are formatted as strict Markdown.

## extmon-start and extmon-stop

Start multi-monitor output [on an Optimus card, using bumblebee](http://askubuntu.com/a/303897/30266).  Needs tweaking to adapt to your screen setup.



Copyright 2015-2025 Kirill Müller.
