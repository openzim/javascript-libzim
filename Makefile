SHELL := /bin/bash

# Version of the libzim *source* tarball we download and patch below. Keep every
# reference to the source tree going through $(LIBZIM_SRC) rather than a `libzim-*`
# glob: a glob silently picks up stale extracted trees, and it lets a hardcoded
# path drift out of sync on a version bump without anything complaining.
# (Distinct from LIBZIM_VERSION, which selects a *prebuilt* release in libzim_release.)
LIBZIM_SRC_VERSION ?= 9.8.1
LIBZIM_SRC := libzim-$(LIBZIM_SRC_VERSION)

# Xapian version, same reasoning. Stay on >= 1.4.30: 1.4.28 accidentally dropped the
# English stemmer's "skis" exception and 1.4.30 restored it, so 1.4.28/1.4.29 stem that
# word differently from the Xapian that built the ZIM's index (kiwix-build pins 1.4.23).
# The set of language codes Xapian::Stem accepts is identical across 1.4.23...1.4.31, so
# bumping within that range does not affect the stemmer whitelist patched in below.
XAPIAN_VERSION ?= 1.4.31
XAPIAN_SRC := xapian-core-$(XAPIAN_VERSION)

# Remaining dependency versions, same treatment: one variable drives the download URL,
# the tarball name and the directory we build in, so those three can never disagree.
# (ICU is left out deliberately - it extracts to an unversioned `icu/` directory and
# re-checks the download every time, so it does not follow this pattern.)
XZ_VERSION ?= 5.2.6
XZ_SRC := xz-$(XZ_VERSION)
ZLIB_VERSION ?= 1.3.1
ZLIB_SRC := zlib-$(ZLIB_VERSION)
ZSTD_VERSION ?= 1.5.7
ZSTD_SRC := zstd-$(ZSTD_VERSION)

all: rename_pjsn build/lib/libzim.a libzim-wasm.dev.js libzim-asm.dev.js libzim-wasm.js libzim-asm.js large_file_access.js restore_pjsn

release: libzim-asm.js libzim-wasm.js libzim-asm.dev.js libzim-wasm.dev.js large_file_access.js

nightly: libzim-asm.js libzim-wasm.js libzim-asm.dev.js libzim-wasm.dev.js large_file_access.js

rename_pjsn:
	# Due to a bug in Emscripten, we need to rename package.json before building libzim from source,
	# otherwise it prevents compilation of (at least) xz utilities
	mv package.json package.json.temp

restore_pjsn:
	mv package.json.temp package.json

