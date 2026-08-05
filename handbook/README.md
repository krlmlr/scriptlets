# The scriptlets handbook

The single source of truth
for every documentable aspect of this repository;
internal pages like this one navigate and state their area's principles,
leaves explain ([`meta/handbook/`](meta/handbook/README.md)).

The areas divide by what a question is about,
not by who is asking it:
the reader who installs once and the one who maintains the repository
are served by the same tree,
and the same question brings both to the same leaf.

* [`install/`](install/) — getting the files onto a machine
  and off it again: the tasks, the bootstrap script,
  importing a file you already have, prerequisites
* [`layout/`](layout/) — how the repository maps onto the home
  directory: the dot rules, the tags, the `PATH`,
  the home-grown layout it replaced
* [`config/`](config/) — what the installed configuration does:
  the inventory, zsh startup profiling, zsh completion
* [`tools/`](tools/) — the scripts that land in `~/bin`,
  grouped by what they are for, each with its status
* [`testing/`](testing/) — the throw-away home directory,
  the checks, CI
* [`meta/`](meta/) — the rules, the authoring checklist, the glossary
