all: install

.PHONY: install force-install

install:
	./install

force-install:
	./install --force
