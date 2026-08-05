# Bootstrap

One-shot setup on a machine that has nothing here yet:

```sh
curl -s https://raw.githubusercontent.com/krlmlr/scriptlets/main/bootstrap | sh
```

[`bootstrap`](/bootstrap) requires `rcup`, and either `mise` or `make`
([`install/prerequisites/`](/handbook/install/prerequisites/README.md)).
It **deletes any existing `~/git/scriptlets`**,
clones the repository there —
the one location where a bare `rcup` or `lsrc` also works
([`layout/mapping/`](/handbook/layout/mapping/README.md)) —
and installs:
trusting the clone and running `mise run install` where there is mise,
`make install` where there is not.

Piped from `curl`, stdin is the download, not the terminal,
so the script reconnects stdin to `/dev/tty` where one can be opened:
rcm's replace-or-keep prompts still reach you,
and the script prints a legend before they start.
Where no terminal can be opened — containers, CI, cron —
the prompts hit end of file
and every conflicting file is kept as it is.
