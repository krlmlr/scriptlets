all: install

.PHONY: install quiet-install force-install

install:
	./install
	if [ -d scriptlets/$${USER} ]; then ./install scriptlets/$${USER} $${HOME}/scriptlets; fi

quiet-install:
	./install --quiet
	if [ -d scriptlets/$${USER} ]; then ./install --quiet scriptlets/$${USER} $${HOME}/scriptlets; fi

force-install:
	./install --force
	if [ -d scriptlets/$${USER} ]; then ./install --force scriptlets/$${USER} $${HOME}/scriptlets; fi
