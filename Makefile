# A fallback for a machine without mise.
#
# There is nothing to keep in step: the tasks are ordinary scripts in
# mise-tasks/, and these targets run the very same files that `mise run` runs.
# Only the ones that work without mise are here -- `import` needs mise to
# parse its arguments, and the test targets run tasks themselves -- so those
# name the task and stop rather than pretend.

all: install

.PHONY: all install force check uninstall nosleep-grant import test test-container

install force check uninstall nosleep-grant:
	@$(CURDIR)/mise-tasks/$@

import test test-container:
	@echo "make $@: this one needs mise -- run \`mise run $@\`" >&2
	@exit 1
