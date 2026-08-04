all: install

.PHONY: all install force check uninstall test test-local

# RCRC points rcm at the copy in this repository, so the first run works on a
# machine that has no ~/.rcrc yet; -d overrides DOTFILES_DIRS, so the
# repository does not have to sit in ~/git/scriptlets.
RCM = RCRC="$(CURDIR)/rcm/rcrc"
DOTDIR = -d "$(CURDIR)/rcm"

install:
	$(RCM) rcup $(DOTDIR)

# Replace existing files instead of skipping them. This is what
# `make run-force-install` used to do.
force:
	$(RCM) rcup -f $(DOTDIR)

# List the mapping without touching the filesystem.
check:
	$(RCM) lsrc $(DOTDIR)

# Remove every symlink rcm owns.
uninstall:
	$(RCM) rcdn $(DOTDIR)

# The same suite in a container, for a Linux run from a machine that is not
# Linux. CI covers Ubuntu and macOS; this is for a quick check in between.
test:
	docker run --rm -v $(shell pwd):/scriptlets -w /scriptlets buildpack-deps:latest \
	  sh -c 'apt-get update && apt-get install -y rcm && make test-local'

# Install into a throw-away home directory and run the checks against it. The
# home directory of whoever runs this is left alone.
test-local:
	./tests/run
