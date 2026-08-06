# The private sidecar

A second dotfiles tree that is not public —
what belongs in one, how it merges with this repository's, and how to
create one.
Where the merged result lands in the home directory is
[`layout/mapping/`](/handbook/layout/mapping/README.md)'s.

A public dotfiles repository cannot hold an API token,
an employer's internal hostname, or a licence key.
The sidecar is a separate private repository shaped like
[`rcm/`](/rcm) and installed in the same pass:
the tasks walk both trees and link both into `$HOME`.
A machine without one installs exactly what it always did,
because rcm skips a dotfiles directory that is not there —
so nothing here has to be switched on.

## Where it lives

`~/git/scriptlets-private`,
beside the public clone that
[`install/bootstrap/`](/handbook/install/bootstrap/README.md)
puts in `~/git/scriptlets`.
`$SCRIPTLETS_PRIVATE` overrides that path,
and both places that need it read the same variable:
[`rcm/rcrc`](/rcm/rcrc), for a bare `rcup` or `lsrc`,
and [`mise-tasks/lib.sh`](/mise-tasks/lib.sh), for the tasks
([`install/tasks/`](/handbook/install/tasks/README.md)).

## Creating one

[`bootstrap-private`](/bootstrap-private) writes the skeleton,
commits it, creates the repository private on GitHub with a description,
adds `origin` and pushes,
leaving the working copy behind as the clone:

```sh
./bootstrap-private -n     # report what each step would do, change nothing
./bootstrap-private        # do it
```

It needs the [GitHub CLI](https://cli.github.com) logged in
([`install/prerequisites/`](/handbook/install/prerequisites/README.md)).
`-r` names the repository where `scriptlets-private` is taken,
and `-d` gives it a description —
the one property the script keeps in step on a repository it did not
create, so a later run with a different `-d` changes it on GitHub
and a run without one leaves it alone.
Without `gh` the same end state is a private repository created by
hand, cloned to the path above,
and the skeleton written into it; `-n` lists the files.

The skeleton is empty of secrets and installs cleanly as it stands:
every file in it is comments, saying what belongs there.

**Every step is idempotent, and says which of two things it found.**
A step brings one thing to the state it should be in and reports it as
created, already so, or updated,
so a run reads as what changed rather than as what ran.
Running the script again therefore converges —
after an interruption, on a machine where half of it is already done,
or once it has grown another step —
and this is the property to preserve when adding one:
inspect first, act only where the state differs.

**No file that exists is ever rewritten.**
By the second run a file may hold the secrets it was created to hold,
and nothing in the script can tell what it wrote
from what was put there afterwards.
The same run reports such a file as already present and moves on,
which is also why a half-finished first attempt can simply be rerun.
`origin` is the one thing a rerun will not adjust:
a remote pointing somewhere else is a decision,
and pushing to it would be the script guessing which.
It stops and says so instead.

## What goes in it

The public tree already declares where private content plugs in,
so the common case adds a file and changes nothing else.
Each of these is read only if it exists,
which is why a machine without a sidecar needs none of them:

| In the sidecar | Installed as | Read by |
| --- | --- | --- |
| `rcm/bash_secrets` | `~/.bash_secrets` | [`rcm/bash_aliases`](/rcm/bash_aliases), and so by zsh as well |
| `rcm/ssh/config-private` | `~/.ssh/config-private` | the `Include config-private` in [`rcm/ssh/config`](/rcm/ssh/config) |
| `rcm/gitconfig.user` | `~/.gitconfig.user` | the `[include]` section of [`rcm/gitconfig`](/rcm/gitconfig) |
| `rcm/Rprofile.private` | `~/.Rprofile.private` | [`rcm/Rprofile`](/rcm/Rprofile) |

Beyond those seams a sidecar is an ordinary dotfiles tree:
a name the public one does not have is simply added,
under the same dot rules and the same `UNDOTTED` list.
What the public tree installs, and through which of these includes,
is [`config/files/`](/handbook/config/files/README.md)'s.

## How the two trees merge

**The sidecar is walked first, and the first tree wins.**
Where a name is in both, rcm takes the one it reaches first and says
nothing about the other,
so the order decides — and [`rcm/rcrc`](/rcm/rcrc) sets it,
sidecar ahead of public.
That is what lets a sidecar override a shipped file
rather than be silently ignored.
It outranks the tags too:
a plain file in the sidecar beats a `tag-<user>/` file in the public
tree, because the tree is chosen before the tag is
([`layout/tags/`](/handbook/layout/tags/README.md)).
Neither side warns, in either direction;
`mise run check` lists what won.

**A fragment at the sidecar's root is how it configures rcm.**
`DOTFILES_DIRS`, `UNDOTTED` and `TAGS` apply to every tree rcm walks,
and rcm reads exactly one `rcrc`,
so a sidecar has no configuration of its own to ship.
[`rcm/rcrc`](/rcm/rcrc) sources `$SCRIPTLETS_PRIVATE/rcrc` as its last
act instead, once those variables are set,
and the fragment appends to them:
`UNDOTTED="$UNDOTTED keys"` adds a name that keeps its spelling
without dropping the ones the public tree needs.
Assigning instead of appending drops exactly those.

rcm has a `<dir>:<glob>` syntax that looks like it would scope
`UNDOTTED` to one tree, and it cannot be used for this:
`lsrc` reads the whole variable as one word,
so a single scoped entry anywhere in it silences every plain one.
The fragment is this repository's answer,
and [`testing/`](/handbook/testing/README.md) has the check that keeps
it working.

**The fragment must not be under `rcm/`.**
Everything there is installed like any other file,
from the tree that is walked first,
so an `rcm/rcrc` in a sidecar would land as `~/.rcrc` in place of the
file that configures rcm —
and every later run would be driven by a fragment that appends to
variables nothing had set.
The tasks refuse to run while one is there,
rather than let it happen quietly.

**Tags and hooks are per tree.**
`tag-<user>/`, `tag-<platform>/` and `host-<name>/` in the sidecar are
selected by the same `TAGS` the public `rcrc` computes.
The sidecar's `hooks/` is its own,
run in its turn alongside this repository's
([`install/hooks/`](/handbook/install/hooks/README.md)).
That is where the `chmod` goes that keeps `~/.ssh/config-private`
unreadable to anyone else —
rcm links rather than copies,
so the permissions of the installed file are the repository's.

## Limits

**Uninstalling needs the sidecar to still be there.**
`mise run uninstall` removes what rcm can see,
so a sidecar deleted or moved first leaves every link it owned behind,
dangling.
Nothing prunes, and the sweep for strays is
[`layout/mapping/`](/handbook/layout/mapping/README.md)'s.

**`mise run import` always imports into the public repository**
([`install/import/`](/handbook/install/import/README.md)).
Putting a file you already have into the sidecar instead is a `git mv`
between the two trees, then `mise run install` again.
