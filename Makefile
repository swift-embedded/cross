prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

build:
	swift build -c release --disable-sandbox

install: build
	install ".build/release/cross" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/cross"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