libzim_release:
	wget -N $$(wget -q https://download.openzim.org/release/libzim/feed.xml -O - | grep -E -o -m1 "<link>[^<]+wasm-emscripten-${LIBZIM_VERSION}[^<]+</link>" | sed -E "s:</?link>::g")
	tar xf libzim_wasm-emscripten-*.tar.gz
	mkdir build
	mkdir build/lib
	cp -r libzim_wasm-emscripten-*/include/ build/include/
	cp -r libzim_wasm-emscripten-*/lib/*.* build/lib/

libzim_nightly:
	wget -N https://download.openzim.org/nightly/$$(date +'%Y-%m-%d')/$$(wget -q https://download.openzim.org/nightly/$$(date +'%Y-%m-%d') -O - | grep -E -o -m1 '"libzim_wasm-emscripten[^"]+"' | sed -E 's/"//g')
	tar xf libzim_wasm-emscripten-$$(date +'%Y-%m-%d').tar.gz
	mkdir build
	mkdir build/lib
	cp -r libzim_wasm-emscripten-$$(date +'%Y-%m-%d')/include/ build/include/
	cp -r libzim_wasm-emscripten-$$(date +'%Y-%m-%d')/lib/*.* build/lib/

build/lib/liblzma.so : 
	# Origin: https://tukaani.org/xz/$(XZ_SRC).tar.gz
	[ -f $(XZ_SRC).tar.gz ] || wget -N https://dev.kiwix.org/kiwix-build/$(XZ_SRC).tar.gz
	tar xf $(XZ_SRC).tar.gz
	# --no-po4a: xz >= 5.2.6 generates translated man pages in autogen.sh and
	# exits non-zero if po4a is not installed. We don't need the man pages.
	cd $(XZ_SRC)/ ; ./autogen.sh --no-po4a
	cd $(XZ_SRC)/ ; emconfigure ./configure --prefix=`pwd`/../build
	cd $(XZ_SRC)/ ; emmake make
	cd $(XZ_SRC)/ ; emmake make install
	
build/lib/libz.a :
	# Origin: https://zlib.net/fossils/$(ZLIB_SRC).tar.gz
	# Do not use the top-level zlib.net URL: it only serves the newest release and
	# moves older ones to fossils/, so the download silently becomes an HTML page.
	[ -f $(ZLIB_SRC).tar.gz ] || wget -N https://dev.kiwix.org/kiwix-build/$(ZLIB_SRC).tar.gz
	tar xf $(ZLIB_SRC).tar.gz
	cd $(ZLIB_SRC)/ ; emconfigure ./configure --prefix=`pwd`/../build
	cd $(ZLIB_SRC)/ ; emmake make
	cd $(ZLIB_SRC)/ ; emmake make install
	
build/lib/libzstd.a :
	# Origin: https://github.com/facebook/zstd/releases/download/v$(ZSTD_VERSION)/$(ZSTD_SRC).tar.gz
	[ -f $(ZSTD_SRC).tar.gz ] || wget -N https://dev.kiwix.org/kiwix-build/$(ZSTD_SRC).tar.gz
	tar xf $(ZSTD_SRC).tar.gz
	cd $(ZSTD_SRC)/build/meson ; meson setup --cross-file=../../../emscripten-crosscompile.ini -Dbin_programs=false -Dbin_contrib=false -Dzlib=disabled -Dlzma=disabled -Dlz4=disabled --prefix=`pwd`/../../../build --libdir=lib builddir
	cd $(ZSTD_SRC)/build/meson/builddir ; ninja
	cd $(ZSTD_SRC)/build/meson/builddir ; ninja install
	
build/lib/libicudata.so : 
	# Version not yet available in dev.kiwix.org
	wget -N https://github.com/unicode-org/icu/releases/download/release-73-2/icu4c-73_2-src.tgz
	tar xf icu4c-*-src.tgz
	# It's no use trying to compile examples
	sed -i -e 's/^SUBDIRS =\(.*\)$$(DATASUBDIR) $$(EXTRA) $$(SAMPLE) $$(TEST)\(.*\)/SUBDIRS =\1\2/' icu/source/Makefile.in
	cd icu/source ; emconfigure ./configure --prefix=`pwd`/../../build
	cd icu/source ; emmake make 
	cd icu/source ; emmake make install

build/lib/libxapian.a : build/lib/libz.a
	# Origin: https://oligarchy.co.uk/xapian/$(XAPIAN_VERSION)/$(XAPIAN_SRC).tar.xz
	# Also mirrored (older versions only) at https://dev.kiwix.org/kiwix-build/
	# As with libzim, the tarball name is pinned rather than globbed: `[ ! -f xapian-*.tar.xz ]`
	# passes several arguments to `test` when a stale tarball is present, so the download is
	# skipped and the *old* version gets built - silently, and with no trace in the log.
	[ -f $(XAPIAN_SRC).tar.xz ] || wget -N https://oligarchy.co.uk/xapian/$(XAPIAN_VERSION)/$(XAPIAN_SRC).tar.xz
	tar xf $(XAPIAN_SRC).tar.xz
        # Some options coming from https://github.com/xapian/xapian/tree/master/xapian-core/emscripten
	# cd $(XAPIAN_SRC); emconfigure ./configure --prefix=`pwd`/../build "CFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" "CXXFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" CPPFLAGS='-DFLINTLOCK_USE_FLOCK' CXXFLAGS='-Oz -s USE_ZLIB=1 -fno-rtti' --disable-backend-honey --disable-backend-inmemory --disable-shared --disable-backend-remote
	cd $(XAPIAN_SRC)/ ; emconfigure ./configure --prefix=`pwd`/../build "CFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" "CXXFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" --disable-shared --disable-backend-remote
	cd $(XAPIAN_SRC)/ ; emmake make "CFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib -std=c++14" "CXXFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib -std=c++14"
	cd $(XAPIAN_SRC)/ ; emmake make install

build/lib/libzim.a : build/lib/liblzma.so build/lib/libz.a build/lib/libzstd.a build/lib/libicudata.so build/lib/libxapian.a
	# Download and extract libzim source. The tarball name is pinned rather than globbed:
	# `[ ! -f libzim-*.tar.xz ]` expands to several arguments when a stale tarball is
	# present, which makes `test` error out, skips the download, and then extracts and
	# builds the *old* version.
	[ -f $(LIBZIM_SRC).tar.xz ] || wget -N https://download.openzim.org/release/libzim/$(LIBZIM_SRC).tar.xz
	tar xf $(LIBZIM_SRC).tar.xz

	@echo "=== APPLYING ESSENTIAL LIBZIM PATCHES ==="

	# 1. Add required headers for std::set
	sed -i '/#include <unicode\/locid.h>/a #include <set>' $(LIBZIM_SRC)/src/search.cpp
	sed -i '/#include <unicode\/locid.h>/a #include <set>' $(LIBZIM_SRC)/src/suggestion.cpp

	# 2. Language whitelist for Xapian stemmer stability. Xapian::Stem throws
	# InvalidArgumentError for a language it has no stemmer for, and libzim's own
	# `catch` around it is compiled away (no exception flags in the cross file), so an
	# unsupported language aborts the module instead. The list must therefore be exactly
	# the set of two-letter codes Xapian accepts - a code that is missing costs recall
	# (silent fallback to the "none" stemmer), but a code that should not be there
	# defeats the whole guard. Source of truth is the generated keyword table in
	# xapian-core-*/languages/sbl-dispatch.h; re-check it when bumping Xapian.
	# Across 1.4.23...1.4.31 that is the 26 codes below - note Xapian 1.4 has no Greek,
	# Hindi or Serbian stemmer, despite those being plausible-looking entries.
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); static const std::set<std::string> supportedLangs = {"ar", "ca", "da", "de", "en", "es", "eu", "fi", "fr", "ga", "hu", "hy", "id", "it", "lt", "nb", "ne", "nl", "nn", "no", "pt", "ro", "ru", "sv", "ta", "tr"}; if (supportedLangs.find(stemLang) != supportedLangs.end()) { m_stemmer = Xapian::Stem(stemLang); } else { m_stemmer = Xapian::Stem("none"); } }/' $(LIBZIM_SRC)/src/search.cpp
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); static const std::set<std::string> supportedLangs = {"ar", "ca", "da", "de", "en", "es", "eu", "fi", "fr", "ga", "hu", "hy", "id", "it", "lt", "nb", "ne", "nl", "nn", "no", "pt", "ro", "ru", "sv", "ta", "tr"}; if (supportedLangs.find(stemLang) != supportedLangs.end()) { m_stemmer = Xapian::Stem(stemLang); } else { m_stemmer = Xapian::Stem("none"); } }/' $(LIBZIM_SRC)/src/suggestion.cpp

	# 3. CRITICAL FIX: Remove problematic bool exceptions from HTML parser
	@echo "Applying HTML parser WASM fix..."
	sed -i 's/throw true;/return;/g' $(LIBZIM_SRC)/src/xapian/myhtmlparse.cc
	sed -i 's/throw newcharset;/return;/g' $(LIBZIM_SRC)/src/xapian/myhtmlparse.cc

	# Verify patches applied correctly. `sed` exits 0 when its pattern matches nothing,
	# so every patch above is capable of silently no-opping after an upstream refactor:
	# this check must therefore fail the build rather than just print a count. The throw
	# detection below is deliberately looser than the `sed` patterns it verifies, so that
	# a reformatted `throw (true);` upstream trips the check instead of sneaking past.
	# Each check is one physical line that exits non-zero on failure, so the build stops
	# at the first unapplied patch. (Kept free of backslash continuations on purpose:
	# this file has CRLF line endings, and a `\` followed by CR is asking for trouble.)
	@echo "Verification:"
	@grep -q '#include <set>' $(LIBZIM_SRC)/src/search.cpp || { echo "FAIL: <set> include missing in $(LIBZIM_SRC)/src/search.cpp"; exit 1; }
	@grep -q '#include <set>' $(LIBZIM_SRC)/src/suggestion.cpp || { echo "FAIL: <set> include missing in $(LIBZIM_SRC)/src/suggestion.cpp"; exit 1; }
	@grep -q 'supportedLangs' $(LIBZIM_SRC)/src/search.cpp || { echo "FAIL: stemmer whitelist not applied in $(LIBZIM_SRC)/src/search.cpp"; exit 1; }
	@grep -q 'supportedLangs' $(LIBZIM_SRC)/src/suggestion.cpp || { echo "FAIL: stemmer whitelist not applied in $(LIBZIM_SRC)/src/suggestion.cpp"; exit 1; }
	@grep -q 'm_stemmer = Xapian::Stem(languageLocale.getLanguage());' $(LIBZIM_SRC)/src/search.cpp && { echo "FAIL: unpatched stemmer call remains in $(LIBZIM_SRC)/src/search.cpp"; exit 1; } || true
	@grep -q 'm_stemmer = Xapian::Stem(languageLocale.getLanguage());' $(LIBZIM_SRC)/src/suggestion.cpp && { echo "FAIL: unpatched stemmer call remains in $(LIBZIM_SRC)/src/suggestion.cpp"; exit 1; } || true
	@test -f $(LIBZIM_SRC)/src/xapian/myhtmlparse.cc || { echo "FAIL: $(LIBZIM_SRC)/src/xapian/myhtmlparse.cc not found - did the source layout change?"; exit 1; }
	@grep -nE 'throw[^;]*\b(true|newcharset)\b' $(LIBZIM_SRC)/src/xapian/myhtmlparse.cc && { echo "FAIL: problematic throws remain in $(LIBZIM_SRC)/src/xapian/myhtmlparse.cc (shown above)"; exit 1; } || true
	@echo "  OK: <set> include, stemmer whitelist (search.cpp + suggestion.cpp), no bare throws (myhtmlparse.cc)"
	@echo "✅ Essential patches applied successfully"

	# Build libzim. Examples are not needed for WASM, hence -Dexamples=false.
	# (Tests are skipped automatically: libzim gates them on `not meson.is_cross_build()`.)
	cd $(LIBZIM_SRC)/ ; PKG_CONFIG_PATH=/src/build/lib/pkgconfig meson --prefix=`pwd`/../build --cross-file=../emscripten-crosscompile.ini . build -DUSE_MMAP=false -Dexamples=false
	cd $(LIBZIM_SRC)/ ; ninja -C build
	cd $(LIBZIM_SRC)/ ; ninja -C build install

