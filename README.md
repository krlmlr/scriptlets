scriptlets
==========

A collection of tiny but helpful shell scripts for personal use.
Tested with current Ubuntu.
Licensed under [GPL v3](http://www.gnu.org/copyleft/gpl.html).

To install all scripts to `~/bin` (by creating symbolic links), type `make`.

##Notifications

###n

Execute command in the foreground and show desktop notification after completion.

###bkg

Execute command in the background and show desktop notification *in case of error*.

##Open my GUI here

###rstudio-here

Start RStudio with an `.Rproj` project file found in the current directory.

###texstudio-here

Start a new instance of texstudio with a `.txss` session file found in the current directory.

##copy-real-path

Copies its argument to the clipboard.

##encfs-local

`encfs` command with support for relative paths.

##extmon-start and extmon-stop

Start multi-monitor output [on an Optimus card, using bumblebee](http://askubuntu.com/a/303897/30266).  Needs tweaking to adapt to your screen setup.

##ghpsd

GitHub Pages in a separate directory. Allows efficiently maintaining and synchronizing the contents of the `gh-pages` branch in a [subdirectory of the main branch](http://rafeca.com/2012/01/17/automate-your-release-flow/).  Supports subcommands `init`, `repair` (in case you want to undo `init`, works only before pushing), `merge` and `checkout`.

Use `ghpsd init` for creating an empty `gh-pages` subdirectory that will hold the contents of your `gh-pages` branch. After adding to this subdirectory, use `ghpsd merge` for updating the `gh-pages` branch. Note that you still have to `push` to GitHub.

It works by cloning a copy of the repo into a shadow subdirectory named `.gh-pages` (which is added to `.gitignore`, too); this makes updating the `gh-pages` branch work seamless.  Call `ghpsd checkout` to recreate the hidden `.gh-pages` folder, this clones locally and does not require network access.

You can also add the call `ghpsd merge` to your commit hook.

##git-mmv

Allows you to write `git mmv` to move several Git-controlled files at once, with the usual `mmv` syntax.

##git-merge-into

Merges the current branch into another branch without altering the current working copy.  Assumes that Git plays well in working copies created by hard-linking
all files.

##i4 and i4c

Indent current clipboard contents by four spaces and copy back to clipboard, the latter script places two hashes in front.

##imgdiff and imgdiff-bg

Compare two images side by side and show differences in a middle pane. Requires ImageMagick. The `-bg` script exits immediately. Usage: `git difftool -x imgdiff-bg -y <image files>`. ([Source](http://www.akikoskinen.info/image-diffs-with-git))

##machine-load

Connects to remote machines and shows the top 5 processes by CPU consumption.

##mail-after

Executes a script and e-mails the status and output to the current user after completion.

##pmake

Parallel `make`, uses number of CPU cores as number of jobs.

##retry
Execute command until success, with increasing time intervals between failures.

##slecho

Echoes each of its parameters on a single line.

##soR

Executes an R script in a way that its contents and output are formatted as strict Markdown.

##tbca

Creates a new mail in Thunderbird with attachments (given as parameters).

##xpra-attach-ssh

A simple wrapper around `xpra attach`, useful to [integrate xpra with GNU Screen](http://krlmlr.github.io/2013/08/07/integrating-xpra-with-screen/).


Copyright 2013 Kirill Müller.
