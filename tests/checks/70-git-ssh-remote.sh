#!/bin/sh
# `git ssh-remote` converts what it promises to convert and nothing else. The
# script is exercised through the installed ~/bin, as `git ssh-remote`, so the
# check covers the wiring as well as the conversion.
#
# The repository it works on is a throw-away one below $HOME: `git init`
# contacts nothing, and neither does rewriting a URL.

set -u

. "$(dirname -- "$0")/../lib.sh"

PATH="$HOME/bin:$PATH"
export PATH

work=$HOME/git-ssh-remote-check
rm -rf "$work"
git init -q "$work"

# url_of REMOTE -- what is stored for REMOTE, not what `git remote get-url`
# shows, which any url.*.insteadOf rewrite would have had a hand in.
url_of() {
    git -C "$work" config --get-all "remote.$1.url" | tr '\n' ' ' | sed 's/ $//'
}

git -C "$work" remote add origin https://github.com/krlmlr/scriptlets.git
git -C "$work" remote add token https://ghp_secret@github.com/krlmlr/plain
git -C "$work" remote add ssh git@github.com:krlmlr/ssh.git
git -C "$work" remote add elsewhere https://gitlab.com/krlmlr/elsewhere.git

assert_ok "git ssh-remote --dry-run succeeds" \
    git -C "$work" ssh-remote --dry-run
assert_equal "--dry-run changes nothing" \
    "https://github.com/krlmlr/scriptlets.git" "$(url_of origin)"

assert_ok "git ssh-remote succeeds" git -C "$work" ssh-remote

assert_equal "an HTTPS GitHub remote becomes an SSH one" \
    "git@github.com:krlmlr/scriptlets.git" "$(url_of origin)"
assert_equal "credentials go, and the .git suffix arrives" \
    "git@github.com:krlmlr/plain.git" "$(url_of token)"
assert_equal "a remote that already speaks SSH is left alone" \
    "git@github.com:krlmlr/ssh.git" "$(url_of ssh)"
assert_equal "a remote on another host is left alone" \
    "https://gitlab.com/krlmlr/elsewhere.git" "$(url_of elsewhere)"

# --all-hosts is what that other host waits for.
assert_ok "git ssh-remote --all-hosts succeeds" \
    git -C "$work" ssh-remote --all-hosts elsewhere
assert_equal "--all-hosts converts a remote on another host" \
    "git@gitlab.com:krlmlr/elsewhere.git" "$(url_of elsewhere)"

# Both URLs of a remote that has two, and its push URL, which `git remote
# get-url` invents where there is none and this command must not write back.
git -C "$work" remote add many https://github.com/krlmlr/one.git
git -C "$work" config --add remote.many.url https://github.com/krlmlr/two.git
git -C "$work" config remote.many.pushurl https://github.com/krlmlr/push.git

assert_ok "git ssh-remote many succeeds" git -C "$work" ssh-remote many
assert_equal "every URL of a remote is converted" \
    "git@github.com:krlmlr/one.git git@github.com:krlmlr/two.git" \
    "$(url_of many)"
assert_equal "the push URL is converted too" \
    "git@github.com:krlmlr/push.git" \
    "$(git -C "$work" config --get-all remote.many.pushurl)"
assert_equal "no push URL is invented where there was none" \
    "" "$(git -C "$work" config --get-all remote.origin.pushurl)"

# Running it again has nothing left to do, and says so without failing.
assert_ok "a second run succeeds" git -C "$work" ssh-remote

if git -C "$work" ssh-remote nosuchremote 2>/dev/null; then
    fail "an unknown remote is an error"
else
    pass "an unknown remote is an error"
fi

rm -rf "$work"