# Development WASM version for testing with WORKERFS and NODEFS, completely unoptimized
libzim-wasm.dev.js: libzim_bindings.cpp prejs_file_api.js postjs_file_api.js
	em++ -o libzim-wasm.dev.js --bind libzim_bindings.cpp -I/src/build/include -L/src/build/lib -lzim -llzma -lzstd -lxapian -lz -licui18n -licuuc -licudata -lpthread -lm -fdiagnostics-color=always -pipe -Wall -Winvalid-pch -Wnon-virtual-dtor -Werror -std=c++14 -O0 -g --pre-js prejs_file_api.js --post-js postjs_file_api.js -s WASM=1 -s DYNAMIC_EXECUTION=0 -s DISABLE_EXCEPTION_CATCHING=0 -s EXCEPTION_DEBUG=1 -s SUPPORT_LONGJMP=1 -s "EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','err','ALLOC_STACK','out']" -s DEMANGLE_SUPPORT=1 -s INITIAL_MEMORY=83886080 -s ALLOW_MEMORY_GROWTH=1 -lworkerfs.js -lnodefs.js
	cp libzim-wasm.dev.* tests/prototype/

# Development ASM version for testing with WORKERFS and NODEFS, completely unoptimized
libzim-asm.dev.js: libzim_bindings.cpp prejs_file_api.js postjs_file_api.js
	em++ -o libzim-asm.dev.js --bind libzim_bindings.cpp -I/src/build/include -L/src/build/lib -lzim -llzma -lzstd -lxapian -lz -licui18n -licuuc -licudata -lm -fdiagnostics-color=always -pipe -Wall -Winvalid-pch -Wnon-virtual-dtor -Werror -std=c++14 -O0 -g --pre-js prejs_file_api.js --post-js postjs_file_api.js -s WASM=0 --memory-init-file 0 -s DYNAMIC_EXECUTION=0 -s DISABLE_EXCEPTION_CATCHING=0 -s EXCEPTION_DEBUG=1 -s SUPPORT_LONGJMP=1 -s "EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','err','ALLOC_STACK','out']" -s DEMANGLE_SUPPORT=1 -s INITIAL_MEMORY=83886080 -s ALLOW_MEMORY_GROWTH=1 -lworkerfs.js -lnodefs.js
	cp libzim-asm.dev.* tests/prototype/

