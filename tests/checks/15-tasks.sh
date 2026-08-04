#!/bin/sh
# `mise run` with no task offers the task list -- on a terminal, a picker --
# rather than running something.
#
# It is one line away from not doing that: an `#MISE alias="default"` on any
# task makes a bare `mise run` run that task instead, which is a surprise where
# a menu was expected, and a surprise that writes to the home directory.

set -u

. "$(dirname -- "$0")/../lib.sh"

output=$(mise -C "$REPO" run </dev/null 2>&1 || true)

if mise -C "$REPO" run </dev/null >/dev/null 2>&1; then
    fail "a bare mise run does not run a task" "it succeeded, so something ran"
else
    pass "a bare mise run does not run a task"
fi

missing=
for name in install import check test; do
    case "$output" in
    *"$name"*) ;;
    *) missing="$missing $name" ;;
    esac
done

if [ -z "$missing" ]; then
    pass "a bare mise run offers the tasks to choose from"
else
    fail "a bare mise run offers the tasks to choose from" \
        "not listed:$missing
$output"
fi
