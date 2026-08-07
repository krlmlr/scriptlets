# Where Positron's command line tool is, and where this repository links it.
#
# handbook/install/hooks/README.md
#
# Sourced by the hooks in post-up/ and pre-down/, and deliberately not
# executable: rcm runs every executable file below hooks/post-up and
# hooks/pre-down, and this file is not one of them.

# Positron ships its command line tool under the name VS Code gives it, inside
# the bundle, where it cannot be renamed. `positron` is that name taken out of
# the way of a `code` that may be VS Code's.
link=$HOME/bin/positron

# The bundle. A per-user install is looked at first, being the more specific of
# the two places macOS puts an application; SCRIPTLETS_POSITRON_APP names one
# bundle instead of both, and is how the check drives these hooks.
positron_cli() {
    if [ -n "${SCRIPTLETS_POSITRON_APP:-}" ]; then
        _positron_cli_in "$SCRIPTLETS_POSITRON_APP"
    else
        _positron_cli_in "$HOME/Applications/Positron.app" /Applications/Positron.app
    fi
}

# _positron_cli_in BUNDLE... -- the first tool that is there, or nothing.
_positron_cli_in() {
    for _app do
        _cli=$_app/Contents/Resources/app/bin/code
        if [ -x "$_cli" ]; then
            printf '%s\n' "$_cli"
            return 0
        fi
    done
    return 1
}

# Whether $link is one of ours: a symbolic link into a Positron.app, rather
# than a file the account put there under a name we happen to want.
positron_link_is_ours() {
    [ -L "$link" ] || return 1

    case $(readlink "$link") in
    */Positron.app/Contents/Resources/app/bin/code) return 0 ;;
    esac

    return 1
}