# Production WASM version with WORKERFS and NODEFS, optimized and packed
libzim-wasm.js: libzim_bindings.cpp prejs_file_api.js postjs_file_api.js
	em++ -o libzim-wasm.js --bind libzim_bindings.cpp -I/src/build/include -L/src/build/lib -lzim -llzma -lzstd -lxapian -lz -licui18n -lpthread -licuuc -licudata -O3 --pre-js prejs_file_api.js --post-js postjs_file_api.js -s WASM=1 -s "EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','err','ALLOC_STACK','out']" -s INITIAL_MEMORY=83886080 -s DISABLE_EXCEPTION_CATCHING=0 -s SUPPORT_LONGJMP=1 -s ALLOW_MEMORY_GROWTH=1 -s DYNAMIC_EXECUTION=0 -lworkerfs.js -lnodefs.js -std=c++14
	cp libzim-wasm.* tests/prototype/

# Production ASM version with WORKERFS and NODEFS, optimized and packed
libzim-asm.js: libzim_bindings.cpp prejs_file_api.js postjs_file_api.js
	em++ -o libzim-asm.js --bind libzim_bindings.cpp -I/src/build/include -L/src/build/lib -lzim -llzma -lzstd -lxapian -lz -licui18n -licuuc -licudata -O3 --pre-js prejs_file_api.js --post-js postjs_file_api.js -s WASM=0 --memory-init-file 0 -s MIN_EDGE_VERSION=40 -s "EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','err','ALLOC_STACK','out']" -s DISABLE_EXCEPTION_CATCHING=0 -s SUPPORT_LONGJMP=1 -s INITIAL_MEMORY=83886080 -s ALLOW_MEMORY_GROWTH=1 -s DYNAMIC_EXECUTION=0 -lworkerfs.js -lnodefs.js -std=c++14
	cp libzim-asm.* tests/prototype/

# Test case: for testing large files
large_file_access.js: test_file_bindings.cpp prejs_test_file_access.js postjs_test_file_access.js
	em++ -o large_file_access.js --bind test_file_bindings.cpp -std=c++14 -O0 --pre-js prejs_test_file_access.js --post-js postjs_test_file_access.js -lworkerfs.js
	cp large_file_access.* tests/test_large_file_access/

clean :
	rm -rf xz-*
	rm -rf zstd-*
	rm -rf zlib-*
	rm -rf xapian-core-*
	rm -rf icu*
	rm -rf large_file_*
	rm -rf libzim-*
	rm -rf libzim_wasm-*
	rm -rf build

.PHONY : all clean