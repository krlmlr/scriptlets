#!/bin/sh
# `bootstrap-private` creates the private sidecar repository, and converges on
# a re-run rather than refusing or duplicating
# (handbook/layout/private/README.md).
#
# Idempotency is the property that has to survive the script growing another
# step, and the only way to see it is to run the thing twice and compare. The
# second run must report no creation at all, and must leave a file that was
# edited by hand exactly as it was -- by then it holds secrets.
#
# GitHub is stood in for by the stub below, which answers only the handful of
# `gh` calls the script makes. It is a stub, so it pins the calls as much as
# the behaviour: a step that reaches for gh in a new way fails here loudly,
# which is the point at which to decide whether the stub or the step is wrong.

set -u

. "$(dirname -- "$0")/../lib.sh"

work=$(mktemp -d "${TMPDIR:-/tmp}/scriptlets-bootstrap.XXXXXX")
dest=$work/side

mkdir "$work/bin"
cat >"$work/bin/gh" <<'STUB'
#!/bin/sh
set -eu
mkdir -p "$GH_STATE"

# The flag values the script passes, read positionally rather than parsed.
flag() {
    _want=$1
    shift
    _prev=
    for _a in "$@"; do
        [ "$_prev" = "$_want" ] && { printf '%s' "$_a"; return 0; }
        _prev=$_a
    done
}

case "${1:-} ${2:-}" in
"auth status") exit 0 ;;
"repo view")
    # Takes a bare name and resolves it against the account, as gh does.
    [ -f "$GH_STATE/exists" ] || exit 1
    case "$(flag -q "$@")" in
    .nameWithOwner) echo "stub/${3##*/}" ;;
    .description) cat "$GH_STATE/description" 2>/dev/null || true; echo ;;
    .sshUrl) echo "$GH_STATE/remote.git" ;;
    .url) echo "https://github.example/stub/${3##*/}" ;;
    esac
    exit 0
    ;;
"repo create")
    [ -f "$GH_STATE/exists" ] && exit 1
    printf '%s' "$(flag --description "$@")" >"$GH_STATE/description"
    git init -q --bare "$GH_STATE/remote.git"
    : >"$GH_STATE/exists"
    exit 0
    ;;
