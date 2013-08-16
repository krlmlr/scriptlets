all: install

IGNORE=Makefile

INSTALL_FILES=$(filter-out $(IGNORE),$(wildcard *))

INSTALL_DIR=~/bin

install:
	for f in ${INSTALL_FILES}; do ln --verbose -s $$PWD/$$f ${INSTALL_DIR}/$$f; done
