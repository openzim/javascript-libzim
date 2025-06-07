SHELL := /bin/bash

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
	# Origin: https://tukaani.org/xz/xz-5.2.4.tar.gz
	[ ! -f xz-*.tar.gz ] && wget -N https://dev.kiwix.org/kiwix-build/xz-5.2.4.tar.gz || true
	tar xf xz-*.tar.gz
	cd xz-*/ ; ./autogen.sh
	cd xz-*/ ; emconfigure ./configure --prefix=`pwd`/../build
	cd xz-*/ ; emmake make 
	cd xz-*/ ; emmake make install
	
build/lib/libz.a :
	# Version not yet available in dev.kiwix.org
	wget -N https://zlib.net/zlib-1.3.1.tar.gz
	tar xf zlib-*.tar.gz
	cd zlib-*/ ; emconfigure ./configure --prefix=`pwd`/../build
	cd zlib-*/ ; emmake make
	cd zlib-*/ ; emmake make install
	
build/lib/libzstd.a :
	# Origin: https://github.com/facebook/zstd/releases/download/v1.4.4/zstd-1.4.4.tar.gz 
	[ ! -f zstd-*.tar.gz ] && wget -N https://dev.kiwix.org/kiwix-build/zstd-1.5.2.tar.gz || true
	tar xf zstd-*.tar.gz
	cd zstd-*/build/meson ; meson setup --cross-file=../../../emscripten-crosscompile.ini -Dbin_programs=false -Dbin_contrib=false -Dzlib=disabled -Dlzma=disabled -Dlz4=disabled --prefix=`pwd`/../../../build --libdir=lib builddir
	cd zstd-*/build/meson/builddir ; ninja
	cd zstd-*/build/meson/builddir ; ninja install
	
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
	# Origin: https://oligarchy.co.uk/xapian/1.4.18/xapian-core-1.4.18.tar.xz
	# Also: https://dev.kiwix.org/kiwix-build/xapian-core-1.4.23.tar.xz
	[ ! -f xapian-*.tar.gz ] && wget -N https://oligarchy.co.uk/xapian/1.4.29/xapian-core-1.4.29.tar.xz || true
	tar xf xapian-core-*.tar.xz
        # Some options coming from https://github.com/xapian/xapian/tree/master/xapian-core/emscripten
	# cd xapian-core-1.4.18; emconfigure ./configure --prefix=`pwd`/../build "CFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" "CXXFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" CPPFLAGS='-DFLINTLOCK_USE_FLOCK' CXXFLAGS='-Oz -s USE_ZLIB=1 -fno-rtti' --disable-backend-honey --disable-backend-inmemory --disable-shared --disable-backend-remote
	cd xapian-core-*/ ; emconfigure ./configure --prefix=`pwd`/../build "CFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" "CXXFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" --disable-shared --disable-backend-remote
	cd xapian-core-*/ ; emmake make "CFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib -std=c++14" "CXXFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib -std=c++14"
	cd xapian-core-*/ ; emmake make install

