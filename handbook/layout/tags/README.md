# Tags

Files that install for one account, one platform, or one host only.
Everything portable stays shared,
including code that already adapts at runtime —
`fsed` prefers `gsed` over `sed`,
`rh` prefers `RStudio.app` over `rstudio`,
and `~/.bashrc` extends the `PATH` only when `/opt/homebrew` exists.

## Per user

A `tag-<NAME>/` directory holds files for one account:
[`rcm/tag-kirill/scriptlets/gitconfig`](/rcm/tag-kirill/scriptlets/gitconfig)
installs to `~/scriptlets/gitconfig`.

[`rcm/rcrc`](/rcm/rcrc) is sourced as shell,
so it selects the tag itself:

```sh
TAGS="$(id -un) $OS_TAG"
```

An account with no matching `tag-` directory installs nothing extra.
The name comes from `id -un` rather than `$USER`,
so selection also works where `$USER` is unset,
such as launchd jobs and some non-interactive sessions.
Tags are not limited to user names:
`rcup -t work` selects a `tag-work/` directory
*instead of* both of these,
and a `host-<hostname>/` directory is picked up automatically
like a tag.

The three files under `~/scriptlets/` are read by the configuration
that ships here —
[`rcm/gitconfig`](/rcm/gitconfig) includes `scriptlets/gitconfig`,
[`rcm/ssh/config`](/rcm/ssh/config) includes `~/scriptlets/ssh-config`,
and [`rcm/Rprofile`](/rcm/Rprofile) sources `~/scriptlets/Rprofile`
if it exists.
Each tolerates the file being absent,
which is why an unknown account needs no tag directory.
`~/scriptlets/zsh-startup`, read the same way by the startup profiler
([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md)),
is not shipped for any account —
it is per machine, like `~/.bash_secrets`.

## Per platform

Files that only work on one operating system live in
[`rcm/tag-macos/`](/rcm/tag-macos) or
[`rcm/tag-linux/`](/rcm/tag-linux),
and are installed nowhere else.
`rcrc` picks the platform tag from `uname -s`:

```sh
case "$(uname -s)" in
  Darwin) OS_TAG="macos" ;;
  Linux) OS_TAG="linux" ;;
  *) OS_TAG="" ;;
esac
```

A system that is neither gets no platform tag,
and therefore only the shared files.
Windows is out of scope.

| macOS only | Linux only |
| --- | --- |
| `finicky.js` — browser picker, macOS-only app | `toprc` — `top`'s Linux configuration format |
| `bin/n`, `bin/bkg` — notify via `terminal-notifier` | `screenrc-xpra` — starts an xpra X11 session |
| `bin/soffice-macos` — drives `/Applications/LibreOffice.app` | |
| `bash_aliases_os` — `csv`/`csv2`/`tsv`, `bit` completion | `bash_aliases_os` — `pxc`, `xo`, the `xclip` key bindings, `/usr/lib/ccache` |

The shared [`rcm/bash_aliases`](/rcm/bash_aliases) sources
`~/.bash_aliases_os` if it exists,
so each platform picks up its own aliases and nothing else.
`rcm/tag-macos/screenrc-xpra` is a placeholder:
`~/.screenrc` sources `.screenrc-xpra` unconditionally,
and screen complains about a missing file.

A file that moves into a tag directory
strands its old link on every account the tag excludes;
the sweep for those is
[`layout/mapping/`](/handbook/layout/mapping/README.md)'s.
