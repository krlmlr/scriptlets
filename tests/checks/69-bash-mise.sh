#!/bin/sh
# mise's activation in bash, which is the zsh arrangement without the wordcode
# (tests/checks/68-zsh-mise.sh): the generated script is written to a file and
# sourced from there, rewritten unless the file is newer than the binary that
# generated it,
# named for that binary, never replaced by a broken one, and absent without
# complaint where mise is not on the PATH.
#
# The stand-in `mise` is the same idea as the zsh check's, printing bash rather
# than zsh; the real mise is on the PATH here and is deliberately not the one
# answering.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v bash >/dev/null 2>&1; then
    skip "bash: not installed"
    exit 0
fi

cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/bash
standin=$HOME/.mise-stand-in-bash

mkdir -p "$standin"

cat >"$standin/mise" <<'EOF'
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

chmod +x "$standin/mise"

cache=$cache_dir/mise-activate-$(printf '%s' "${standin#/}" | tr '/' '-')-mise.bash

rm -f "$cache"

# The shipped file is named rather than left to `bash -i` to find, because the
# throw-away home directory does not have it: rcm leaves a file the account
# already had alone, and on Ubuntu that is the ~/.bashrc seeded from /etc/skel
# until `mise run force` replaces it (tests/checks/90-force.sh). macOS seeds
# nothing, so an unnamed rcfile would make this check ask a different question
# on each platform. Where ~/.bashrc comes from is those checks'; what the file
# does once it is read is this one's.
#
# -i because the file returns at once unless the shell is interactive; the
# command still comes from -c.
rcfile=$REPO/rcm/bashrc

probe() {
    env PATH="$standin:$PATH" "$@" \
        bash --rcfile "$rcfile" -ic 'echo "probe=$MISE_STAND_IN_LOADED"' \
        2>/dev/null |
        sed -n 's/^probe=//p' | tail -n 1
}

runs() {
    if [ -f "$standin/mise-runs" ]; then
        wc -l <"$standin/mise-runs" | tr -d ' '
    else
        echo 0
    fi
}

strays() {
    ls "$cache_dir" 2>/dev/null | grep -c 'mise-activate-.*\.[0-9][0-9]*$' |
        tr -d ' '
}

assert_equal "the first shell loads what mise generated" "1" "$(probe)"

assert_equal "and generated it for bash" \
    "activate bash" "$(tail -n 1 "$standin/mise-runs" 2>&1)"

if [ -s "$cache" ]; then
    pass "the generated script is kept in a file named for the binary"
else
    fail "the generated script is kept in a file named for the binary" \
        "no $cache
$(ls -la "$cache_dir" 2>&1)"
fi

# The stand-in and the file it generates are written moments apart, and a shell
# that compares whole seconds cannot tell such a pair apart -- which the rule in
# the startup file reads as an upgrade. Dated into the past, the stand-in is
# unambiguously the older of the two, which is the case asked about here.
touch -t 202001010000 "$standin/mise"

before=$(runs)
probe >/dev/null
probe >/dev/null

assert_equal "later shells source the file instead of generating it again" \
    "$before" "$(runs)"

assert_equal "and still load it" "1" "$(probe)"

touch "$standin/mise"
probe >/dev/null

assert_equal "a mise newer than the file makes the next shell rewrite it" \
    "$((before + 1))" "$(runs)"

# And a mise the file cannot be told apart from counts as an upgrade too --
# same mtime to the second, which is all the comparison has on macOS. The
# other reading would leave such a pair stuck with the older script for good.
before=$(runs)
touch -r "$cache" "$standin/mise"
probe >/dev/null

assert_equal "so does one the file cannot be told apart from" \
    "$((before + 1))" "$(runs)"

for mode in empty truncated fail; do
    touch "$standin/mise"

    assert_equal "the working file survives a rewrite that comes back $mode" \
        "1" "$(probe "FAKE_MODE=$mode")"

    # Back to a known-good file, so the next mode is asked its own question
    # rather than inheriting what this one left behind.
    touch "$standin/mise"
    probe >/dev/null
done

assert_equal "and leaves no half-written files behind" "0" "$(strays)"

# tests/run will not start without a mise on the PATH, so the PATH is what this
# takes away: every entry that has one is dropped.
without=$(printf '%s' "$PATH" | tr ':' '\n' | while read -r dir; do
    [ -x "$dir/mise" ] || printf '%s:' "$dir"
done)

assert_equal "without mise, nothing is loaded" \
    "" "$(env PATH="$without" bash --rcfile "$rcfile" -ic \
        'echo "probe=$MISE_STAND_IN_LOADED"' 2>/dev/null |
        sed -n 's/^probe=//p' | tail -n 1)"

# A cache directory that cannot be made -- a regular file, because root may
# write to a directory nobody else may.
blocked=$HOME/.cache-is-a-file

: >"$blocked"

assert_equal "a cache that cannot be written costs the shell its mise" \
    "" "$(probe "XDG_CACHE_HOME=$blocked")"

noise=$(env PATH="$standin:$PATH" "XDG_CACHE_HOME=$blocked" \
    bash --rcfile "$rcfile" -ic true </dev/null 2>&1 >/dev/null |
    grep -F mise || true)

if [ -z "$noise" ]; then
    pass "and costs it nothing else -- nothing is said before the prompt"
else
    fail "and costs it nothing else -- nothing is said before the prompt" "$noise"
fi

rm -f "$blocked"
rm -rf "$standin"
