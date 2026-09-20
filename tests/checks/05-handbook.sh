#!/bin/sh
# The handbook's mechanical shape, checked by the script the docs-consistency
# skill carries from its source (handbook/meta/local/README.md says what runs
# the checks here, handbook/meta/handbook/README.md points at the rules they
# enforce). Whether a fact sits in the leaf that owns it stays judgment work;
# this check owns the shape.
#
# It reads the repository alone -- nothing here looks at the home directory
# the other checks install into, which is why it can run first.

set -u

. "$(dirname -- "$0")/../lib.sh"

cd "$REPO" || exit 1

if output=$(.claude/skills/docs-consistency/scripts/check-handbook.sh 2>&1); then
    pass "the handbook holds its shape"
else
    fail "the handbook holds its shape" "$output"
fi