"repo edit")
    # gh insists on OWNER/REPO here where `repo view` is happy with a bare
    # name, and says so in exactly these words. Refusing it here too is the
    # whole value of the stub: the asymmetry is real, and easy to write past.
    case "${3:-}" in
    */*) ;;
    *)
        echo "expected the \"[HOST/]OWNER/REPO\" format, got \"${3:-}\"" >&2
        exit 1
        ;;
    esac
    printf '%s' "$(flag --description "$@")" >"$GH_STATE/description"
    exit 0
    ;;
esac

echo "gh stub: unhandled call: $*" >&2
exit 1
STUB
chmod +x "$work/bin/gh"

PATH=$work/bin:$PATH
GH_STATE=$work/state
SCRIPTLETS_PRIVATE=$dest
export PATH GH_STATE SCRIPTLETS_PRIVATE

# The throw-away home has no git identity, and neither does a CI runner: the
# repository's ~/.gitconfig only carries one for an account with a tag.
GIT_AUTHOR_NAME=check
GIT_AUTHOR_EMAIL=check@example
GIT_COMMITTER_NAME=check
GIT_COMMITTER_EMAIL=check@example
export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

# --- the dry run changes nothing -------------------------------------------

if plan=$("$REPO/bootstrap-private" -n 2>&1); then
    pass "a dry run on nothing succeeds"
else
    fail "a dry run on nothing succeeds" "$plan"
fi

if [ -e "$dest" ]; then
    fail "a dry run creates nothing" "$dest exists"
else
    pass "a dry run creates nothing"
fi

missing=
for name in README.md rcrc rcm/bash_secrets rcm/gitconfig.user \
    rcm/Rprofile.private rcm/ssh/config-private rcm/hooks/post-up; do
    printf '%s\n' "$plan" | grep -qF "+  $name" || missing="$missing $name"
done

if [ -z "$missing" ]; then
    pass "the plan names every file of the skeleton"
else
    fail "the plan names every file of the skeleton" "not planned:$missing
$plan"
fi

# --- the first run ---------------------------------------------------------

assert_ok "the first run succeeds" "$REPO/bootstrap-private"

# The fragment belongs at the root: under rcm/ it would be installed as
# ~/.rcrc, over the file that sources it, and the tasks refuse to run at all.
if [ -f "$dest/rcrc" ] && [ ! -e "$dest/rcm/rcrc" ]; then
    pass "the rcrc fragment lands at the root, not under rcm/"
else
    fail "the rcrc fragment lands at the root, not under rcm/" \
        "$(find "$dest" -name rcrc 2>&1)"
fi

# rcm only runs a hook it can execute.
if [ -x "$dest/rcm/hooks/post-up" ]; then
    pass "the hook is executable"
else
    fail "the hook is executable" "$(ls -l "$dest/rcm/hooks/post-up" 2>&1)"
fi

assert_equal "a fresh sidecar has two commits" \
    "2" "$(git -C "$dest" rev-list --count HEAD 2>&1)"

root=$(git -C "$dest" rev-list --max-parents=0 HEAD 2>/dev/null)

assert_equal "the root commit is named Initial commit" \
    "Initial commit" "$(git -C "$dest" show -s --format=%s "$root" 2>&1)"

# The point of the root: the skeleton arrives as a diff like everything after
# it, rather than as the state the repository began in.
if [ -z "$(git -C "$dest" ls-tree "$root" 2>&1)" ]; then
    pass "the root commit is empty"
else
    fail "the root commit is empty" "$(git -C "$dest" ls-tree "$root" 2>&1)"
fi

assert_equal "the skeleton is a commit of its own on top of it" \
    "Add the sidecar skeleton" "$(git -C "$dest" log -1 --format=%s 2>&1)"

assert_equal "it commits on main" \
    "main" "$(git -C "$dest" rev-parse --abbrev-ref HEAD 2>&1)"

assert_equal "the repository is created with a description" \
    "Private counterpart of https://github.com/krlmlr/scriptlets" \
    "$(cat "$work/state/description" 2>&1)"

# --- a second run converges ------------------------------------------------

# What a sidecar is for, added the way its owner would add it.
printf 'export A_REAL_SECRET=hunter2\n' >>"$dest/rcm/bash_secrets"
git -C "$dest" add -A
git -C "$dest" commit -q -m "a secret"

secret_before=$(cat "$dest/rcm/bash_secrets")
head_before=$(git -C "$dest" rev-parse HEAD)

assert_ok "a second run succeeds" "$REPO/bootstrap-private"
again=$("$REPO/bootstrap-private" 2>&1)

if printf '%s\n' "$again" | grep -q '^  + '; then
    fail "a settled run creates nothing" \
        "$(printf '%s\n' "$again" | grep '^  + ')"
else
    pass "a settled run creates nothing"
fi

assert_equal "a file edited by hand is left alone" \
    "$secret_before" "$(cat "$dest/rcm/bash_secrets")"

assert_equal "no second commit is invented" \
    "$head_before" "$(git -C "$dest" rev-parse HEAD 2>&1)"

assert_equal "the skeleton is committed once, not again" \
    "3" "$(git -C "$dest" rev-list --count HEAD 2>&1)"

# --- the description follows -d --------------------------------------------

"$REPO/bootstrap-private" -d "Another description" >/dev/null 2>&1

assert_equal "-d updates the description on a repository that exists" \
    "Another description" "$(cat "$work/state/description" 2>&1)"

repeat=$("$REPO/bootstrap-private" -d "Another description" 2>&1)

if printf '%s\n' "$repeat" | grep -q '^  ~ '; then
    fail "the same -d twice is not an update" \
        "$(printf '%s\n' "$repeat" | grep '^  ~ ')"
else
    pass "the same -d twice is not an update"
fi

rm -rf "$work"
