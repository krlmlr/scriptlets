# The Git aliases

How the names in [`rcm/gitaliases`](/rcm/gitaliases) are chosen,
and the shape they make together.
The file is the list — what each alias expands to is read there —
and this page owns what the file cannot say about itself:
why a name is the name it is, and where a new one goes.
Which file lands where is
[`config/files/`](/handbook/config/files/README.md)'s.

## How a name is built

**The letters spell the command, then the variant.**
A command that is typed daily takes a letter, its variants take a second,
and a variant of a variant takes a third:
`b` is `branch`, `bv` adds `-v`, `bvv` adds the second one.
The push family carries it furthest, and is worth learning as a scheme:
`p` and then the variant — `h` plain, `f` for `--force-with-lease`,
`t` for `--follow-tags`, `u` for `--set-upstream` —
and then, where a third letter follows, the remote the current branch
goes to: `c` for cynkra, `o` for origin, `u` for upstream,
`k` for krlmlr where an account has one.
`puo` is therefore `push --set-upstream origin HEAD`, read left to right.

**A name takes git's own abbreviation where git has one.**
`wt` is `worktree` because git spells the concept as two words itself,
in `--work-tree` and `GIT_WORK_TREE`,
so the two letters are the initials of the thing
rather than a squeeze of one word.

**A command whose initial is taken reads on for a free letter.**
`v` is `revert` because `rebase` holds the `r` and `restore` the `e`:
the name is the first letter of the word that nothing else had claimed,
which is how `switch` came to be `w` and `restore` itself `e`.

**A name that borrows an occupied prefix is not a variant of it.**
`conflicts` begins with the letters of `checkout` and is a `diff`;
the stash sits under the letter `status` holds.
Git resolves an alias name in full and never by prefix,
and nothing in [`rcm/gitconfig`](/rcm/gitconfig) sets `help.autocorrect`,
the one mechanism that could turn a near-miss into the other command,
so such a name costs nothing at the keyboard —
it costs on the page, which is why the trie below lifts each one
out of the family whose prefix it borrowed
and gives it a group of its own.

**A renamed spelling warns and forwards rather than vanishing.**
`sq`, `fft`, `phuc`, `phuo` and `prm` are the names their replacements used
to have:
each prints one line to stderr and runs the new one,
so fingers that learned the old spelling are corrected rather than stopped.
`qs` took `sq`'s work because a squash is a `reset --soft` that ends in a
commit, and belongs to the reset family rather than under `status`;
`ff` took `fft`'s because the fast-forward became a script that reaches
the branches a worktree holds ([`tools/`](/handbook/tools/README.md));
`pr` took `prm`'s because the script it stands for opens against the
default branch already.

**A destructive variant keeps its long spelling.**
`q --hard`, `b -d`, `b -D`, `clean` and `rm` appear in the file as comments
rather than as aliases:
they are named so that nobody wonders whether they were forgotten,
and left unaliased so that they stay two seconds slower to type than the
recoverable ones.
The `v` family is the recoverable undo, and keeps its short names:
a revert is an ordinary commit on top,
so it undoes published work without rewriting any of it,
and is itself undone by reverting it.

**A name a script already answers to gets no alias.**
A `git-<name>` on the `PATH` wins over an alias that spells it,
so an alias beside the script would never run —
`git pr` is [`tools/`](/handbook/tools/README.md)'s script, not a name here,
and `pra` is an alias only because it adds an option to it.

**Plain expansions beat shell expansions where there is a choice.**
Git's completion expands an alias to its first command word,
so `git wt <TAB>` offers the `worktree` subcommands;
an alias that begins with `!` gets no completion at all,
and is marked as such in the trie so the cost is visible.
A plain expansion can lose it too:
completion walks the expansion a word at a time,
so a `-c` whose value carries a space — `dt`'s does, to keep its colour —
leaves it holding the tail of that value rather than the command.

## What the longer expansions do

Most expansions are their own explanation.
These are the ones that are not, and the file points here for them.

