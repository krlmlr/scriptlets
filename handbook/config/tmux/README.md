# tmux copy mode

What [`rcm/tmux.conf`](/rcm/tmux.conf) adds to tmux: three keys that navigate
and copy by the prompt boundaries a shell marks,
and the option that says where a copy goes.
It needs tmux 3.4 or newer,
which is where `previous-prompt`, `next-prompt` and their `-o` flag arrived.

* `[` in copy mode — jump to the previous prompt
* `]` in copy mode — jump to the next prompt
* `prefix o` — copy the output of the last command, and leave copy mode

**What marks the prompts is the shell, not tmux.**
tmux records two of the OSC 133 sequences against the lines they arrive on —
`A`, a prompt starts here, and `C`, output starts here —
and a pane whose shell sends neither leaves all three keys
with nothing to find.
An older tmux reads the file without complaining
and fails only when one of the keys is pressed:
the name of a copy-mode command is not resolved until it runs.

**`[` and `]` are bound in both copy-mode key tables.**
tmux picks the table from the `mode-keys` option,
whose default follows the `$EDITOR` and `$VISUAL`
of the environment the tmux *server* was started in,
and is `emacs` unless one of them contains `vi`.
Neither editor these dotfiles set is a vi,
so binding `copy-mode-vi` alone —
which is what the recipes for this in circulation do —
would leave the keys inert on most of the machines they install on.
Both keys are unbound in both tables to begin with.

**`prefix o` walks the marks.**
From the bottom of the history it goes back to where the last command's
output started, forward to the prompt that followed it,
one line back up, and copies.
It starts at the bottom explicitly because `copy-mode` does nothing
when the pane is already in copy mode,
and the key would otherwise mean
"the output above wherever I have scrolled to".

The one thing it will not do is take the clipboard with it
when there is nothing to copy.
Where no prompt is marked below the output —
the command is still running, or it printed nothing at all,
or the pane has no marks in it
(a shell without them, an ssh session, a full-screen program) —
`next-prompt` does not move,
the selection would end a line above where it began,
and what tmux copies is a stray newline.
The binding compares the cursor before and after that step
and leaves copy mode without copying when it did not move.
The comparison carries the scroll position as well as the cursor row,
because the row alone is measured against the visible screen,
and output longer than the window scrolls it out from under the comparison.

`prefix o` replaces the default, which selects the next pane;
`prefix q` shows the pane numbers and takes one.

**A copy goes through the `copy-command` option.**
`copy-pipe-and-cancel` with no command of its own falls back to it,
so the command is named once
and every copy that reaches for it goes to the same clipboard —
including the default mouse-drag bindings,
on a machine where `mouse` has been switched on.
`pbcopy` is macOS-only and `~/.tmux.conf` installs everywhere,
so the name lives in `~/.tmux-clipboard.conf`,
which only `tag-macos/` ships
([`layout/tags/`](/handbook/layout/tags/README.md)),
and `source-file -q` is what makes it optional.
Where there is none the option stays empty,
a copy lands in the tmux paste buffer alone,
and `prefix ]` pastes it.

On a machine reached over ssh, `set -g set-clipboard on` is the other half
of the answer: tmux would then offer its own copies
to the terminal it is displayed on, over OSC 52,
which is the clipboard actually in front of you.
It is not set here.
The default, `external`, passes on what programs inside tmux ask for
and keeps tmux's own copies to itself.
