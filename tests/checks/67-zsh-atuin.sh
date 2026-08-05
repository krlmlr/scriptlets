#!/bin/sh
# Ctrl-R by way of atuin: the generated init script is written to a file and
# sourced from there, rewritten when atuin is upgraded, and missed by nobody
# where atuin is not installed.
#
# A stand-in `atuin` on the PATH does the talking. It counts its own runs and
# prints an init script that says it was loaded, which is all these checks
# need -- and it makes them say the same thing on a machine that has the real
# atuin and one that does not.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

standin=$HOME/.atuin-stand-in
runs=$standin/atuin-runs
cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/atuin-init.zsh

mkdir -p "$standin"
rm -f "$runs" "$cache" "$cache.zwc"

cat >"$standin/atuin" <<'EOF'
#!/bin/sh
# The arguments of every `atuin init`, one per line, and an init script that
# announces itself. `atuin uuid` is what the real init script asks for.
case $1 in
init)
    echo "$*" >>"$0-runs"
    echo 'ATUIN_STAND_IN_LOADED=1'
    ;;
uuid)
    echo 00000000-0000-0000-0000-000000000000
    ;;
esac
EOF

chmod +x "$standin/atuin"

# probe CODE -- what CODE prints in an interactive zsh that finds the stand-in
# first on its PATH. stderr is dropped for the reason given in
# 60-zsh-startup.sh: a system-wide zshrc with a compinit of its own is noisy.
probe() {
    env PATH="$standin:$PATH" zsh -ic "$1" 2>/dev/null |
        sed -n 's/^probe=//p' | tail -n 1
}

init_runs() {
    if [ -f "$runs" ]; then
        wc -l <"$runs" | tr -d ' '
    else
        echo 0
    fi
}

assert_equal "the first shell loads what atuin generated" \
    "1" "$(probe 'print "probe=$ATUIN_STAND_IN_LOADED"')"

assert_equal "and generated it with the up arrow left to zsh" \
    "init zsh --disable-up-arrow" "$(tail -n 1 "$runs" 2>&1)"

if [ -s "$cache" ]; then
    pass "the generated script is kept in a file"
else
    fail "the generated script is kept in a file" "no $cache"
fi

# Wordcode, which zsh reads in place of the script whenever it is the newer of
# the two.
if [ -s "$cache.zwc" ]; then
    pass "the file is compiled to wordcode"
else
    fail "the file is compiled to wordcode" "no $cache.zwc"
fi

before=$(init_runs)
probe 'true' >/dev/null
probe 'true' >/dev/null

assert_equal "later shells source the file instead of generating it again" \
    "$before" "$(init_runs)"

assert_equal "and still load it" \
    "1" "$(probe 'print "probe=$ATUIN_STAND_IN_LOADED"')"

# An upgrade is the one thing that changes what `atuin init` writes, and a
# binary newer than the file is how this notices.
touch "$standin/atuin"
probe 'true' >/dev/null

assert_equal "an atuin newer than the file makes the next shell rewrite it" \
    "$((before + 1))" "$(init_runs)"

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

rm -rf "$standin"
