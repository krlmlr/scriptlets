#!/bin/sh
# mise's activation in zsh: the generated script is written to a file and
# sourced from there, rewritten unless the file is newer than the binary that
# generated it, named for that binary, never replaced by a broken one, and missed
# by nobody where mise is not on the PATH.
#
# A stand-in `mise` on the PATH does the talking. It counts its own runs,
# prints an activation script that says it was loaded, and can be told to fail
# the way a rewrite fails. The real mise is not needed for any of that, and is
# not wanted: it is on the PATH here -- tests/run refuses to start without it
# -- so these checks would otherwise say different things depending on which
# mise answered.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh

# stand_in DIRECTORY -- a `mise` there that counts its runs beside itself.
#
# $FAKE_MODE picks the failure: nothing on stdout with a zero exit, a write cut
# short, or a non-zero exit. The first is the one a check on the exit status
# alone would take for success.
stand_in() {
    mkdir -p "$1"
    cat >"$1/mise" <<'EOF'
#!/bin/sh
case $1 in
activate)
    echo "$*" >>"$0-runs"
    case ${FAKE_MODE:-} in
    empty) exit 0 ;;
    truncated) printf 'if [ 1 = 1 ]; then\n  MISE_STAND_IN_LOADED=1\n' ;;
    fail) exit 1 ;;
    *) echo 'MISE_STAND_IN_LOADED=1' ;;
    esac
    ;;
esac
EOF
    chmod +x "$1/mise"
}

