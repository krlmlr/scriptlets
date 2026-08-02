all: install

CASTLE = scriptlets
HOMESHICK = $${HOME}/.homesick/repos/homeshick/bin/homeshick

.PHONY: all install install-personalized check pull test test-local

# homeshick links everything under home/ into $HOME, creating real
# directories and symlinking the files -- including nested and hidden ones.
install:
	$(HOMESHICK) --batch link $(CASTLE)
	if [ -n "$${USER}" ] && [ -d personalized/$${USER} ]; then $(MAKE) install-personalized; fi

# homeshick has no per-user or per-machine mechanism: one castle installs the
# same files everywhere. The per-user overrides are therefore linked here, by
# hand, the way `install-personalized` used to.
install-personalized:
	mkdir -p "$${HOME}/scriptlets"
	for f in personalized/$${USER}/*; do \
	  ln -sfn "$(CURDIR)/$${f}" "$${HOME}/scriptlets/$$(basename "$${f}")"; \
	done

# Report which links are missing or out of date.
check:
	$(HOMESHICK) check $(CASTLE)
	$(HOMESHICK) --batch --pretend link $(CASTLE)

pull:
	$(HOMESHICK) --batch pull $(CASTLE)

test:
	docker run --rm -v $(shell pwd):/scriptlets -w /scriptlets buildpack-deps:latest make test-local

test-local:
	make install
	ls -lRa $${HOME}
	make install
	ls -lRa $${HOME}
