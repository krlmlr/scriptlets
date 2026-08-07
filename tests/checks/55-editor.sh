#!/bin/sh
# The editor every tool that asks for one is handed, and the zsh widget that
# hands it the command line
# (handbook/config/editor/README.md).
#
# The name of the editor is the smaller half of the claim. What a check can
# catch and a reading cannot is the `--wait`: `zed` without it gives the file
# to the window already open and returns at once, so `git commit` reads back
# the template it wrote and the widget reads back the line it sent -- silently,
# both of them. So the value is compared whole rather than searched for a
# `zed` in it.
#
# The check brings its own home directory, because the value is ~/.profile's
# and the throw-away home the other checks read has Ubuntu's: /etc/skel seeds
# one there and rcm leaves a file that already exists alone
# (tests/checks/30-preexisting.sh is where that behaviour is checked).
#
# The Zed command line is on neither CI runner and may well be on a developer
# machine, so both sides are arranged rather than waited for: a stub named
# `zed` is what puts one on the `PATH`, and the fallback is checked with the
# directory holding it taken away again -- except on a machine carrying a real
# one, which no `PATH` of ours can hide.

set -u

. "$(dirname -- "$0")/../lib.sh"

home=$(mktemp -d "${TMPDIR:-/tmp}/scriptlets-editor.XXXXXX")
stub=$home/stub-bin
mkdir -p "$stub"

# Never started by anything here: every shell below is asked what $EDITOR is,
# not to run it. Being found is all the guard in ~/.profile asks of it.
cat >"$stub/zed" <<'STUB'
#!/bin/sh
echo "zed $*"
STUB
chmod +x "$stub/zed"

(
    HOME=$home
    export HOME

    assert_ok "mise run install succeeds" mise -C "$REPO" run install

    # ~/.profile prepends to the PATH it inherits rather than building a new
    # one, so a directory put in front here is still in front inside the login
    # shell.
    PATH="$stub:$PATH"
    export PATH

    # The three shells a fresh account may log in with, as in the PATH check:
    # the value is set once, in ~/.profile, and bash and zsh have each their
    # own way of arriving there.
    for shell in sh bash zsh; do
        if ! command -v "$shell" >/dev/null 2>&1; then
            skip "$shell: not installed"
            continue
        fi

        assert_equal "$shell: EDITOR is Zed, told to wait" \
            "zed --wait" "$(login_output "$shell" 'printf %s "$EDITOR"')"

        # Not a second spelling of the assertion above: git and zsh's
        # edit-command-line both read $VISUAL first, so a $VISUAL left behind
        # is a $EDITOR ignored.
        assert_equal "$shell: VISUAL says the same" \
            "zed --wait" "$(login_output "$shell" 'printf %s "$VISUAL"')"
    done

    # `core.editor` is unset on purpose (rcm/gitconfig): git falls back to the
    # environment, and asking git itself is what shows the two ends meet.
    # $GIT_EDITOR is dropped rather than trusted -- it outranks both variables,
    # and the harness may well be running under a tool that exports it.
    assert_equal "git edits with what the login shell set" \
        "zed --wait" "$(login_output sh 'env -u GIT_EDITOR git var GIT_EDITOR')"

    if command -v zsh >/dev/null 2>&1; then
        # An interactive shell rather than a login one: the binding is
        # ~/.zshrc's. $ZDOTDIR is dropped so that a suite run from a terminal
        # that sets it still reads the file installed above.
        assert_equal "^X^E opens the command line in the editor" \
            '"^X^E" edit-command-line' \
            "$(env -u ZDOTDIR zsh -ic 'bindkey "^X^E"' 2>/dev/null | tail -n 1)"
    fi

    # --- the machine without Zed --------------------------------------------

    PATH=${PATH#"$stub:"}
    export PATH

    if command -v zed >/dev/null 2>&1; then
        skip "the fallback: this machine has a Zed command line of its own"
    else
        assert_equal "without Zed, EDITOR is vim" \
            "vim" "$(login_output sh 'printf %s "$EDITOR"')"
        assert_equal "without Zed, VISUAL is vim" \
            "vim" "$(login_output sh 'printf %s "$VISUAL"')"
    fi
)

rm -rf "$home"
