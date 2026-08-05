# Semantic prompt marks

Every interactive zsh tells the terminal where each prompt begins and ends,
where the command it accepted started running,
and where that command ended with which exit status.
The sequences are
[OSC 133](https://gitlab.freedesktop.org/Per_Bothner/specifications/-/blob/master/proposals/semantic-prompts.md),
the semantic-prompt escapes,
and [`rcm/zshrc`](/rcm/zshrc) is where they are sent from.

A terminal that reads them can jump from prompt to prompt,
select or copy the output of a single command,
tell the prompt from the command typed after it,
and tell a command that failed from one that did not.
A terminal that reads none of them ignores them:
they take up no columns, and nothing here is tied to one terminal.
tmux 3.4 records `A` and `C` against the lines they arrive on
and drops `B` and `D` on the floor,
so the last two are for the terminal alone.

**The marks are sent from two places, because they are two kinds of fact.**
`C` and `D` are events — output started, a command ended — and go in
`preexec` and `precmd` hooks.
`A` and `B` are places — this line is where a prompt starts,
this column is where what I typed begins —
and go in `$PS1`, inside the `%{...%}` that tells zsh they occupy no columns.

A place cannot be sent from a hook.
The line editor redraws a prompt from scratch every time:
carriage return, `\e[J` to erase from the cursor to the end of the screen,
then the prompt.
tmux drops what it knows about the lines that erase clears,
and `precmd` runs before all of it,
so a mark sent from there is wiped a moment after it arrives —
leaving the first prompt of a session marked and no other,
which looks like nothing at all until a jump between prompts
goes from wherever you are to the top and nowhere in between.
Sent from inside the prompt they arrive after the erase,
and are renewed at every redraw, which costs nothing:
flagging a line twice is flagging it once.

**`D` is sent only for a prompt a command actually preceded.**
`precmd` runs before every prompt, not after every command,
so a hook that sends `D` unconditionally reports a command-end
before the first prompt of a session and another for every bare Enter,
each carrying the status of the last real command —
one failed command painting three prompts red.
A flag set in `preexec` and cleared in `precmd` is what closes that.

**Where Ghostty's own integration is loaded, the marks are left to it.**
Ghostty sends the same sequences,
and two of everything is worse than one of it.
The condition asks whether that integration is in *this* shell
rather than whether this is a Ghostty window:
`$TERM_PROGRAM` is exported to everything Ghostty starts,
but the integration is injected once, through `$ZDOTDIR`, in the first shell,
so a `zsh` started inside that one — or by tmux, or by vim's `:terminal` —
has the variable and none of the marks.
What the injection does leave in the shell it reached
is a `precmd` hook of its own, and that is what is looked for.
Leaning on the name of another project's function is the price;
it is the safe direction to be wrong in,
since a rename means both integrations mark
where a missed guard would mean neither does.

There is no Ghostty-side switch to prefer instead.
`shell-integration-features` takes `cursor`, `sudo`, `title`, `ssh-env`,
`ssh-terminfo` and `path`, and no `prompt-mark` among them;
`shell-integration = none` would turn off the other features
to be rid of the marking.

**Two prompts get nothing.**
A prompt with escapes switched off (`unsetopt prompt_percent`)
would print the braces rather than hide the marks, so it is left alone;
and anything that replaces `$PS1` after `~/.zshrc` has read
takes the marks with it, since they are added once, as the file is read.

**Nothing here costs a process.**
`print` is a builtin, the strings are constants,
and the prompt marks are expanded by zsh's own prompt machinery —
which is the same standard the rest of the startup is held to
([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md)).
