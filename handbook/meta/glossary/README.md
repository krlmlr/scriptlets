# Glossary

The tree's recurring terms of art, one line each,
every entry linking the leaf that owns the concept.
A term earns a line once a second leaf uses it,
added by the change that reaches for it —
one line, so the register stays greppable and diffs per term.

* **check** — one script in `tests/checks/`, run in name order against the throw-away home ([`testing/`](/handbook/testing/README.md)).
* **fragment** — the `rcrc` at a sidecar's root, appending to the variables rcm applies to every tree ([`layout/private/`](/handbook/layout/private/README.md)).
* **dump** — zsh's completion dump, audited once a day and trusted in between ([`config/completion/`](/handbook/config/completion/README.md)).
* **hook** — a script rcm runs before or after it links or unlinks, from the tree it belongs to ([`install/hooks/`](/handbook/install/hooks/README.md)).
* **import** — moving a file you already have into the repository, linked back where it was ([`install/import/`](/handbook/install/import/README.md)).
* **sidecar** — a second, private dotfiles tree merged into the same home directory ([`layout/private/`](/handbook/layout/private/README.md)).
* **stamp** — the `.audited` file that dates the last completion audit ([`config/completion/`](/handbook/config/completion/README.md)).
* **tag** — rcm's mechanism behind files that install for one account, platform, or host only ([`layout/tags/`](/handbook/layout/tags/README.md)).
* **task** — one executable script in `mise-tasks/`, reachable through mise and through `make` alike ([`install/tasks/`](/handbook/install/tasks/README.md)).
* **throw-away home** — the fresh home directory the test harness creates, installs into, and checks ([`testing/`](/handbook/testing/README.md)).
* **UNDOTTED** — the names that keep their spelling instead of gaining a leading dot ([`layout/mapping/`](/handbook/layout/mapping/README.md)).
