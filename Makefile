ifeq ($(OS),Windows_NT)
$(error Windows is not supported)
endif

LANGUAGE_NAME := tree-sitter-polar
HOMEPAGE_URL := https://github.com/tree-sitter/tree-sitter-polar
VERSION := 1.0.0

# repository
SRC_DIR := src

TS ?= tree-sitter

# install directory layout
PREFIX ?= /usr/local
INCLUDEDIR ?= $(PREFIX)/include
LIBDIR ?= $(PREFIX)/lib
PCLIBDIR ?= $(LIBDIR)/pkgconfig

# source/object files
PARSER := $(SRC_DIR)/parser.c
EXTRAS := $(filter-out $(PARSER),$(wildcard $(SRC_DIR)/*.c))
OBJS := $(patsubst %.c,%.o,$(PARSER) $(EXTRAS))

# flags
ARFLAGS ?= rcs
override CFLAGS += -I$(SRC_DIR) -std=c11 -fPIC

# ABI versioning
SONAME_MAJOR = $(shell sed -n 's/\#define LANGUAGE_VERSION //p' $(PARSER))
SONAME_MINOR = $(word 1,$(subst ., ,$(VERSION)))

# OS-specific bits
ifeq ($(shell uname),Darwin)
	SOEXT = dylib
	SOEXTVER_MAJOR = $(SONAME_MAJOR).$(SOEXT)
	SOEXTVER = $(SONAME_MAJOR).$(SONAME_MINOR).$(SOEXT)
	LINKSHARED = -dynamiclib -Wl,-install_name,$(LIBDIR)/lib$(LANGUAGE_NAME).$(SOEXTVER),-rpath,@executable_path/../Frameworks
else
	SOEXT = so
	SOEXTVER_MAJOR = $(SOEXT).$(SONAME_MAJOR)
	SOEXTVER = $(SOEXT).$(SONAME_MAJOR).$(SONAME_MINOR)
	LINKSHARED = -shared -Wl,-soname,lib$(LANGUAGE_NAME).$(SOEXTVER)
endif
ifneq ($(filter $(shell uname),FreeBSD NetBSD DragonFly),)
	PCLIBDIR := $(PREFIX)/libdata/pkgconfig
endif

all: lib$(LANGUAGE_NAME).a lib$(LANGUAGE_NAME).$(SOEXT) $(LANGUAGE_NAME).pc

lib$(LANGUAGE_NAME).a: $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

lib$(LANGUAGE_NAME).$(SOEXT): $(OBJS)
	$(CC) $(LDFLAGS) $(LINKSHARED) $^ $(LDLIBS) -o $@
ifneq ($(STRIP),)
	$(STRIP) $@
endif

$(LANGUAGE_NAME).pc: bindings/c/$(LANGUAGE_NAME).pc.in
	sed -e 's|@PROJECT_VERSION@|$(VERSION)|' \
		-e 's|@CMAKE_INSTALL_LIBDIR@|$(LIBDIR:$(PREFIX)/%=%)|' \
		-e 's|@CMAKE_INSTALL_INCLUDEDIR@|$(INCLUDEDIR:$(PREFIX)/%=%)|' \
		-e 's|@PROJECT_DESCRIPTION@|$(DESCRIPTION)|' \
		-e 's|@PROJECT_HOMEPAGE_URL@|$(HOMEPAGE_URL)|' \
		-e 's|@CMAKE_INSTALL_PREFIX@|$(PREFIX)|' $< > $@

$(PARSER): $(SRC_DIR)/grammar.json
	$(TS) generate $^

install: all
	install -d '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter '$(DESTDIR)$(PCLIBDIR)' '$(DESTDIR)$(LIBDIR)'
	install -m644 bindings/c/$(LANGUAGE_NAME).h '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/$(LANGUAGE_NAME).h
	install -m644 $(LANGUAGE_NAME).pc '$(DESTDIR)$(PCLIBDIR)'/$(LANGUAGE_NAME).pc
	install -m644 lib$(LANGUAGE_NAME).a '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).a
	install -m755 lib$(LANGUAGE_NAME).$(SOEXT) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER)
	ln -sf lib$(LANGUAGE_NAME).$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER_MAJOR)
	ln -sf lib$(LANGUAGE_NAME).$(SOEXTVER_MAJOR) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXT)

uninstall:
	$(RM) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).a \
		'$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER) \
		'$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER_MAJOR) \
		'$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXT) \
		'$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/$(LANGUAGE_NAME).h \
		'$(DESTDIR)$(PCLIBDIR)'/$(LANGUAGE_NAME).pc

clean:
	$(RM) $(OBJS) $(LANGUAGE_NAME).pc lib$(LANGUAGE_NAME).a lib$(LANGUAGE_NAME).$(SOEXT)

test:
	$(TS) test

wasm:
	$(TS) build --wasm

.PHONY: all install uninstall clean test wasm

# Begin Tree-sitter LS config. Borrowed from
#  https://github.com/nvim-treesitter/nvim-treesitter/blob/c6dd314086f7b471bf6c9110092a94ce1c06d220/Makefile
ifeq ($(shell uname -s),Darwin)
    NVIM_ARCH ?= macos-arm64
    LUALS_ARCH ?= darwin-arm64
    STYLUA_ARCH ?= macos-aarch64
    RUST_ARCH ?= aarch64-apple-darwin
else
    NVIM_ARCH ?= linux-x86_64
    LUALS_ARCH ?= linux-x64
    STYLUA_ARCH ?= linux-x86_64
    RUST_ARCH ?= x86_64-unknown-linux-gnu
endif

DEPDIR ?= .test-deps
CURL ?= curl -sL --create-dirs

TSQUERYLS := $(DEPDIR)/ts_query_ls-$(RUST_ARCH)
TSQUERYLS_TARBALL := $(TSQUERYLS).tar.gz
TSQUERYLS_URL := https://github.com/ribru17/ts_query_ls/releases/latest/download/$(notdir $(TSQUERYLS_TARBALL))

.PHONY: tsqueryls
tsqueryls: $(TSQUERYLS)

$(TSQUERYLS):
	$(CURL) $(TSQUERYLS_URL) -o $(TSQUERYLS_TARBALL)
	mkdir $@
	tar -xf $(TSQUERYLS_TARBALL) -C $@
	rm -rf $(TSQUERYLS_TARBALL)

.PHONY: query
query: formatquery lintquery checkquery

.PHONY: lintquery
lintquery: $(TSQUERYLS) wasm
	$(TSQUERYLS)/ts_query_ls lint queries

.PHONY: formatquery
formatquery: $(TSQUERYLS) wasm
	$(TSQUERYLS)/ts_query_ls format queries

.PHONY: checkquery
checkquery: $(TSQUERYLS) wasm
	$(TSQUERYLS)/ts_query_ls check -f queries
# End Tree-sitter LS config.
