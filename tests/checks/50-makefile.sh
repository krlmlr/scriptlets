#!/bin/sh
# The Makefile is the fallback for a machine without mise.
#
# It cannot drift from the tasks by construction -- its targets run the very
# scripts in mise-tasks/ that `mise run` runs -- so what is left to check is
# that the wiring is complete: every task is either delegated to or named, and
# the ones that are named fail instead of pretending to have done the work.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v make >/dev/null 2>&1; then
    skip "make: not installed"
    exit 0
fi

# -s: without it the recipe echoes itself onto stdout, ahead of the mapping.
assert_equal "make check agrees with mise run check" \
    "$(mise -q -C "$REPO" run check 2>/dev/null)" \
    "$(make -s -C "$REPO" check 2>/dev/null)"

assert_ok "make install succeeds" make -s -C "$REPO" install

# A task added to mise-tasks/ and forgotten here is the one way the two can
# still come apart.
unmentioned=
for script in "$REPO"/mise-tasks/*; do
    [ -x "$script" ] || continue
    name=${script##*/}

    if ! grep -q "^[a-z ]*\\b$name\\b" "$REPO/Makefile"; then
        unmentioned="$unmentioned $name"
    fi
done

if [ -z "$unmentioned" ]; then
    pass "every task is a Makefile target too"
else
    fail "every task is a Makefile target too" "missing:$unmentioned"
fi

for target in import test test-container; do
    output=$(make -s -C "$REPO" "$target" 2>&1 || true)

    case "$output" in
    *"mise run $target"*)
        pass "make $target names the mise task"
        ;;
    *)
        fail "make $target names the mise task" "$output"
        ;;
    esac

    if make -s -C "$REPO" "$target" >/dev/null 2>&1; then
        fail "make $target fails instead of pretending" "it succeeded"
    else
        pass "make $target fails instead of pretending"
    fi
done
