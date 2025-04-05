all: install

.PHONY: install quiet-install force-install

install:
	./install
	if [ -n "$${USER}" ] && [ -d personalized/$${USER} ]; then ./install personalized/$${USER} $${HOME}/scriptlets; fi

quiet-install:
	./install --quiet
	if [ -n "$${USER}" ] && [ -d personalized/$${USER} ]; then ./install --quiet personalized/$${USER} $${HOME}/scriptlets; fi

force-install:
	./install --force
	if [ -n "$${USER}" ] && [ -d personalized/$${USER} ]; then ./install --force personalized/$${USER} $${HOME}/scriptlets; fi

test:
	docker run --rm -v $(shell pwd):/scriptlets -w /scriptlets buildpack-deps:latest make test-local

test-local:
	make
	ls -lRa $${HOME}
	make force-install
	ls -lRa $${HOME}
