# AGENTS.md

Orienting doc for any AI coding agent landing in this repository.
Format: [agents.md](https://agents.md/).

_Everything this repository documents lives in [`handbook/`](/handbook/README.md), the single source of truth.
This page only routes there._

## What this repository is

Small shell scripts and configuration files, linked into a home directory by rcm,
with a private sidecar repository merged into the same home where anything secret belongs
([`handbook/layout/`](/handbook/layout/README.md)).
The one thing to know before touching it: nothing is tried out on the account you are working in.
`mise run test` installs into a home directory it makes and discards, and runs the checks there
([`handbook/testing/`](/handbook/testing/README.md)).

## The first five minutes

- where a fact lives, and how the tree grows: [`handbook/meta/handbook/`](/handbook/meta/handbook/README.md)
- how a sentence is written here, before you write one: [`handbook/meta/authoring/`](/handbook/meta/authoring/README.md)
- what this repository decides for itself, and the rules it adopts beyond the shared ones:
  [`handbook/meta/local/`](/handbook/meta/local/README.md)
- the vocabulary this repository uses: [`handbook/meta/glossary/`](/handbook/meta/glossary/README.md)
- how a file in the repository becomes a file in the home directory: [`handbook/layout/mapping/`](/handbook/layout/mapping/README.md)
- how an installation is made and undone, and what it needs first: [`handbook/install/`](/handbook/install/README.md)
- how the checks are run, and what each one covers: [`handbook/testing/`](/handbook/testing/README.md)
- what the scripts that land in `~/bin` are for: [`handbook/tools/`](/handbook/tools/README.md)

## Behaviour

- Every document outside `handbook/` either derives from it or backreferences it, and this page's italic line is its own.
  In Claude Code the prose rules load on their own when you touch a file carrying prose;
  run `/docs:check` after touching documentation.
- Never install into the account you are working in, and never test against it
  ([`handbook/meta/local/`](/handbook/meta/local/README.md)).
- The trie in [`handbook/config/git-aliases/`](/handbook/config/git-aliases/README.md) is generated from
  [`rcm/gitaliases`](/rcm/gitaliases): change the aliases and regenerate, and never edit the block by hand.

---

_The shared pages under `handbook/meta/` point to their home, [`cynkra/handbook-tools`](https://github.com/cynkra/handbook-tools);
the rule file and the skills are carried from there unchanged,
and `.handbook-source` names the files and the state of the source this handbook was last checked against._
