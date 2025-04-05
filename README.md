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

- `-i` or `--interactive`: run the command in interactive mode, turn off parallel propcessing (with aliases `hi` and `si`)
- `-p` or `--paged`: show the output of the command in a pager (with aliases `hp` and `sp`)
- `-n` or `--dry-run`: show the command that would be executed, but do not execute it
- `-x` or `--log-commands`: also log the commands that are executed

`gita` both does too much and not enough, let's see how far I can get with home-grown scripts.

`g` is a simple forwarder to `git`.

FIXME: Integrate with `inside` and `every`

## rh

Start RStudio with an `.Rproj` project file found in the current directory.
If no project file is found, it is created using `usethis::use_rstudio()`.

## fsed

Run `gsed` on files in subdirectories.

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

Concatenate multiple PDF files into a single document.

## git-bubble

How far can the most recent commit be pushed back up in the history without introducing merge conflicts?

FIXME: Add option to run code (check for semantic conflicts).

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

In the [`obsolete`](obsolete) directory.



Copyright 2015-2025 Kirill Müller.
