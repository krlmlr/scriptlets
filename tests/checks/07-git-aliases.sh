#!/bin/sh
# The trie in handbook/config/git-aliases/README.md is what the aliases render
# to, and not a snapshot of what they once rendered to.
#
# An enumeration in prose goes stale without anyone noticing, because nothing
# fails when it does (handbook/meta/authoring/README.md). This is what fails:
# the page carries the output of tests/git-aliases-trie, and an alias added,
# renamed or dropped without regenerating it stops the run here.
#
# It reads the repository alone -- neither the home directory the other checks
# install into nor the account's own git configuration -- so it runs with the
# other two that come before the installed ones.

set -u

. "$(dirname -- "$0")/../lib.sh"

page=$REPO/handbook/config/git-aliases/README.md

expected=$("$REPO/tests/git-aliases-trie")

# The one fenced block of the page, which is the trie and nothing else.
actual=$(awk '
    /^```text$/ { inside = 1; next }
    /^```$/     { if (inside) exit }
    inside      { print }
' "$page")

if [ "$expected" = "$actual" ]; then
    pass "the handbook trie is what the aliases render to"
else
    work=$(mktemp -d "${TMPDIR:-/tmp}/git-aliases-check.XXXXXX")
    printf '%s\n' "$actual" >"$work/page"
    printf '%s\n' "$expected" >"$work/aliases"
    fail "the handbook trie is what the aliases render to" \
        "regenerate it: tests/git-aliases-trie

$(diff -u "$work/page" "$work/aliases" | sed -n '3,30p')"
    rm -rf "$work"
fi
