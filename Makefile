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

test:
	docker run --rm -v $(shell pwd):/scriptlets -w /scriptlets buildpack-deps:latest \
	  sh -c 'apt-get update && apt-get install -y rcm && make test-local'

test-local:
	make install
	ls -lRa $${HOME}
	make install
	ls -lRa $${HOME}
	make force
	ls -lRa $${HOME}
