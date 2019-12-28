prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	mkdir -p "$(bindir)"
	install ".build/release/cross" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/cross"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
