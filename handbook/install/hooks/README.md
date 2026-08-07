# `install/hooks/`

What runs around rcm's linking and unlinking,
and what this repository does with it.
Which files rcm links, and where they land,
is [`layout/mapping/`](/handbook/layout/mapping/README.md)'s.

## The mechanism

The hooks are rcm's, and its man pages own them.
`rcup` runs `hooks/pre-up` before it links and `hooks/post-up` after;
`rcdn` runs `hooks/pre-down` and `hooks/post-down` around unlinking.
Each name may be a single file or a directory of them,
and a directory's files run in name order,
so [`rcm/hooks/post-up/`](/rcm/hooks/post-up) holds one file per concern
the way [`mise-tasks/`](/mise-tasks) holds one file per task.

Three properties of the mechanism are load-bearing here:

* **Only executable files run**,
  and a file without the bit is passed over in silence —
  which is why
  [`tests/checks/78-positron.sh`](/tests/checks/78-positron.sh)
  checks the bit rather than trusting it,
  and why the shared
  [`rcm/hooks/positron.sh`](/rcm/hooks/positron.sh)
  is not executable:
  it is sourced by the hooks, never run as one.
* **`hooks/` is never installed.**
  rcm skips the directory by name, in every tree it walks,
  so nothing under it needs an `UNDOTTED` entry
  and nothing lands in the home directory as `~/.hooks`.
* **Each hook runs from the directory it sits in**,
  so a hook reaches its neighbours as `./name`
  and the tree above it as `../name`,
  wherever the clone lives.

Hooks are per tree:
a private sidecar runs its own, from its own `hooks/`
([`layout/private/`](/handbook/layout/private/README.md)).
`mise run check` runs none of them —
`lsrc` only lists the mapping —
and `rcup -K` skips them for one run.

**Which trees' hooks run is not settled by `-d` alone.**
Both commands look for hooks below `DOTFILES_DIRS`,
and only `rcup` assigns that from the `-d` it was given:
`rcdn` keeps `-d` to itself
(checked against rcm 1.3.4).
An uninstall run from a clone anywhere else
would therefore unlink one tree and run another tree's hooks,
or none at all.
The tasks name the trees in the environment as well as in `-d`,
and [`rcm/rcrc`](/rcm/rcrc) defers to a value already set,
so the two readings cannot come apart
([`install/tasks/`](/handbook/install/tasks/README.md)).

## The Positron link

`mise run install` on macOS links Positron's command line tool into
`~/bin` under the name `positron`,
and `mise run uninstall` takes the link away again.
The pair is [`rcm/hooks/post-up/positron`](/rcm/hooks/post-up/positron)
and [`rcm/hooks/pre-down/positron`](/rcm/hooks/pre-down/positron),
over the paths and the tests in
[`rcm/hooks/positron.sh`](/rcm/hooks/positron.sh).

**The name is the whole reason there is a hook.**
Positron is a VS Code fork,
and the tool inside its bundle carries the name it inherited: `code`.
It cannot be renamed where it sits —
an application bundle is signed, and an update replaces it —
so putting that directory on the `PATH`
is putting a second `code` there,
one that shadows VS Code's or is shadowed by it
depending on which came first.
A symbolic link under a name of our choosing is the way out,
and reaching the tool through one is a case it handles:
it follows the link back to the bundle it lives in
before it looks for anything beside it.
A link is not something the repository can ship as a file, though:
its target is an absolute path outside the repository,
present on some accounts and not others,
which is a decision that has to be made on the machine —
hence a hook rather than a file under `rcm/`.

**Where it looks.**
`$HOME/Applications/Positron.app` first, then `/Applications/Positron.app`,
taking the per-user install over the system-wide one when both are there.
`SCRIPTLETS_POSITRON_APP` names one bundle instead of both;
the check drives the hooks with it,
and an account with Positron somewhere else can set it too.
An account with no bundle at either place gets no link and no message.

**What it will not touch.**
A `~/bin/positron` that is not a symbolic link into a `Positron.app`
belongs to the account,
and the hook keeps it and says so on standard error.
rcm asks before replacing a file it did not create;
a hook cannot ask,
because an install must not stop at a prompt
([`layout/mapping/`](/handbook/layout/mapping/README.md)
says what rcm's own prompt does).
The same test decides what `pre-down` removes:
a link into a bundle goes, anything else stays.
A link of ours whose bundle has been deleted is removed
on the next install.

## Limits

**The link follows an install, not the application.**
Installing Positron after the last `mise run install`
leaves the link uncreated until the next one;
nothing watches `/Applications`.
Moving the bundle is the same,
except that the stale link is dangling in the meantime.

**Positron is the only application here.**
Nothing generalises the pattern to other bundles that ship a CLI,
and a second one would be a second hook file beside this one
rather than a list this one reads.
