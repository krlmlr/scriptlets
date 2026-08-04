# A fallback for a machine without mise. The tasks in mise.toml are the real
# thing; these targets exist so that a plain `make` still installs.
#
# Only the one-line targets are duplicated here. Anything longer lives in mise
# alone -- a second implementation would drift, and a fallback that lies is
# worse than one that points at the real thing.

all: install

.PHONY: all install force check uninstall import test test-container

# RCRC points rcm at the copy in this repository, so the first run works on a
# machine that has no ~/.rcrc yet; -d overrides DOTFILES_DIRS, so the
# repository does not have to sit in ~/git/scriptlets. mise.toml sets the same
# two in [env].
RCM = RCRC="$(CURDIR)/rcm/rcrc"
DOTDIR = -d "$(CURDIR)/rcm"

install:
	$(RCM) rcup $(DOTDIR)

# Replace existing files instead of skipping them.
force:
	$(RCM) rcup -f $(DOTDIR)

# List the mapping without touching the filesystem.
check:
	$(RCM) lsrc $(DOTDIR)

# Remove every symlink rcm owns.
uninstall:
	$(RCM) rcdn $(DOTDIR)

# The rest are mise tasks: `import` reads UNDOTTED and takes arguments, and
# the two test targets need mise anyway, because tests/run runs tasks.
import test test-container:
	@echo "make $@: this one is a mise task -- run \`mise run $@\`" >&2
	@exit 1
