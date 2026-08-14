#!/bin/sh
# The R Makevars profiles and the dispatcher that picks between them
# (handbook/config/r-makevars/README.md).
#
# Against a home directory of this check's own, holding the repository's copy
# of the files: they are macOS-only, so reading the throw-away home would
# leave everything below unrun on the Linux CI runner -- where the make that
# parses them is the same make. What the throw-away home is asked is the one
# question that differs by platform, at the end.
#
# `make` answers what a profile resolves to, rather than a compiler running:
# Homebrew's LLVM and gcc-15 are on neither runner, and the question here is
# which flags a profile produces, not whether they compile.

set -u

. "$(dirname -- "$0")/../lib.sh"

src=$REPO/rcm/tag-macos/R

work=$HOME/r-makevars-check
rm -rf "$work"
mkdir -p "$work/.R"
cp "$src"/Makevars "$src"/Makevars.* "$work/.R/"

# The profiles, taken from the repository rather than listed here: a profile
# added without a line in this check would otherwise go untested. Makevars
# itself is the dispatcher, and Makevars.common is what every profile shares.
profiles=
for f in "$src"/Makevars.*; do
    name=${f##*/Makevars.}
    [ "$name" = common ] || profiles="$profiles $name"
done

cat >"$work/probe.mk" <<'EOF'
include $(HOME)/.R/Makevars
probe:
	@printf '%s|%s\n' '$(CC)' '$(CFLAGS)'
EOF

# probe [PROFILE] -- `CC|CFLAGS` as the dispatcher resolves them, with $status.
# No argument leaves R_MAKEVARS_PROFILE unset, which is not the same as empty.
probe() {
    if [ $# -eq 0 ]; then
        output=$(env -u R_MAKEVARS_PROFILE HOME="$work" \
            make -s -f "$work/probe.mk" probe 2>&1)
    else
        output=$(env HOME="$work" R_MAKEVARS_PROFILE="$1" \
            make -s -f "$work/probe.mk" probe 2>&1)
    fi
    status=$?
}

# --- every profile resolves -------------------------------------------------

unresolved=
for name in $profiles; do
    probe "$name"
    [ "$status" -eq 0 ] || unresolved="$unresolved $name"
done

if [ -z "$unresolved" ]; then
    pass "every profile beside the dispatcher resolves"
else
    fail "every profile beside the dispatcher resolves" "failed:$unresolved"
fi

# --- the default ------------------------------------------------------------

probe debug
debug=$output

probe
assert_equal "an unset R_MAKEVARS_PROFILE is debug" "$debug" "$output"

# `?=` would read an empty value as a choice and look for a file whose name
# stops at the dot.
probe ""
assert_equal "an empty R_MAKEVARS_PROFILE is debug too" "$debug" "$output"

# --- what a profile is for --------------------------------------------------

probe release
assert_match "release optimises" "*|*-O3*" "$output"
assert_match "and keeps the debug information" "*|*-g*" "$output"

probe gcc
assert_match "the gcc profile takes a compiler of its own" "ccache gcc-15|*" \
    "$output"
assert_match "and promotes the uninitialised warnings to errors" \
    "*|*-Werror=maybe-uninitialized*" "$output"

# -fpermissive is a C++ option, and GCC warns on every C file it is passed for.
case $output in
*-fpermissive*) fail "and keeps -fpermissive out of CFLAGS" "$output" ;;
*) pass "and keeps -fpermissive out of CFLAGS" ;;
esac

# The profile is about the compiler alone; its flags are debug's, included
# from the file that owns them.
probe llvm
assert_match "the llvm profile takes Homebrew's clang" \
    "ccache /opt/homebrew/opt/llvm/bin/clang|*" "$output"
assert_equal "and debug's flags, so the two cannot drift apart" \
    "${debug#*|}" "${output#*|}"

# --- ccache -----------------------------------------------------------------

# Simply expanded in Makevars.common, so it wraps whatever the profile chose --
# which is what makes the order of the two includes load-bearing.
probe gcc
assert_match "ccache wraps the compiler the profile chose" "ccache gcc-15|*" \
    "$output"

# --- a name with no file behind it ------------------------------------------

probe nosuchprofile
if [ "$status" -eq 0 ]; then
    fail "an unknown profile fails the build" "$output"
else
    pass "an unknown profile fails the build"
fi
assert_match "and the message names it" "*nosuchprofile*" "$output"

# --- what the platform decides ----------------------------------------------

# Everything above reads the repository. This is the throw-away home, and the
# tag is the whole point: the files name /opt/homebrew, and the ccache
# wrapping above would be a second one on Linux, where /usr/lib/ccache is
# already on the PATH (handbook/layout/tags/README.md).
if [ "$(uname -s)" = Darwin ]; then
    if [ -e "$HOME/.R/Makevars" ]; then
        pass "on macOS the dispatcher is installed"
    else
        fail "on macOS the dispatcher is installed" "no $HOME/.R/Makevars"
    fi
else
    if [ -e "$HOME/.R/Makevars" ]; then
        fail "off macOS nothing is installed" "$(ls -l "$HOME/.R/Makevars")"
    else
        pass "off macOS nothing is installed"
    fi
fi

rm -rf "$work"
