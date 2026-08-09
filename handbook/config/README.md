# `config/`

What the installed configuration files do once they are in place.
The scripts installed beside them are
[`tools/`](/handbook/tools/README.md)'s,
and how anything gets there at all is
[`layout/`](/handbook/layout/README.md)'s.

* [`files/`](files/) — the inventory: what installs as what, and what for
* [`git-aliases/`](git-aliases/) — how a Git alias name is chosen, and the trie they make
* [`zsh-startup/`](zsh-startup/) — every interactive zsh times its own startup
* [`completion/`](completion/) — zsh completion, audited daily instead of per shell
* [`prompt-marks/`](prompt-marks/) — every prompt, command and exit status marked for the terminal
* [`current-directory/`](current-directory/) — the directory the terminal opens the next tab in
* [`editor/`](editor/) — the editor every tool is handed, and the widget that hands it the command line