**`dz` opens the whole diff in Zed, and takes edits back.**
`--dir-diff` hands the tool both trees in one call rather than a pair of
files at a time, and `zed --diff` recurses into two directories and shows
every changed file in a single multi-diff view.
`--no-symlinks` is what makes that work:
the right-hand tree is symlinks into the working tree otherwise,
and the walk behind `--diff` steps over those,
leaving every file looking deleted.
It waits where `dm` backgrounds,
because git takes the trees down when the tool exits —
and copies whatever was edited on the right back into the working tree
first.
Its arguments are `git diff`'s, so `git dz HEAD^!` is `dmh`'s view.

**`dzm` is the same against the branch this one grew out of.**
It takes the merge base rather than `main...`,
and that is the whole of it:
git copies edits back only from the side that *is* the working tree,
so naming two sides — which `main...` does, expanding to `main...HEAD` —
makes both of them temporary copies and discards what was typed.
One side named leaves the working tree as the other,
and the merge base puts the fork point opposite it,
which is what `main...` was reaching for.
Uncommitted work is in the view as well, which is the point.
The branch is the remote's own default,
read from `refs/remotes/upstream/HEAD` and then `refs/remotes/origin/HEAD`
— `git remote set-head origin --auto` is what writes those down —
with `main` where neither says, and an argument overriding all of it.

**`dt` diffs with difftastic**, which compares syntax trees rather than
lines, and so tells a brace that moved from a line that changed.
It sets `diff.external` for the one invocation rather than as a setting,
so `git diff` stays what it was.
`--color always` is not decoration:
git hands an external diff to the pager,
and a difft that sees a pipe rather than a terminal turns its colour off,
while the `less -FRX` in [`rcm/gitconfig`](/rcm/gitconfig) passes the
escapes through.
That space inside the value is what costs the alias its completion,
above.
Where `difft` is not installed the alias says so and stops
([`install/prerequisites/`](/handbook/install/prerequisites/README.md)).

**`vm` reverts a merge, from the side it was merged into.**
Git refuses a merge commit without `--mainline`,
because two parents leave nothing to say
which of them the tree goes back to.
`1` is the side that was already there,
so the alias undoes what came in and keeps what it came into;
any other number is rare enough to spell out.
What the revert commit records is that the merged branch is merged *and*
undone, so merging it again brings nothing back:
the way back is to revert the revert.

**`vn` stages a revert without committing it**,
which is how several of them become one commit —
`git vn A..B`, and then a single commit of the lot.
Git prepares a message as it goes and each revert overwrites the one
before, so what is left names a single commit of the range —
the oldest, because a revert walks newest first.
The message for the whole range is written rather than accepted.

**`wtb` puts a worktree beside the repository it belongs to**, named for
both: `~/git/repo` and `branch-name` make `~/git/repo-branch-name`.
The name comes from the main worktree rather than the current one,
so a run from inside a linked worktree is a sibling rather than a nest,
and a slash in the branch name folds to a dash for the same reason.
A branch that already exists, here or on exactly one remote, is checked
out — git's own guessing sets the tracking branch up —
and a name that is neither becomes a new branch.

## The trie

Every alias, by the letters that reach it.
One alphabetical run, in which a name that heads a group of its own
comes before the family whose letter it borrowed —
`dm` before `d`, `conflicts` before `c` —
so a group is read before the family it would be taken for a variant of.
`*` is an alias, `!` one that expands to a shell command,
and `.` a node no alias stops at — a prefix that only leads somewhere.
A shell command is shown 60 characters deep, an ellipsis where the file
takes over; the `!` is the mark rather than part of what runs.

This block is generated by [`tests/git-aliases-trie`](/tests/git-aliases-trie)
and pinned by the `07-git-aliases` check
([`testing/`](/handbook/testing/README.md)),
so an alias that arrives without it fails the run.

