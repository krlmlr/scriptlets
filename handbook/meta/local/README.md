# What this repository decides

The choices the shared rules ([`meta/handbook/`](/handbook/meta/handbook/README.md)) leave open, answered for this repository,
and the rules it adopts beyond the shared ones.
This is the one page under `meta/` that answers for this repository;
the shared pages beside it point to their home, [`cynkra/handbook-tools`](https://github.com/cynkra/handbook-tools),
and [`.handbook-source`](/.handbook-source) names the state of the source this handbook was last checked against.

**Intent and status.**
Both live in [the issue tracker](https://github.com/krlmlr/scriptlets/issues), and neither lives in the tree.
Each affected leaf links the issue that carries its intent,
and an intention that has become fact is written as fact, in the leaf, with no trace of its having once been one.

**Evidence.**
Measurements live under [`experiments/`](/experiments/README.md), in the shared shape, and the registry there names every record.
There are none yet, because what this repository leans on is measured again rather than recorded once:
the shipped profiler times every interactive zsh on the machine asking
([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md)),
and a behavioural claim lands with the check that pins it ([`testing/`](/handbook/testing/README.md)).
A measurement that needs a platform, a version, or an hour nobody will spend twice earns a directory.

**What this repository does not author.**
The trie in [`config/git-aliases/`](/handbook/config/git-aliases/README.md) is the output of a script rather than prose,
regenerated rather than edited, and a check refuses a page that has drifted from it.
The files carried from the source are the source's:
an edit to one belongs there rather than in the copy, and [`.handbook-source`](/.handbook-source) names them.
Nothing else here is generated or vendored.

**The comment budget.**
The scripts are POSIX shell and the configuration files are whatever the tool reading them accepts.
Neither has a formatter here, and a comment in one aims for 80 columns.

**Rules adopted beyond the shared ones.**

* **Em dashes are permitted**, in prose and code alike.
  This repository was written with them throughout, and [`.handbook-ignore`](/.handbook-ignore) turns the check off for that reason.
* **Verify against the throw-away home, never against an account you care about.**
  A claim about what an installation does is checked where `mise run test` installs, in a home directory it makes and discards
  ([`testing/`](/handbook/testing/README.md)).

**Documents shipped without the tree.**
None.
The scripts are installed as symbolic links into a clone that carries the handbook,
so every secondary document links into the tree directly.

**Enforcement.**
[`tests/checks/05-handbook.sh`](/tests/checks/05-handbook.sh) runs the carried check script,
so `mise run test` covers the tree along with everything else ([`testing/`](/handbook/testing/README.md)).
[`.github/workflows/handbook.yaml`](/.github/workflows/handbook.yaml) runs it once more,
without the prerequisites the suite needs before it can install anything,
and checks the carried files against the source.
What needs judgment is review's, against the shared pages and the `docs-consistency` skill beside the script.
