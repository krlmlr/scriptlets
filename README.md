scriptlets
==========

A collection of tiny but helpful shell scripts for personal use.
Tested with current Ubuntu.
Licensed under [GPL v3](http://www.gnu.org/copyleft/gpl.html).

To install all scripts to `~/bin` (by creating symbolic links), type `make`.

##copy-real-path

Copies its argument to the clipboard.

##extmon-start and extmon-stop

Start multi-monitor output [on an Optimus card, using bumblebee](http://askubuntu.com/a/303897/30266).
Needs tweaking to adapt to your screen setup.

##i4 and i4c

Indent current clipboard contents by four spaces and copy back to clipboard, the latter script places two hashes in front.

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
