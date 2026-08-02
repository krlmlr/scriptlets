all: install

.PHONY: all install apply diff status check test test-local

# `chezmoi init` writes ~/.config/chezmoi/chezmoi.toml from .chezmoi.toml.tmpl,
# pointing sourceDir at this working tree; `--apply` then does the work.
# Safe to rerun.
install:
	chezmoi init --source "$(CURDIR)" --apply

# Once installed, sourceDir is recorded in the config, so these need no
# arguments and work from any directory.
apply:
	chezmoi apply

diff:
	chezmoi diff

status:
	chezmoi status

# Report what `make apply` would do, without touching the filesystem.
check:
	chezmoi apply --dry-run --verbose

test:
	docker run --rm -v $(shell pwd):/scriptlets -w /scriptlets buildpack-deps:latest \
	  sh -c 'sh -c "$$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin && make test-local'

test-local:
	make install
	ls -lRa $${HOME}
	make install
	ls -lRa $${HOME}
	chezmoi status
