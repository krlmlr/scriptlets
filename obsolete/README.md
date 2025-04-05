# Obsolete tools

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
