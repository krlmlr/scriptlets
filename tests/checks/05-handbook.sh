#!/bin/sh
# The handbook's mechanical shape (handbook/meta/handbook/README.md): every
# directory has a README.md, every subdirectory is in its parent's child list,
# every link resolves, and none climbs out of its directory with `..`.
# Whether a fact sits in the leaf that owns it stays judgment work; this
# check owns the shape.
#
# It reads the repository alone -- nothing here looks at the home directory
# the other checks install into, which is why it can run first.

set -u

. "$(dirname -- "$0")/../lib.sh"

# --- every directory has a README.md ---------------------------------------

missing=
for dir in $(find "$REPO/handbook" -type d | sort); do
    [ -f "$dir/README.md" ] || missing="$missing ${dir#$REPO/}"
done

if [ -z "$missing" ]; then
    pass "every handbook directory has a README.md"
else
    fail "every handbook directory has a README.md" "missing:$missing"
fi

# --- every page is tracked -------------------------------------------------

# A page that exists here but not in the repository passes every check below,
# because they all read the working tree: the links resolve, the child lists
# agree, and the tree looks whole. It is only missing for everyone else --
# a clone, a fresh checkout, CI -- where it fails as a dangling link, a long
# way from the page that was never added. `.gitignore` is enough to cause it.

untracked=
for page in $(find "$REPO/handbook" -name '*.md' | sort); do
    git -C "$REPO" ls-files --error-unmatch "$page" >/dev/null 2>&1 ||
        untracked="$untracked ${page#$REPO/}"
done

if [ -z "$untracked" ]; then
    pass "every handbook page is tracked by git"
else
    fail "every handbook page is tracked by git" "untracked:$untracked"
fi

# --- every subdirectory is in its parent's child list ----------------------

unlisted=
for dir in $(find "$REPO/handbook" -mindepth 1 -type d | sort); do
    parent=${dir%/*}
    name=${dir##*/}
    grep -qF "]($name/" "$parent/README.md" 2>/dev/null ||
        unlisted="$unlisted ${dir#$REPO/}"
done

if [ -z "$unlisted" ]; then
    pass "every subdirectory is in its parent's child list"
else
    fail "every subdirectory is in its parent's child list" "unlisted:$unlisted"
fi

# --- links resolve, and never climb ----------------------------------------

# Every page of the tree, plus the secondary documents that link into it.
files="$(find "$REPO/handbook" -name '*.md' | sort)
$REPO/README.md
$REPO/obsolete/README.md"

dangling=
upward=
for f in $files; do
    dir=${f%/*}
    for target in $(grep -o ']([^)]*)' "$f" | sed 's/^](//; s/)$//'); do
        case $target in
        http://* | https://* | mailto:*) continue ;;
        esac

        target=${target%%#*}
        [ -n "$target" ] || continue

        case $target in
        .. | ../* | */../* | */..)
            upward="$upward ${f#$REPO/}:$target"
            continue
            ;;
        esac

        case $target in
        /*) resolved="$REPO$target" ;;
        *) resolved="$dir/$target" ;;
        esac
        [ -e "$resolved" ] || dangling="$dangling ${f#$REPO/}:$target"
    done
done

if [ -z "$dangling" ]; then
    pass "every link resolves"
else
    fail "every link resolves" "dangling:$dangling"
fi

if [ -z "$upward" ]; then
    pass "no link climbs with .."
else
    fail "no link climbs with .." "upward:$upward"
fi
