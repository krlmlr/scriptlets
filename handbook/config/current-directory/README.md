# The working directory

Every interactive zsh tells the terminal which directory it is in,
as a file URL naming the host as well as the path,
whenever that directory changes and again before every prompt.
The sequence is OSC 7, the spelling terminals agree on —
iTerm2 reads it as
[a synonym for its own `RemoteHost` and `CurrentDir`](https://iterm2.com/documentation-escape-codes.html),
which is the proprietary pair it would take otherwise —
and [`rcm/zshrc`](/rcm/zshrc) is where it is sent from.

A terminal that reads it opens a new tab, window or split
in the directory the current one is in rather than in `$HOME`,
resolves a clicked file name against it,
and can tell a directory here from one on a host reached by ssh.
A terminal that reads none of it ignores it:
the sequence takes up no columns, and nothing here is tied to one terminal.

**A shell the terminal can see into may not need it.**
A terminal drawing a local shell can ask the operating system
what directory that process is in, and some do —
iTerm2 documents its `path` as working without any shell integration,
[but not once you ssh elsewhere](https://iterm2.com/documentation-variables.html).
The report is what covers the shells it cannot see:
one on the far side of an ssh connection, or in a container.

**The path is encoded one byte at a time.**
A file URL is ASCII, so anything outside the unreserved set is sent as `%` and
two hex digits, and the question is what "anything" counts as one character.
`LC_ALL=C` is set for the length of the function so that the substitution
matches single bytes: a path outside ASCII is then encoded as the UTF-8 bytes
it is made of, which is what a reader decodes it back into.
Encoding code points instead would look right and survive only
on a machine whose paths are all ASCII anyway.

**Nothing here costs a process.**
`print` is a builtin and `$(( ))` is arithmetic rather than a command,
so the encoding is zsh's own — the standard the rest of the startup is held to
([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md)).

**It is sent from two hooks, and each covers what the other misses.**
`chpwd` fires the moment the directory changes,
which is what makes `cd build && make` leave the terminal pointing at `build`
for the minutes that follow rather than at the directory it started in;
`precmd` fires before every prompt,
which puts the directory back after a program has reported one of its own —
an `ssh` that ended, a nested shell that exited.
Repeating a report costs two builtins and says the same thing twice,
and that is the whole difference from the prompt marks
([`config/prompt-marks/`](/handbook/config/prompt-marks/README.md)):
a directory is state, and state can be re-asserted.
A mark is a place, and a place sent twice is two places.

**Where Ghostty's own integration is loaded, the directory is left to it**,
under the same condition that leaves it the prompt marks.
Ghostty reports the same directory in kitty's `kitty-shell-cwd://` scheme,
which is a scheme invented to skip the encoding above;
`file://` is the one every terminal reads, and is what this sends.

**tmux consumes it and passes nothing on.**
An OSC 7 that arrives in a pane sets that pane's path — tmux's
`#{pane_path}` — and stops there,
so a terminal outside tmux learns nothing from a shell inside one.
What a new tmux window or split opens in is `#{pane_current_path}`,
which tmux reads from the operating system rather than from this report,
and which a binding has to name for a window to inherit it at all.