# cache_file BINARY -- the file ~/.zshrc names for the mise at BINARY.
cache_file() {
    printf '%s/mise-activate-%s.zsh\n' \
        "$cache_dir" "$(printf '%s' "${1#/}" | tr '/' '-')"
}

runs() {
    if [ -f "$1-runs" ]; then
        wc -l <"$1-runs" | tr -d ' '
    else
        echo 0
    fi
}

# Anything named for the shell that was building it rather than for the file.
strays() {
    ls "$cache_dir" 2>/dev/null | grep -c 'mise-activate-.*\.[0-9][0-9]*$' |
        tr -d ' '
}

standin=$HOME/.mise-stand-in
elsewhere=$HOME/.mise-stand-in-elsewhere

stand_in "$standin"
stand_in "$elsewhere"

cache=$(cache_file "$standin/mise")
other=$(cache_file "$elsewhere/mise")

rm -f "$cache" "$cache.zwc" "$other" "$other.zwc"

# probe DIRECTORY [NAME=VALUE...] -- whether an interactive zsh that finds the
# stand-in in DIRECTORY first on its PATH ended up with its script loaded.
probe() {
    _dir=$1
    shift
    env PATH="$_dir:$PATH" "$@" \
        zsh -ic 'print "probe=$MISE_STAND_IN_LOADED"' 2>/dev/null |
        sed -n 's/^probe=//p' | tail -n 1
}

assert_equal "the first shell loads what mise generated" \
    "1" "$(probe "$standin")"

assert_equal "and generated it for zsh" \
    "activate zsh" "$(tail -n 1 "$standin/mise-runs" 2>&1)"

if [ -s "$cache" ]; then
    pass "the generated script is kept in a file named for the binary"
else
    fail "the generated script is kept in a file named for the binary" \
        "no $cache
$(ls -la "$cache_dir" 2>&1)"
fi

# Wordcode, which zsh reads in place of the script whenever it is not the older
# of the two. Written before either is renamed into place, so the ordering
# holds for every shell that looks, not only once the dust has settled.
if [ -s "$cache.zwc" ] && [ ! "$cache" -nt "$cache.zwc" ]; then
    pass "the file is compiled to wordcode, and the wordcode is what gets read"
else
    fail "the file is compiled to wordcode, and the wordcode is what gets read" \
        "$(ls -l "$cache" "$cache.zwc" 2>&1)"
fi

# The stand-in and the file it generates are written moments apart, and a shell
# that compares whole seconds cannot tell such a pair apart -- which the rule in
# the startup file reads as an upgrade. Dated into the past, the stand-in is
# unambiguously the older of the two, which is the case asked about here.
touch -t 202001010000 "$standin/mise"

before=$(runs "$standin/mise")
probe "$standin" >/dev/null
probe "$standin" >/dev/null

assert_equal "later shells source the file instead of generating it again" \
    "$before" "$(runs "$standin/mise")"

assert_equal "and still load it" "1" "$(probe "$standin")"

# An upgrade is what changes the script, and it is not visible in the script
# itself, so it is noticed by mtime.
touch "$standin/mise"
probe "$standin" >/dev/null

assert_equal "a mise newer than the file makes the next shell rewrite it" \
    "$((before + 1))" "$(runs "$standin/mise")"

# And a mise the file cannot be told apart from counts as an upgrade too --
# same mtime to the second, which is all the comparison has on macOS. The
# other reading would leave such a pair stuck with the older script for good.
before=$(runs "$standin/mise")
touch -r "$cache" "$standin/mise"
probe "$standin" >/dev/null

assert_equal "so does one the file cannot be told apart from" \
    "$((before + 1))" "$(runs "$standin/mise")"

# ---------------------------------------------------------------------------
# A second mise at another path. The generated script calls its mise by
# absolute path, so a file generated from one of them is wrong for the other --
# it would keep calling the first, however the PATH has since been ordered.
# ---------------------------------------------------------------------------
before=$(runs "$standin/mise")
assert_equal "a mise at another path loads too" "1" "$(probe "$elsewhere")"

assert_equal "and generates a file of its own" \
    "1" "$(runs "$elsewhere/mise")"

assert_equal "leaving the first one's alone" \
    "$before" "$(runs "$standin/mise")"

if [ -s "$other" ] && [ -s "$cache" ]; then
    pass "both files are kept, one per binary"
else
    fail "both files are kept, one per binary" "$(ls -la "$cache_dir" 2>&1)"
fi

# ---------------------------------------------------------------------------
# A rewrite that goes wrong must leave the working file alone: replacing a good
# script with an empty or half-written one is a shell without mise, or a syntax
# error at every start, until someone works out why.
# ---------------------------------------------------------------------------
for mode in empty truncated fail; do
    touch "$standin/mise"

    assert_equal "the working file survives a rewrite that comes back $mode" \
        "1" "$(probe "$standin" "FAKE_MODE=$mode")"

    # Back to a known-good file, so the next mode is asked its own question
    # rather than inheriting what this one left behind.
    touch "$standin/mise"
    probe "$standin" >/dev/null
done

assert_equal "and leaves no half-written files behind" "0" "$(strays)"

# ---------------------------------------------------------------------------
# The other half: no mise, no section. tests/run will not start without a mise
# on the PATH, so the PATH is what this takes away -- every entry that has one
# is dropped, and everything else the startup files reach stays.
# ---------------------------------------------------------------------------
without=$(printf '%s' "$PATH" | tr ':' '\n' | while read -r dir; do
    [ -x "$dir/mise" ] || printf '%s:' "$dir"
done)

assert_equal "without mise, nothing is loaded" \
    "" "$(env PATH="$without" zsh -ic 'print "probe=$MISE_STAND_IN_LOADED"' \
        2>/dev/null | sed -n 's/^probe=//p' | tail -n 1)"

noise=$(env PATH="$without" zsh -ilc true </dev/null 2>&1 >/dev/null |
    grep -F mise || true)

if [ -z "$noise" ]; then
    pass "without mise, nothing is said about it either"
else
    fail "without mise, nothing is said about it either" "$noise"
fi

# ---------------------------------------------------------------------------
# A cache directory that cannot be made. Pointed at a regular file rather than
# at a directory nobody may write to, because these checks are run as root as
# often as not, and root may write to that one.
# ---------------------------------------------------------------------------
blocked=$HOME/.cache-is-a-file
: >"$blocked"

assert_equal "a cache that cannot be written costs the shell its mise" \
    "" "$(probe "$standin" "XDG_CACHE_HOME=$blocked")"

noise=$(env PATH="$standin:$PATH" "XDG_CACHE_HOME=$blocked" \
    zsh -ilc true </dev/null 2>&1 >/dev/null | grep -F mise || true)

if [ -z "$noise" ]; then
    pass "and costs it nothing else -- nothing is said before the prompt"
else
    fail "and costs it nothing else -- nothing is said before the prompt" "$noise"
fi

rm -f "$blocked"
rm -rf "$standin" "$elsewhere"
