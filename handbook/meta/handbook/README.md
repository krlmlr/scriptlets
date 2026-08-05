# The handbook's rules

The handbook is a strict topic hierarchy with full cover:
every aspect of this repository that may need documentation
has exactly one place in this tree.

* **Internal nodes navigate, and may govern.**
  An internal `README.md` is a scope sentence,
  optionally the principles that govern its area,
  and a nested list of its subdirectories —
  and, except at the root below, nothing else.
  A principle is why the area is divided as it is,
  or a constraint every leaf under it obeys;
  it belongs to the node because no single leaf could state it
  without reaching past its own scope.
  Anything one leaf could state is that leaf's,
  and an internal node never repeats it
  (the tests are among [the forms](#the-forms)).
  The root additionally sketches each area's contents,
  naming the next level in prose — names, not links,
  so the sketch cannot rot.
* **Leaves explain, once.**
  A leaf page owns its topic;
  other pages link to it and never paraphrase it.
  A leaf may sit at any depth, including directly under the root.
* **Leaves own their boundaries.**
  A leaf states not only how its topic works
  but also its limits, its declined requests with their reasons,
  and — where intent exists — a pointer to the issue that carries it.
  "Can it do X?" is answered at X's leaf, whichever way it goes.
* **Full cover.**
  Every fact is reachable by walking down from
  [`handbook/`](/handbook/README.md);
  a topic with no place in the tree is a defect of the tree,
  not of the topic.
  Nothing announces such a defect — a homeless topic raises no error,
  it is simply absent — so full cover is a claim the tree has to be
  audited against, not one its shape can enforce.
* **A scope sentence states a boundary, not a child list.**
  A node that describes itself by naming what is under it
  cannot admit the topic it did not foresee:
  the wording excludes it, and no one notices, because the child list
  below says the same thing and agrees.
  So when a topic turns out to have no home,
  ask first whether a node's *wording* excluded it rather than its
  design — that is the cheaper defect, and the commoner one.
* **Pointer leaves are legitimate.**
  Where the canonical home is elsewhere —
  a script's own `-h` or header comment,
  or truly external documentation
  such as rcm's man pages or the mise docs —
  the leaf states the fact's home and links to it,
  so a traversal still finds it.
  The tree needs no separate map of what lives outside;
  the leaves are the map.
* **Intent lives outside the tree.**
  The handbook describes how things work today;
  work merely intended lives in the issue tracker,
  and each affected leaf links the issue that carries its intent.
  An intention that has become fact is documented as fact,
  in the leaf, with no trace of its having once been a proposal.
* **The tree is the single source of truth.**
  Everything outside it is secondary —
  the root `README.md`, per-directory indexes, script headers —
  and every secondary document carries a backreference
  to the handbook node it serves.
  Where a pointer leaf names a fixed medium as a fact's home,
  the links are bidirectional:
  the leaf points at the medium,
  the medium backreferences the leaf.
  A secondary document without a backreference is an orphan.
* **A leaf is born small and grows in place.**
  Three depths are legitimate published states.
  A **reference** leaf states its scope
  and where the knowledge lives today.
  A **core** leaf additionally states the load-bearing facts —
  defaults, boundaries, the answers questions keep circling back to —
  and still points elsewhere for the rest.
  A **comprehensive** leaf answers its topic in full,
  so a reader never has to leave the tree for it.
  Comprehensive is the end state, not the entry bar;
  a leaf below it says what remains in a single closing line
  ([the forms](#the-forms)),
  which is this tree's only form of visible debt.

## Growing a leaf

The tree deepens one leaf per change, by four moves.
Any of them is a complete, mergeable pull request:

1. **Close an issue into its leaf.**
   An issue closed without a code change is closed
   *with* a documentation change:
   the answer, workaround, or limitation lands in the leaf
   that owns the topic, the closing comment links it,
   and the leaf links the issue from the text that answers it.
2. **Absorb a document, or one section of one.**
   The fine print moves to the leaf in the same change;
   what stays behind is cut to what a reader standing there needs,
   and backreferences the leaf that now carries the detail.
   A source with nothing left worth keeping goes away entirely,
   and anything that linked to it is updated.
   The breadcrumb is the point:
   a fact that changes is edited in one place,
   and the reader who never heard of the handbook still finds it.
3. **Deepen from the ground truth.**
   Write what the scripts, configuration files, and workflows
   actually do, and cite the file that proves it.
4. **Give a homeless topic a home.**
   Something tracked in this repository that no leaf covers gets one,
   born at reference depth: a scope sentence, where the knowledge lives
   today, and a deepen line naming the rest.
   The node above it gains a child-list entry, and a scope sentence too
   narrow to admit the new leaf is widened in the same change —
   otherwise the next topic of that kind falls out again.

Whichever move, the same protocol:

* **Register a term the tree reuses.**
  A term of art gets a glossary line linking its owning leaf,
  added by the change that coins it
  ([`meta/glossary/`](/handbook/meta/glossary/README.md)).
* **Follow [`meta/authoring/`](/handbook/meta/authoring/README.md).**
  Every sentence, new or absorbed, is walked down the ladder there
  before it is written — absorption is rewriting, never blind
  copy-paste.
* **Stay inside the scope line.**
  A fact beyond it belongs to another leaf — link, don't absorb.
* **Finish clean.**
  Update the leaf's closing deepen line — or delete it
  when nothing remains — and leave no dangling links.

## The forms

The rules above say what a page must do;
these are the shapes the tree has settled on for doing it.
They exist so that leaves written independently read as one document.
How the prose itself is written is `meta/authoring/`'s.

**A written leaf** opens with its H1
and then a scope sentence in ordinary prose,
and continues with the content.
The scope sentence is load-bearing at every depth:
the tree's shape depends on every leaf declaring its boundary.
A one-screen leaf needs no headings; a longer one uses `##`.

**A named part of a one-screen leaf** opens with a bold run-in phrase
rather than a heading;
headings start where a page is long enough to navigate.

**A link to a handbook page** names the directory in backticks
and targets its `README.md`.
An internal node's child list is the exception:
there the link text is the directory and so is the target,
because the list is the tree, not a citation.

**A deepen line** is the last line of a leaf
that is not yet comprehensive:
one italic sentence naming what deepening absorbs, verifies, or drains —
`*To deepen: absorb the import header comment; drain #….*` —
kept current by every change to the leaf,
and deleted by the change that completes it.
A leaf with no deepen line asserts it is comprehensive.

**A principle on an internal node** is a short paragraph, or a few,
between the scope sentence and the list of children.
It survives three tests,
and a sentence that fails any of them belongs to a leaf instead:
a leaf yet to be written could falsify it
(a generalisation over the children, not a summary of one);
it has the lifetime of the child list
(a fact an ordinary commit could falsify has a leaf);
and it names no particulars —
no paths, scripts, variables, versions, counts, or commands.
A node whose leaves share no such constraint gets no principle.

**A link that leaves its own directory is written from the repository
root**, with a leading `/`;
same-directory and downward links stay relative,
and an upward `../` chain is never written —
it breaks the moment a page moves, and a page in a settling tree moves.
GitHub resolves a root-relative link on any branch or fork;
a local Markdown preview does not, and that is the trade taken.

**An absorbed file keeps its essentials, or goes away.**
A `.md` whose detail has landed in a leaf shrinks to the part
its own readers need and backreferences the leaf;
what it must not become is a one-line redirect.
A file with nothing left to keep is deleted, and its place is taken
by the **in-place `README.md`** —
the index GitHub renders when someone browses to that directory,
an entry per file, written by hand
([`obsolete/README.md`](/obsolete/README.md) is the worked example).
A file only partly absorbed keeps its remaining sections,
and each absorbed heading becomes a one-line pointer to the leaf.
One directory never gets an in-place index:
a `.github/README.md` would be surfaced as the repository front page
(precedence `.github/` → root → `docs/`).

**A backreference is how a leaf is discovered from the source tree.**
Someone standing in `rcm/bin/` finds the leaf that explains what they
are looking at without knowing the handbook exists.
An in-place index carries the backreference for the files it covers;
where no index covers a document, it carries its own:

* *Markdown* — a visible italic line directly under the H1,
  linking the leaf by repo-relative path.
  Several leaves serving one file share the one line.
  The root `README.md` is the exception:
  it is the repository's front page,
  read mostly by visitors who have not heard of the handbook,
  so its pointers live in its sections
  rather than above the first sentence about the repository.
* *Scripts and configuration files* — a plain comment
  below the file's one-line header.

## Enforcement

The mechanical rules are a check, not a request:
[`tests/checks/05-handbook.sh`](/tests/checks/05-handbook.sh)
fails the suite when a directory here lacks its `README.md`,
a parent's child list misses a subdirectory,
a link dangles, or a link reaches upward —
run with everything else, locally and in CI
([`testing/`](/handbook/testing/README.md)).
What needs judgment —
whether a fact sits in the leaf that owns it,
whether a scope sentence still holds,
whether a rewrite lost a fact —
is review work, against this page and `meta/authoring/`.

*To deepen: script backreferences cover the zsh startup pair alone;
the rest of `rcm/` is unannotated.*
