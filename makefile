SRCS := $(shell find src -name '*.swift' -type f)
SDK_PATH := $(shell xcrun --show-sdk-path --sdk macosx)
ARCH := $(shell uname -m)

all: dmenu

dmenu: $(SRCS) libfzy.a
	@echo "==> Building dmenu…"
	swiftc -O -sdk $(SDK_PATH) -framework Cocoa $(SRCS) -L. -lfzy -o dmenu

libfzy.a: | fzy/.git
	@echo "==> Building fzy library from https://github.com/jhawthorn/fzy"
	@cp fzy/src/config.def.h fzy/config.h 2>/dev/null || true
	clang -c -O2 -I. -Ifzy -isysroot $(SDK_PATH) -arch $(ARCH) fzy/src/match.c -o fzy/match.o
	ar rcs libfzy.a fzy/match.o

fzy/.git:
	@echo "==> Initializing fzy submodule…"
	git submodule update --init --recursive

clean:
	rm -f dmenu libfzy.a fzy/match.o

veryclean: clean
	@echo "==> Removing fzy submodule data…"
	rm -rf fzy/config.h

format:
	swiftformat src

.PHONY: all clean veryclean format

