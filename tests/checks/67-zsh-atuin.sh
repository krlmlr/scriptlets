#!/bin/sh
# Ctrl-R by way of atuin: the generated init script is written to a file and
# sourced from there, rewritten when atuin or its configuration is newer than
# the file, never replaced by a broken one, and missed by nobody where atuin
# is not installed.
#
# A stand-in `atuin` on the PATH does the talking. It counts its own runs,
# prints an init script that says it was loaded, and can be told to fail the
# way the real one fails. The real atuin is not needed for any of that, and is
# not wanted: these checks would otherwise say different things on a machine
# that has it. The one case that does need the machine's own answer -- what
# happens with no atuin at all -- is skipped where there is one.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

standin=$HOME/.atuin-stand-in
runs=$standin/atuin-runs
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
cache=$cache_dir/atuin-init.zsh
config=$HOME/.atuin-config

mkdir -p "$standin" "$config/atuin"
rm -f "$runs" "$cache" "$cache.zwc"

# $FAKE_MODE picks the failure. `empty` is the real thing's behaviour when it
# finds its own paths broken: a complaint on stderr, nothing on stdout, and
# exit 0 -- which a check on the exit status alone would take for success.
cat >"$standin/atuin" <<'EOF'
#!/bin/sh
case $1 in
init)
    echo "$*" >>"$0-runs"
    case ${FAKE_MODE:-} in
    empty) exit 0 ;;
    truncated) printf 'ATUIN_STAND_IN_LOADED=1\nif [ ' ;;
    fail) exit 1 ;;
    *) echo 'ATUIN_STAND_IN_LOADED=1' ;;
    esac
    ;;
uuid)
    echo 00000000-0000-0000-0000-000000000000
    ;;
esac
EOF

chmod +x "$standin/atuin"

# probe [NAME=VALUE...] -- whether an interactive zsh that finds the stand-in
# first on its PATH ended up with the generated script loaded.
#
# $XDG_CONFIG_HOME is pointed at a directory of this check's own: the shell
# rewrites the cache when atuin's configuration file is newer than it, and a
# real ~/.config/atuin on the machine running the checks would make that
# happen -- or not -- for reasons that have nothing to do with the code.
probe() {
    env PATH="$standin:$PATH" "XDG_CONFIG_HOME=$config" "$@" \
        zsh -ic 'print "probe=$ATUIN_STAND_IN_LOADED"' 2>/dev/null |
        sed -n 's/^probe=//p' | tail -n 1
}

init_runs() {
    if [ -f "$runs" ]; then
        wc -l <"$runs" | tr -d ' '
    else
        echo 0
    fi
}

# Anything named for this shell rather than for the file it is building.
strays() {
    ls "$cache_dir" 2>/dev/null | grep -c 'atuin-init\.zsh\.[0-9]' | tr -d ' '
}

assert_equal "the first shell loads what atuin generated" \
    "1" "$(probe)"

assert_equal "and generated it with the up arrow left to zsh" \
    "init zsh --disable-up-arrow" "$(tail -n 1 "$runs" 2>&1)"

if [ -s "$cache" ]; then
    pass "the generated script is kept in a file"
else
    fail "the generated script is kept in a file" "no $cache"
fi

# Wordcode, which zsh reads in place of the script whenever it is not the
# older of the two. Written before either is renamed into place, so this
# ordering holds for every shell that looks, not just afterwards.
if [ -s "$cache.zwc" ] && [ ! "$cache" -nt "$cache.zwc" ]; then
    pass "the file is compiled to wordcode, and the wordcode is what gets read"
else
    fail "the file is compiled to wordcode, and the wordcode is what gets read" \
        "$(ls -l "$cache" "$cache.zwc" 2>&1)"
fi

before=$(init_runs)
probe >/dev/null
probe >/dev/null

assert_equal "later shells source the file instead of generating it again" \
    "$before" "$(init_runs)"

assert_equal "and still load it" "1" "$(probe)"

# An upgrade, and a change of configuration, are the two things that change
# what `atuin init` writes. Neither is visible in the file itself, so both are
# noticed by mtime.
touch "$standin/atuin"
probe >/dev/null

assert_equal "an atuin newer than the file makes the next shell rewrite it" \
    "$((before + 1))" "$(init_runs)"

before=$(init_runs)
touch "$config/atuin/config.toml"
probe >/dev/null

assert_equal "a newer configuration file does too" \
    "$((before + 1))" "$(init_runs)"

# ---------------------------------------------------------------------------
# A rewrite that goes wrong must leave the working file alone. `atuin init`
# exiting 0 with nothing to say is the real thing's answer to a broken
# configuration, and a write cut short is what a full disk or a signal leaves
# behind; replacing a good cache with either is a shell without a Ctrl-R, or
# a syntax error at every start, until someone works out why.
# ---------------------------------------------------------------------------
for mode in empty truncated fail; do
    touch "$standin/atuin"

    assert_equal "the working file survives a rewrite that comes back $mode" \
        "1" "$(probe "FAKE_MODE=$mode")"
done

assert_equal "and leaves no half-written files behind" "0" "$(strays)"

# The other half: no atuin, no section. Only checkable where the machine
# running the checks does not have one of its own.
if command -v atuin >/dev/null 2>&1; then
    skip "atuin is installed here, so its absence cannot be checked"
else
    assert_equal "without atuin, nothing is loaded" \
        "" "$(zsh -ic 'print "probe=$ATUIN_STAND_IN_LOADED"' 2>/dev/null |
            sed -n 's/^probe=//p' | tail -n 1)"

    noise=$(zsh -ilc true </dev/null 2>&1 >/dev/null | grep -F atuin || true)

    if [ -z "$noise" ]; then
        pass "without atuin, nothing is said about it either"
    else
        fail "without atuin, nothing is said about it either" "$noise"
    fi
fi

rm -rf "$standin" "$config"
