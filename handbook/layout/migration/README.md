# Coming from the home-grown layout

The layout before rcm — generated installer scripts over a `home/`
directory — is preserved on the
[`home-grown`](https://github.com/krlmlr/scriptlets/tree/home-grown)
branch.
Everything lands where it always did, still as symbolic links,
so nothing in `$HOME` moves;
what changed is where the files sit *inside* the repository,
and what drives the installation.

| Before | Now |
| --- | --- |
| `home/dot-bashrc` | `rcm/bashrc` — rcm supplies the dot |
| `home/dot-ssh/config` | `rcm/ssh/config` |
| `home/bin/h` | `rcm/bin/h` — `bin` is in `UNDOTTED`, so the name is kept |
| `personalized/<USER>/gitconfig` | `rcm/tag-<USER>/scriptlets/gitconfig` |
| `home/dot-finicky.js`, `home/dot-toprc` | `rcm/tag-macos/finicky.js`, `rcm/tag-linux/toprc` |
| `make` | `make` — unchanged, or `mise run install`, which runs the same script |
| `make build` (regenerate the installers) | — nothing to regenerate |
| `make run-force-install` | `mise run force` |
| — | `mise run uninstall`, `mise run check`, `mise run import` |

What an upgrader notices, beyond the table —
the facts are the linked leaves', this page only orders them:

* **rcm is a new prerequisite** — `apt install rcm`, `brew install rcm`
  ([`install/prerequisites/`](/handbook/install/prerequisites/README.md)).
* **The generated installers are gone.**
  `make-install`, `install` and `install-personalized` had to be
  refreshed with `make build` after every change;
  rcm links straight out of `rcm/`,
  so there is nothing to regenerate.
* **Uninstalling is now possible**,
  and `mise run force` replaces existing files;
  the old installer could only add
  ([`install/tasks/`](/handbook/install/tasks/README.md)).
* **Existing files are no longer skipped in silence.**
  The old installer left any pre-existing file alone and moved on;
  a first run on a machine that already has a `~/.gitconfig`
  will stop and prompt
  ([`layout/mapping/`](/handbook/layout/mapping/README.md)).
* **The tag is chosen with `id -un` rather than `$USER`**
  ([`layout/tags/`](/handbook/layout/tags/README.md)).
* **Single-platform files are no longer installed everywhere.**
  The old installers linked `home/dot-finicky.js` and `home/dot-toprc`
  on every machine;
  a platform tag now keeps each to the system it works on —
  and strands the old links on the other system,
  dangling because their target moved
  (the sweep is `layout/mapping/`'s).
* **`~/log/dummy` is now a symbolic link.**
  Previously `home/log/.dummy` was skipped
  and the directory created directly.
