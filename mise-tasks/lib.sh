# Shared by the task scripts. Deliberately not executable: mise takes every
# executable file in this directory for a task, and this one is not.
#
# The scripts run under `mise run`, under `make`, and on their own, so they
# cannot lean on mise's [env] -- the variables are worked out here instead.
# $0 is the task script that sourced this file, not this file.

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

# RCRC points rcm at the copy in this repository, so the first run works on a
# machine that has no ~/.rcrc yet. DOTFILES overrides DOTFILES_DIRS, so the
# repository does not have to sit in ~/git/scriptlets.
RCRC="$REPO/rcm/rcrc"
DOTFILES="$REPO/rcm"

# The private sidecar repository, if this machine has one
# (handbook/layout/private/README.md). Exported because rcm/rcrc reads it too:
# the tasks are what tell rcm where the sidecar is when it is not at the
# default path.
SCRIPTLETS_PRIVATE="${SCRIPTLETS_PRIVATE:-$HOME/git/scriptlets-private}"

export REPO RCRC DOTFILES SCRIPTLETS_PRIVATE

# A sidecar extends rcm's configuration through a fragment at its root, and an
# `rcrc` under its rcm/ is a different thing entirely: it would be installed
# like any other file, from the tree that is walked first, so ~/.rcrc would
# become the fragment that only appends to variables nothing had set. Every
# later run would be configured by half a file, and nothing would say so.
if [ -f "$SCRIPTLETS_PRIVATE/rcm/rcrc" ]; then
    echo "$SCRIPTLETS_PRIVATE/rcm/rcrc would be installed as ~/.rcrc," >&2
    echo "replacing the file that configures rcm with the fragment that only" >&2
    echo "extends it. Move it to $SCRIPTLETS_PRIVATE/rcrc, which rcm/rcrc" >&2
    echo "sources: handbook/layout/private/README.md." >&2
    exit 1
fi

# Run an rcm command over the trees this machine has. rcm's -d replaces
# DOTFILES_DIRS from rcrc rather than adding to it, so a task that passes one
# has to pass them all; the sidecar comes first, in the order rcrc sets.
#
# Every task that reaches rcm goes through here, so none of them can act on a
# different set of trees than the others -- an install that saw the sidecar and
# an uninstall that did not would strand every link the sidecar owns.
#
# The same list also goes into the environment, because rcm reads the trees
# twice and only one of the readings honours -d: `rcup` assigns DOTFILES_DIRS
# from it and `rcdn` keeps it to itself, while the hooks of both are looked for
# below DOTFILES_DIRS (rcm 1.3.4). Without this an uninstall would unlink one
# tree and run another tree's hooks -- handbook/install/hooks/README.md.
# rcm/rcrc defers to a value already set, so the two never disagree.
rcm_run() {
    _rcm_cmd=$1
    shift

    if [ -d "$SCRIPTLETS_PRIVATE/rcm" ]; then
        DOTFILES_DIRS="$SCRIPTLETS_PRIVATE/rcm $DOTFILES" \
            "$_rcm_cmd" -d "$SCRIPTLETS_PRIVATE/rcm" -d "$DOTFILES" "$@"
    else
        DOTFILES_DIRS="$DOTFILES" "$_rcm_cmd" -d "$DOTFILES" "$@"
    fi
}
