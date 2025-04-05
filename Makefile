all: run-install

# Directories exist: personalized/kirill, personalized/cynkra
# all_personalized should then be install-kirill install-cynkra
all_personalized=$(shell ls personalized | tr '\n' ' ')

build: install install-personalized

.PHONY: run-install run-quiet-install run-force-install

install: make-install Makefile
	./make-install home '$${HOME}' > $@
	chmod +x $@

install-personalized: make-install Makefile
	./make-install personalized/kirill '$${HOME}/scriptlets' | sed 's#kirill#$${USER}#g' > $@
	chmod +x $@

run-install:
	./install
	if [ -n "$${USER}" ] && [ -d personalized/$${USER} ]; then ./install-personalized; fi

run-quiet-install:
	./install --quiet
	if [ -n "$${USER}" ] && [ -d personalized/$${USER} ]; then ./install-personalized --quiet; fi

run-force-install:
	./install --force
	if [ -n "$${USER}" ] && [ -d personalized/$${USER} ]; then ./install-personalized --force; fi

test:
	docker run --rm -v $(shell pwd):/scriptlets -w /scriptlets buildpack-deps:latest make test-local

test-local:
	make run-quiet-install
	ls -lRa $${HOME}
	make run-quiet-install
	ls -lRa $${HOME}
	make run-force-install
	ls -lRa $${HOME}
