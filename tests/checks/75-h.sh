#!/bin/sh
# `h` runs the command in every repository it finds, and says so.
#
# The bug this pins was invisible: `h` collected the repositories, then ended
# on the first one it had to number, under its own `set -e`, printing nothing
# and exiting 1. Nothing distinguishes that from a directory with no
# repositories below it, which is why a check has to name the repositories it
# expects to hear back from.
#
# The tools `h` drives are not this repository's to install
# (`install/prerequisites/`), so the check builds the two links a Linux box
# needs -- the GNU commands are there under their plain names -- and skips
# where even those are missing.

set -u

. "$(dirname -- "$0")/../lib.sh"

PATH="$HOME/bin:$PATH"
export PATH

work=$HOME/h-check
rm -rf "$work"
mkdir -p "$work/shims" "$work/one" "$work/two"

# link_as NAME COMMAND... -- put NAME on the PATH, from the first COMMAND that
# exists. Returns non-zero when none does, which is the check's skip signal.
link_as() {
    _name=$1
    shift

    if command -v "$_name" >/dev/null 2>&1; then
        return 0
    fi

    for _candidate in "$@"; do
        _found=$(command -v "$_candidate" 2>/dev/null) || continue
        ln -sf "$_found" "$work/shims/$_name"
        return 0
    done

    return 1
}

missing=
# fd is fdfind on Debian and Ubuntu; gsed and gsort are what macOS calls the
# GNU commands Linux ships unprefixed.
link_as fd fdfind || missing="$missing fd"
link_as gsed sed || missing="$missing gsed"
link_as gsort sort || missing="$missing gsort"
command -v parallel >/dev/null 2>&1 || missing="$missing parallel"

if [ -n "$missing" ]; then
    skip "h: not installed:$missing"
    exit 0
fi

PATH="$work/shims:$PATH"
export PATH

git init -q "$work/one"
git init -q "$work/two"

output=$(cd "$work" && h --no-color echo scriptlets 2>&1)
status=$?

assert_equal "h succeeds where there are repositories" 0 "$status"

for repo in one two; do
    case $output in
    *"$repo: scriptlets"*)
        pass "h runs the command in $repo"
        ;;
    *)
        fail "h runs the command in $repo" "$output"
        ;;
    esac
done
