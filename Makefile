# The build system example.spec's %build and %install sections drive
# (%make_build and %make_install). Replace this with your real project's
# own build — a Go binary, a compiled C program, whatever it is — as long
# as `install` still populates DESTDIR the way %install expects.

PREFIX ?= /usr

build:
	@echo "nothing to compile for example-tool"

install:
	install -Dm755 bin/example-tool $(DESTDIR)$(PREFIX)/bin/example-tool

.PHONY: build install
