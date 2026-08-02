all: install

# Shared options (--dir, --target, --dotfiles, --no-folding) live in .stowrc.
# Note that .stowrc has no comment syntax: stow 2.3.x splits the whole file on
# whitespace and treats every token as an option.
STOW = stow

.PHONY: all install install-personalized delete delete-personalized restow \
        check test test-local

# `home` is stowed into $HOME, via the defaults in .stowrc. `ssh` and `config`
# are separate packages because their target is a subdirectory of $HOME:
# stow 2.3.x cannot translate a `dot-` prefix on a *directory* name, so
# `home/dot-ssh/config` would abort with a "non-directory path" error.
install:
	mkdir -p "$${HOME}/log" "$${HOME}/.ssh" "$${HOME}/.config"
	$(STOW) home
	$(STOW) --target "$${HOME}/.ssh" ssh
	$(STOW) --target "$${HOME}/.config" config
	if [ -n "$${USER}" ] && [ -d personalized/$${USER} ]; then $(MAKE) install-personalized; fi

install-personalized:
	mkdir -p "$${HOME}/scriptlets"
	$(STOW) --dir personalized --target "$${HOME}/scriptlets" "$${USER}"

# Remove every symlink this repository owns. stow only unlinks symlinks that
# point back into the package it is told about, so unrelated files stay put.
delete:
	$(STOW) --delete home
	$(STOW) --target "$${HOME}/.ssh" --delete ssh
	$(STOW) --target "$${HOME}/.config" --delete config
	if [ -n "$${USER}" ] && [ -d personalized/$${USER} ]; then $(MAKE) delete-personalized; fi

delete-personalized:
	$(STOW) --dir personalized --target "$${HOME}/scriptlets" --delete "$${USER}"

# Drop and recreate all links, so that links to renamed or removed files
# disappear instead of dangling.
restow:
	$(MAKE) delete
	$(MAKE) install

# Report what `make install` would do, without touching the filesystem.
check:
	$(STOW) --no --verbose home
	$(STOW) --no --verbose --target "$${HOME}/.ssh" ssh
	$(STOW) --no --verbose --target "$${HOME}/.config" config

test:
	docker run --rm -v $(shell pwd):/scriptlets -w /scriptlets buildpack-deps:latest \
	  sh -c 'apt-get update && apt-get install -y stow && make test-local'

test-local:
	make install
	ls -lRa $${HOME}
	make install
	ls -lRa $${HOME}
	make restow
	ls -lRa $${HOME}
