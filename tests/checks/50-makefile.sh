#!/bin/sh
# The Makefile is the fallback for a machine without mise, so it has to agree
# with the tasks it stands in for -- two implementations of `rcup -d` are two
# things that can drift apart.
#
# Only the one-line targets are duplicated there. The rest name the mise task
# and fail, which is also checked here: a fallback that quietly does nothing,
# or does something different, is worse than one that points at the real thing.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v make >/dev/null 2>&1; then
    skip "make: not installed"
    exit 0
fi

# -s: without it the recipe echoes itself onto stdout, ahead of the mapping.
assert_equal "make check agrees with mise run check" \
    "$(mise -C "$REPO" run check 2>/dev/null)" \
    "$(make -s -C "$REPO" check 2>/dev/null)"

assert_ok "make install succeeds" make -s -C "$REPO" install

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