build/lib/libzim.a : build/lib/liblzma.so build/lib/libz.a build/lib/libzstd.a build/lib/libicudata.so build/lib/libxapian.a
	# Origin: wget -N --content-disposition https://github.com/openzim/libzim/archive/7.2.2.tar.gz
	[ ! -f libzim-*.tar.xz ] && wget -N https://download.openzim.org/release/libzim/libzim-9.3.0.tar.xz || true
	tar xf libzim-*.tar.xz
	@echo "=== APPLYING WHITELIST-BASED LIBZIM PATCHES ==="
	# Add required header for std::set
	sed -i '/#include <unicode\/locid.h>/a #include <set>' libzim-*/src/search.cpp
	sed -i '/#include <unicode\/locid.h>/a #include <set>' libzim-*/src/suggestion.cpp
	# SEARCH.CPP - Whitelist all Xapian-supported languages, use 'none' for all others
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); static const std::set<std::string> supportedLangs = {"ar", "hy", "eu", "ca", "da", "nl", "en", "fi", "fr", "de", "el", "hi", "hu", "id", "ga", "it", "lt", "ne", "no", "pt", "ro", "ru", "sr", "es", "sv", "tr"}; if (supportedLangs.find(stemLang) != supportedLangs.end()) { m_stemmer = Xapian::Stem(stemLang); } else { m_stemmer = Xapian::Stem("none"); } }/' libzim-*/src/search.cpp
	# SUGGESTION.CPP - Whitelist all Xapian-supported languages, use 'none' for all others
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); static const std::set<std::string> supportedLangs = {"ar", "hy", "eu", "ca", "da", "nl", "en", "fi", "fr", "de", "el", "hi", "hu", "id", "ga", "it", "lt", "ne", "no", "pt", "ro", "ru", "sr", "es", "sv", "tr"}; if (supportedLangs.find(stemLang) != supportedLangs.end()) { m_stemmer = Xapian::Stem(stemLang); } else { m_stemmer = Xapian::Stem("none"); } }/' libzim-*/src/suggestion.cpp
	@echo "=== APPLYING SEARCH SNIPPETS WASM FIX ==="
	# SEARCH_ITERATOR.CPP - Complete fix for HTML parser exceptions AND Xapian snippet generation in WASM
	# This patch addresses both HTML parser bool exceptions AND Xapian snippet() failures in WASM environment
	# Replace the problematic empty catch block with properly formatted catch blocks for HTML parser exceptions
	sed -i 's/} catch (...) {}/} catch (bool) {\n            \/\/ HTML parser control flow exceptions (normal behavior)\n        } catch (const std::string\&) {\n            \/\/ HTML parser error exceptions\n        } catch (...) {\n            \/\/ Other exceptions\n        }/' libzim-*/src/search_iterator.cpp
	# Wrap the Xapian snippet() call with try-catch and fallback logic for WASM
	sed -i 's/return internal->mp_mset->snippet(/try {\n                return internal->mp_mset->snippet(/' libzim-*/src/search_iterator.cpp
	# Add WASM fallback snippet generation when Xapian snippet() fails
	sed -i '/\/\*flags=\*\/0);/a\            } catch (...) {\n                \/\/ WASM FALLBACK: Xapian snippet failed, use simple text fallback\n                std::string textContent = htmlParser.dump;\n                if (textContent.empty()) {\n                    return "";\n                }\n                \/\/ Simple snippet: first 500 chars with ellipsis\n                if (textContent.length() > 500) {\n                    return textContent.substr(0, 500) + "...";\n                } else {\n                    return textContent;\n                }\n            }' libzim-*/src/search_iterator.cpp
	@echo "=== VERIFYING PATCHES APPLIED ==="
	@echo "search.cpp - Headers added: $$(grep -c '#include <set>' libzim-*/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Headers added: $$(grep -c '#include <set>' libzim-*/src/suggestion.cpp || echo '0')"
	@echo "search.cpp - Whitelist added: $$(grep -c 'supportedLangs' libzim-*/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Whitelist added: $$(grep -c 'supportedLangs' libzim-*/src/suggestion.cpp || echo '0')"
	@echo "search_iterator.cpp - WASM FALLBACK comments: $$(grep -c 'WASM FALLBACK' libzim-*/src/search_iterator.cpp || echo '0')"
	@echo "search_iterator.cpp - Exception handlers: $$(grep -c 'catch.*{' libzim-*/src/search_iterator.cpp || echo '0')"
	@echo "search_iterator.cpp - Snippet fallback: $$(grep -c 'textContent.substr' libzim-*/src/search_iterator.cpp || echo '0')"
	# It's no use trying to compile examples
	sed -i -e "s/^subdir('examples')//" libzim-*/meson.build
	cd libzim-*/ ; PKG_CONFIG_PATH=/src/build/lib/pkgconfig meson --prefix=`pwd`/../build --cross-file=../emscripten-crosscompile.ini . build -DUSE_MMAP=false
	cd libzim-*/ ; ninja -C build
	cd libzim-*/ ; ninja -C build install

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