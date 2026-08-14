# The configuration files

What lands in the home directory besides the scripts in `~/bin`,
and what each file is for.
The naming rules that turn `rcm/bashrc` into `~/.bashrc` are
[`layout/mapping/`](/handbook/layout/mapping/README.md)'s.

| File | Installed as | |
| --- | --- | --- |
| [`rcrc`](/rcm/rcrc) | `~/.rcrc` | drives the mapping itself |
| [`profile`](/rcm/profile), [`zprofile`](/rcm/zprofile) | `~/.profile`, `~/.zprofile` | login shells of any kind: `~/bin` and `~/.local/bin` on the `PATH` ([`layout/path/`](/handbook/layout/path/README.md)), and the [editor](/handbook/config/editor/README.md) every tool is handed |
| [`bashrc`](/rcm/bashrc), [`bash_profile`](/rcm/bash_profile), [`bash_aliases`](/rcm/bash_aliases) | `~/.bashrc`, `~/.bash_profile`, `~/.bash_aliases` | interactive bash: prompt, history, aliases, [mise](/handbook/config/mise/README.md) |
| [`tag-macos/bash_aliases_os`](/rcm/tag-macos/bash_aliases_os), [`tag-linux/bash_aliases_os`](/rcm/tag-linux/bash_aliases_os) | `~/.bash_aliases_os` | the aliases, completions and bindings of one platform, sourced from `~/.bash_aliases` |
| [`zshenv`](/rcm/zshenv), [`zshrc`](/rcm/zshrc) | `~/.zshenv`, `~/.zshrc` | zsh: the startup profiler for every shell, completion, history, mise, [prompt marks](/handbook/config/prompt-marks/README.md) and the [working directory](/handbook/config/current-directory/README.md) for the interactive ones |
| [`zsh-startup-profile.zsh`](/rcm/zsh-startup-profile.zsh) | `~/.zsh-startup-profile.zsh` | times every interactive zsh startup ([`config/zsh-startup/`](/handbook/config/zsh-startup/README.md)) |
| [`autoscreen`](/rcm/autoscreen) | `~/.autoscreen` | drop into `screen` automatically on an interactive SSH login |
| [`gitconfig`](/rcm/gitconfig), [`gitaliases`](/rcm/gitaliases) | `~/.gitconfig`, `~/.gitaliases` | Git settings and aliases, whose names are [`config/git-aliases/`](/handbook/config/git-aliases/README.md)'s; pulls in several optional `~/.gitconfig.*` includes |
| [`gitignore`](/rcm/gitignore) | `~/.gitignore` | global excludes, wired up via `core.excludesfile` |
| [`ssh/config`](/rcm/ssh/config) | `~/.ssh/config` | keep-alives plus `Include`s for Colima, OrbStack and the per-user overrides |
| [`Rprofile`](/rcm/Rprofile) | `~/.Rprofile` | R defaults: CRAN mirror selection, `usethis`/`testthat`/`pillar` options, per-project `.lib` and `Makevars` hooks |
| [`air.toml`](/rcm/air.toml) | `~/air.toml` | fallback config for the `air` R formatter — formats nothing unless a project overrides it |
| [`editorconfig`](/rcm/editorconfig) | `~/.editorconfig` | indentation defaults |
| [`vimrc`](/rcm/vimrc), [`tigrc`](/rcm/tigrc) | `~/.vimrc`, `~/.tigrc` | vim and tig |
| [`log/dummy`](/rcm/log/dummy) | `~/log/dummy` | placeholder that brings `~/log` into existence |
| [`tag-linux/toprc`](/rcm/tag-linux/toprc) | `~/.toprc` | top; the format is the Linux one, so it installs there only |
| [`screenrc`](/rcm/screenrc), [`tag-linux/screenrc-xpra`](/rcm/tag-linux/screenrc-xpra) | `~/.screenrc`, `~/.screenrc-xpra` | GNU screen; the second starts an `xpra` server in a window on Linux, and is a placeholder on macOS |
| [`config/diffuse/diffuserc`](/rcm/config/diffuse/diffuserc) | `~/.config/diffuse/diffuserc` | dark colour scheme for the Diffuse merge tool |
| [`tag-macos/homebrew/brew.env`](/rcm/tag-macos/homebrew/brew.env) | `~/.homebrew/brew.env` | Homebrew's own environment file: how stale an index it tolerates, and that it may install dependencies unasked; macOS only |
| [`tag-macos/finicky.js`](/rcm/tag-macos/finicky.js) | `~/.finicky.js` | per-URL browser routing via Finicky; macOS only |
| [`git/R/`](/rcm/git/R) | `~/git/R/` | CMake and build helpers for working on the R sources in CLion |

The `tag-` prefixes select an account or a platform
([`layout/tags/`](/handbook/layout/tags/README.md));
the per-account files under `~/scriptlets/` are that page's too.

**Several of these include a file this repository does not ship**,
each guarded so that its absence is not an error:
that is where a private sidecar repository plugs in, and which include
serves which is [`layout/private/`](/handbook/layout/private/README.md)'s.

**Some of these lean on what the repository does not ship.**
`~/.bashrc` sources `~/git/bash-git-prompt/gitprompt.sh` and
`~/git/complete-alias/complete_alias`
without guarding for their absence,
so a fresh bash reports errors
until the two clones exist or the lines are removed.
`~/.bash_secrets` used to be among them,
and is now sourced by `~/.bash_aliases` only if it is there:
it is the one of the three that a machine may legitimately never need,
and the error was reaching zsh as well,
which reads `~/.bash_aliases` through `~/.zshrc`.
