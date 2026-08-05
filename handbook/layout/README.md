# `layout/`

How the repository's tree maps onto the home directory.
Everything lands as a symbolic link,
so editing a file in the repository takes effect immediately.

* [`mapping/`](mapping/) — `rcm/` to `$HOME`: dots, `UNDOTTED`, prompts, pruning
* [`tags/`](tags/) — files for one account, one platform, or one host
* [`path/`](path/) — how `~/bin` gets onto the `PATH`, on both platforms
* [`migration/`](migration/) — coming from the home-grown layout
