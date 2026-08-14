#!/bin/sh
# The working directory ~/.zshrc reports to the terminal: the right URL, from
# both of the hooks that send it, and only where something else is not already
# reporting it.
#
# The encoding is what earns a check. A file URL is ASCII and a path is bytes,
# so every path outside the unreserved set has to be percent-encoded, and a
# reader turns those hex pairs straight back into bytes -- encoding a
# character's code point instead would be wrong in exactly the places nobody
# tests by hand, and right everywhere else.

set -u

. "$(dirname -- "$0")/../lib.sh"

if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh: not installed"
    exit 0
fi

# reports INPUT -- the working-directory reports an interactive zsh sends
# while running INPUT, one per line, with everything else dropped.
#
# The same shape as the prompt-mark checks next door: an interactive zsh
# reading a pipe runs the hooks around every command and prints no prompt to
# get in the way. cat -v first so a sequence is ordinary text; the reports are
# then the only thing on the line that can start with ^[]7;, since a path
# arrives percent-encoded and cannot carry a ^ of its own.
reports() {
    printf '%s' "$1" |
        env -u ZDOTDIR TERM_PROGRAM= TMUX= zsh -i 2>/dev/null |
        cat -v | grep -o '\^\[]7;[^^]*\^G'
}

# The host half of the URL comes from zsh's own $HOST, which is what makes a
# directory on this machine distinguishable from one behind an ssh. Asking the
# shell for it beats spelling it here: `hostname` and $HOST disagree on
# machines that carry a domain.
host=$(env -u ZDOTDIR zsh -ic 'print -rn -- $HOST' 2>/dev/null)

# A directory whose name needs the encoding: a space is reserved, and 日 is
# three bytes that a code-point encoder would send as one. It is matched
# rather than compared because the throw-away home lives under $TMPDIR, whose
# spelling on macOS carries characters of its own to encode.
mkdir -p "$HOME/osc7 日"

assert_match "the working directory is reported as a file URL naming the host" \
    "*]7;file://$host/*/osc7%20%E6%97%A5^G" \
    "$(reports 'cd "$HOME/osc7 日"
' | tail -n 1)"

# Both hooks, counted rather than named: chpwd reports the change as it
# happens -- which is what leaves the terminal pointing at the new directory
# for however long the rest of the command line runs -- and precmd reports it
# again at the prompt that follows. A cd therefore produces two reports of
# where it arrived, on top of the one for where it started.
assert_equal "a change of directory is reported when it happens and again at the next prompt" \
    "3" \
    "$(reports 'cd "$HOME/osc7 日"
' | wc -l | tr -d ' ')"

# ---------------------------------------------------------------------------
# Ghostty reports the directory itself, in kitty's kitty-shell-cwd:// scheme,
# from an integration it injects into the first shell alone -- so the guard
# asks whether that integration is in *this* shell rather than whether this is
# a Ghostty window, exactly as the prompt marks do.
# ---------------------------------------------------------------------------
ghostty=$HOME/.ghostty-stand-in
mkdir -p "$ghostty"

cat >"$ghostty/.zshenv" <<'EOF'
precmd_functions+=(_ghostty_deferred_init)
ZDOTDIR=$HOME
[[ -r $HOME/.zshenv ]] && source $HOME/.zshenv
EOF

assert_equal "where Ghostty's integration is loaded, the directory is left to it" \
    "0" \
    "$(printf 'true\n' |
        env -u ZDOTDIR TERM_PROGRAM=ghostty TMUX= ZDOTDIR="$ghostty" zsh -i 2>/dev/null |
        cat -v | grep -c ']7;' || true)"

assert_equal "a shell started inside that one reports for itself" \
    "1" \
    "$(env -u ZDOTDIR TERM_PROGRAM=ghostty TMUX= zsh -ic \
        'print "probe=${+functions[_osc7_report_cwd]}"' 2>/dev/null |
        sed -n 's/^probe=//p' | tail -n 1)"

rm -rf "$ghostty" "$HOME/osc7 日"
