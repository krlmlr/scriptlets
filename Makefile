all: install

.PHONY: install force-install

install:
	./install home

force-install:
	./install --force home
