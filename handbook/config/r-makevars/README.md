# R Makevars profiles

What R compiles packages with,
how the compiler and the flags are switched from one build to the next,
and what outranks the choice when a project has one of its own.
The rest of what `~/.Rprofile` sets is
[`config/files/`](/handbook/config/files/README.md)'s inventory entry.

**One file R reads, and all it does is choose.**
[`rcm/tag-macos/R/Makevars`](/rcm/tag-macos/R/Makevars)
installs as `~/.R/Makevars`,
the user Makevars R consults before every compile,
and it holds no flags of its own:
it reads the profile named by `$R_MAKEVARS_PROFILE`,
then [`Makevars.common`](/rcm/tag-macos/R/Makevars.common).

**Switching is an environment variable,
so nothing on disk changes and nothing is left switched.**
make imports the environment,
which is what lets one build differ from the next without an edit:

```sh
R_MAKEVARS_PROFILE=release R CMD INSTALL .
```

A session that never saw a login shell — RStudio, Positron,
anything started from the Dock — sets it from the R side instead,
and the make that R starts inherits it:

```r
Sys.setenv(R_MAKEVARS_PROFILE = "gcc")
```

Unset means `debug`, and so does empty:
`R_MAKEVARS_PROFILE=` is how a shell unsets a variable it has exported,
and reading that as a choice would send the dispatcher looking for a file
whose name stops at the dot.

**A profile is its difference from the others, and nothing else.**
`debug` and `release` choose flags and leave the compiler alone;
`gcc` and `llvm` reach for a compiler Homebrew installed.
Each file says at its head what it is for,
and [`Makevars.llvm`](/rcm/tag-macos/R/Makevars.llvm)
takes its flags by including
[`Makevars.debug`](/rcm/tag-macos/R/Makevars.debug)
rather than repeating them,
because the compiler is the whole of what it changes.
A new profile is a file beside those,
named for what it selects;
the check below finds it without being told.

**`Makevars.common` is read second, and that order is load-bearing.**
It holds what no profile varies —
the Homebrew include and library paths, gfortran, the linker, `-j8` —
and it wraps the compilers in ccache with `:=`,
which expands there and then.
Read first, it would wrap whatever R's own `Makeconf` had named
and the profile's choice would go unwrapped and uncached.

**A name with no file behind it stops the build.**
`$(error)` rather than silence,
because a profile that quietly resolved to nothing
would compile with none of the flags above
and produce a working package with no sign of what it was built with.

**A project's own `Makevars` outranks every word of this.**
`check_local_env` in [`rcm/Rprofile`](/rcm/Rprofile)
points `$R_MAKEVARS_USER` at a `Makevars` it finds beside or above a project,
and R consults that *instead of* `~/.R/Makevars` —
not in addition to it.
Such a project therefore compiles without ccache
and without the Homebrew paths
unless its file includes `$(HOME)/.R/Makevars` itself.

**Two more names outrank it, and both fail quietly.**
R reads `~/.R/Makevars-$R_PLATFORM` ahead of `~/.R/Makevars`
and never mentions doing so,
so a file left behind under the platform's own name shadows all of this.
And `$R_MAKEVARS_USER` naming a file that does not exist
leaves R using no user Makevars at all,
rather than falling back to `~/.R/Makevars`.

**macOS alone, and not only for the paths.**
Every profile names `/opt/homebrew`,
which settles it on its own
([`layout/tags/`](/handbook/layout/tags/README.md)),
but the ccache wrapping is the sharper reason:
on Linux `/usr/lib/ccache` is already on the `PATH`,
so `gcc` is ccache there and wrapping it again would nest one in another.

**The check reads the repository, not the home directory.**
[`tests/checks/80-r-makevars.sh`](/tests/checks/80-r-makevars.sh)
parses every profile with `make` on both CI runners —
the files are macOS's, the make that reads them is not —
and pins what each one is for,
that the default holds, that ccache wraps the profile's own compiler,
and that an unknown name fails.
It asks the throw-away home one question only,
the one whose answer differs by platform:
whether the dispatcher was installed
([`testing/`](/handbook/testing/README.md)).
