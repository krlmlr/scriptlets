# `layout/`

How a dotfiles tree maps onto the home directory —
this repository's, and a private one beside it where there is one.
Everything lands as a symbolic link,
so editing a file in the repository takes effect immediately.

* [`mapping/`](mapping/) — `rcm/` to `$HOME`: dots, `UNDOTTED`, prompts, pruning
* [`tags/`](tags/) — files for one account, one platform, or one host
* [`private/`](private/) — the private sidecar repository: a second tree, merged
* [`path/`](path/) — how `~/bin` gets onto the `PATH`, on both platforms
* [`migration/`](migration/) — coming from the home-grown layout