```text
a * add
├─a * add .
├─c * commit --all --verbose
│  └─m * commit --all --message
└─p * add --patch

b * branch --sort=committerdate
├─m * branch --sort=committerdate --merged
├─n * branch --sort=committerdate --no-merged
└─v * branch -v --sort=committerdate
   └─v * branch -vv --sort=committerdate

conflicts * diff --name-only --diff-filter=U

c .
├─h * cherry-pick
│  ├─a * cherry-pick --abort
│  ├─c * cherry-pick --continue
│  └─s * cherry-pick --skip
├─i * commit -v
│  ├─a * commit --amend -v
│  │  └─o * commit --amend --no-edit
│  ├─f ! sh -c 'git commit --fixup=$1' -
│  ├─m * commit --message
│  │  └─s ! sh -c 'git commit --message "$0 [ci skip]" "$@"'
│  ├─o * commit --no-edit
│  └─r ! sh -c 'git commit --reuse-message=${1:-HEAD}' -
└─o * checkout
   ├─a * checkout -- .
   ├─b * checkout -b
   └─p * checkout --patch

dm ! sh -c 'diffuse -m $@ &' -
└─h ! sh -c 'diffuse -c HEAD &' -

d * diff
├─c * diff --cached
│  └─w * diff --cached --word-diff
├─d ! sh -c 'git diff | delta --max-line-length 2048 --navigate'
├─t * -c diff.external='difft --color always' diff
├─u * diff @{u}
├─w * diff --word-diff
└─z * difftool --dir-diff --no-symlinks --tool=zed
   └─m ! f() { b=${1:-$(git symbolic-ref --short refs/remotes/upstrea…

echo ! bash -c 'echo "${@: 0}"'

e * restore

fft ! echo 'warning: fft is now ff' >&2; git ff

f * fetch --prune
└─a * fetch --all --prune -j 32

lsf ! f() { if [ ${GIT_PREFIX} != ${PWD} ]; then cd ${GIT_PREFIX};…

l * log --numstat --graph --decorate
├─1 * log --oneline --decorate
├─a * log --all --numstat --graph --decorate
├─f * log --numstat --first-parent --graph --decorate
│  └─p * log --patch -m --first-parent --graph --decorate
├─l * log --oneline --graph --decorate
└─p * log --patch --graph --decorate

mu * merge-update

m * merge
├─a * merge --abort
├─f * merge --ff
├─o * merge --no-edit
└─s * merge --squash --ff
   └─o ! sh -c 'git merge --squash --ff "$0" "$@" && git commit --no-…

pr .
├─a * pr --auto-merge
└─m ! echo 'warning: prm is now pr' >&2; git pr

p .
├─f * push --force-with-lease
├─h * push
│  ├─c * push cynkra HEAD
│  ├─o * push origin HEAD
│  └─u * push upstream HEAD
│     ├─c ! echo 'warning: phuc is now puc' >&2; git puc
│     └─o ! echo 'warning: phuo is now puo' >&2; git puo
├─l * pull
│  ├─f * pull --ff-only
│  └─r * pull --rebase
├─t * push --follow-tags
└─u * push --set-upstream
   ├─c * push --set-upstream cynkra HEAD
   ├─o * push --set-upstream origin HEAD
   └─u * push --set-upstream upstream HEAD

q * reset
├─h * reset HEAD
│  └─p * reset HEAD^
├─s ! sh -c 'git reset --soft ${1:-main} && git commit --edit -m "…
└─u * reset @{u}

r * rebase
├─a * rebase --abort
├─c * rebase --continue
├─i * rebase --interactive --autosquash
├─m .
│  ├─a * rebase main
│  └─i * rebase main --interactive --autosquash
├─p * rebase --preserve-merges
└─s * rebase --skip

sq ! echo 'warning: sq is now qs' >&2; git qs

st .
├─d * stash drop
├─l * stash list
├─p * stash pop
└─s * stash save

s * status
└─p * status --porcelain

v * revert
├─a * revert --abort
├─c * revert --continue
├─h * revert HEAD
├─m * revert --mainline 1
├─n * revert --no-commit
├─o * revert --no-edit
└─s * revert --skip

wt * worktree
├─a * worktree add
├─b ! f() { r=$(git worktree list --porcelain | sed -n '1s/^worktr…
├─l * worktree list
├─m * worktree move
├─p * worktree prune
└─r * worktree remove

w * switch
```

## What the trie is for

**A free letter is visible**, and so is a free second one:
the letters that head nothing are where a command still fits,
and a family with few members is where its own options still fit —
`w` holds `switch` alone, so `switch`'s flags have the room
the `worktree` subcommands took under `wt`.
Counting them here would be a list going stale beside the one that cannot,
so the trie is where they are read.

**A borrowed prefix is visible too:**
a group standing immediately before a letter family — `mu` before `m`,
`sq` and `st` before `s` — is a name that would otherwise read as a
variant of that family, and does not belong to it.
