# Shared by the task scripts. Deliberately not executable: mise takes every
# executable file in this directory for a task, and this one is not.
#
# The scripts run under `mise run`, under `make`, and on their own, so they
# cannot lean on mise's [env] -- the two variables are worked out here instead.
# $0 is the task script that sourced this file, not this file.

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

# RCRC points rcm at the copy in this repository, so the first run works on a
# machine that has no ~/.rcrc yet. DOTFILES overrides DOTFILES_DIRS, so the
# repository does not have to sit in ~/git/scriptlets.
RCRC="$REPO/rcm/rcrc"
DOTFILES="$REPO/rcm"

export REPO RCRC DOTFILES
