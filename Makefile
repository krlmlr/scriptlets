all: install

.PHONY: all install check test test-local

# `install` is dotbot's own entry point: it initialises the submodule and runs
# dotbot against install.conf.yaml. Everything the `make-install` generator
# used to emit is now declared there instead.
install:
	./install

# Report what `make install` would do, without touching the filesystem.
check:
	./install --dry-run --verbose

test:
	docker run --rm -v $(shell pwd):/scriptlets -w /scriptlets buildpack-deps:latest make test-local

test-local:
	make install
	ls -lRa $${HOME}
	make install
	ls -lRa $${HOME}
