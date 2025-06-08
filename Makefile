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
	# @echo "=== APPLYING ROBUST WASM SNIPPET FIX ==="

	# SEARCH_ITERATOR.CPP - Use node-libzim approach: robust exception handling for WASM
	@echo "=== APPLYING WASM-SAFE HTML PARSER PATCHES ==="
	# Patch MyHtmlParser to remove problematic exceptions
	@echo "Patching myhtmlparse.cc to remove bool exceptions..."
	# Replace the "throw true" in closing_tag for </body>
	sed -i 's/throw true;/return;/g' libzim-9.3.0/src/xapian/myhtmlparse.cc
	# Replace the "throw newcharset" with a more graceful approach
	sed -i 's/throw newcharset;/return;/g' libzim-9.3.0/src/xapian/myhtmlparse.cc	

	# Verify the patches were applied
	@echo "Checking for remaining problematic throws..."
	@grep -n "throw.*true\|throw.*false\|throw.*newcharset" libzim-9.3.0/src/xapian/myhtmlparse.cc || echo "All throws removed successfully!"
	@echo "MyHtmlParser patched for WASM compatibility"
	@echo ""

	@echo "=== APPLYING DIAGNOSTIC LOGGING PATCHES ==="
	# Add iostream header for debug output
	sed -i '/#include <zim\/error.h>/a #include <iostream>' libzim-9.3.0/src/search_iterator.cpp
	# Create the diagnostic getSnippet method in a temporary file
	printf '%s\n' \
	'std::string SearchIterator::getSnippet() const {' \
	'    std::cerr << "[SNIPPET DEBUG] getSnippet() called" << std::endl;' \
	'    if ( ! internal ) {' \
	'        std::cerr << "[SNIPPET DEBUG] No internal data, returning empty" << std::endl;' \
	'        return "";' \
	'    }' \
	'' \
	'    try {' \
	'        // Check for stored snippets first' \
	'        std::cerr << "[SNIPPET DEBUG] Checking for stored snippets..." << std::endl;' \
	'        if ( ! internal->mp_internalDb->hasValuesmap() )' \
	'        {' \
	'            std::cerr << "[SNIPPET DEBUG] No valuesmap, checking legacy value slot 1" << std::endl;' \
	'            std::string stored_snippet = internal->get_document().get_value(1);' \
	'            if ( ! stored_snippet.empty() ) {' \
	'                std::cerr << "[SNIPPET DEBUG] Found stored snippet: " << stored_snippet.length() << " chars" << std::endl;' \
	'                return stored_snippet;' \
	'            }' \
	'            std::cerr << "[SNIPPET DEBUG] No stored snippet in legacy slot" << std::endl;' \
	'        }' \
	'        else if ( internal->mp_internalDb->hasValue("snippet") )' \
	'        {' \
	'            std::cerr << "[SNIPPET DEBUG] Has snippet value in valuesmap" << std::endl;' \
	'            auto snippet = internal->get_document().get_value(internal->mp_internalDb->valueSlot("snippet"));' \
	'            std::cerr << "[SNIPPET DEBUG] Found stored snippet: " << snippet.length() << " chars" << std::endl;' \
	'            return snippet;' \
	'        }' \
	'' \
	'        std::cerr << "[SNIPPET DEBUG] No stored snippet, generating from content..." << std::endl;' \
	'        Entry& entry = internal->get_entry();' \
	'' \
	'        try {' \
	'            std::cerr << "[SNIPPET DEBUG] Getting entry item data..." << std::endl;' \
	'            zim::MyHtmlParser htmlParser;' \
	'            std::string content = entry.getItem().getData();' \
	'            std::cerr << "[SNIPPET DEBUG] Got content: " << content.length() << " bytes" << std::endl;' \
	'' \
	'            try {' \
	'                std::cerr << "[SNIPPET DEBUG] Starting HTML parsing..." << std::endl;' \
	'                htmlParser.parse_html(content, "UTF-8", true);' \
	'                std::cerr << "[SNIPPET DEBUG] HTML parsing completed successfully" << std::endl;' \
	'            } catch (const std::string& s) {' \
	'                std::cerr << "[SNIPPET DEBUG] Caught string exception (charset): " << s << std::endl;' \
	'            } catch (const std::exception& e) {' \
	'                std::cerr << "[SNIPPET DEBUG] Caught std exception during HTML parsing: " << e.what() << std::endl;' \
	'            } catch (...) {' \
	'                std::cerr << "[SNIPPET DEBUG] Caught unknown exception during HTML parsing" << std::endl;' \
	'            }' \
	'' \
	'            std::cerr << "[SNIPPET DEBUG] HTML dump length after parsing: " << htmlParser.dump.length() << " chars" << std::endl;' \
	'            if (htmlParser.dump.length() > 0) {' \
	'                std::cerr << "[SNIPPET DEBUG] First 100 chars of dump: " << htmlParser.dump.substr(0, 100) << "..." << std::endl;' \
	'            }' \
	'' \
	'            try {' \
	'                std::cerr << "[SNIPPET DEBUG] Calling Xapian snippet generation..." << std::endl;' \
	'                std::cerr << "[SNIPPET DEBUG] MSet pointer valid: " << (internal->mp_mset != nullptr) << std::endl;' \
	'                std::cerr << "[SNIPPET DEBUG] Stemmer language: " << internal->mp_internalDb->m_stemmer.get_description() << std::endl;' \
	'            	' \
	'                std::string snippet = internal->mp_mset->snippet(htmlParser.dump,' \
	'                                              500,' \
	'                                              internal->mp_internalDb->m_stemmer,' \
	'                                              0);' \
	'            	' \
	'                std::cerr << "[SNIPPET DEBUG] Xapian snippet generated successfully: " << snippet.length() << " chars" << std::endl;' \
	'                if (snippet.length() > 0) {' \
	'                    std::cerr << "[SNIPPET DEBUG] Snippet preview: " << snippet.substr(0, 100) << "..." << std::endl;' \
	'                }' \
	'                return snippet;' \
	'            } catch (const Xapian::Error& e) {' \
	'                std::cerr << "[SNIPPET DEBUG] Caught Xapian::Error: " << e.get_description() << std::endl;' \
	'                std::cerr << "[SNIPPET DEBUG] Error type: " << e.get_type() << ", context: " << e.get_context() << std::endl;' \
	'            } catch (const std::exception& e) {' \
	'                std::cerr << "[SNIPPET DEBUG] Caught std exception from Xapian: " << e.what() << std::endl;' \
	'            } catch (...) {' \
	'                std::cerr << "[SNIPPET DEBUG] Caught unknown exception from Xapian snippet()" << std::endl;' \
	'            }' \
	'' \
	'            std::cerr << "[SNIPPET DEBUG] Falling back to manual snippet extraction" << std::endl;' \
	'            std::string htmlText = htmlParser.dump;' \
	'            if (htmlText.empty()) {' \
	'                std::cerr << "[SNIPPET DEBUG] HTML dump empty, using raw content" << std::endl;' \
	'                htmlText = content;' \
	'            }' \
	'' \
	'            if (htmlText.length() > 500) {' \
	'                std::string fallback = htmlText.substr(0, 500) + "...";' \
	'                std::cerr << "[SNIPPET DEBUG] Returning fallback snippet: " << fallback.length() << " chars" << std::endl;' \
	'                return fallback;' \
	'            } else {' \
	'                std::cerr << "[SNIPPET DEBUG] Returning full text as snippet: " << htmlText.length() << " chars" << std::endl;' \
	'                return htmlText;' \
	'            }' \
	'        } catch (const std::exception& e) {' \
	'            std::cerr << "[SNIPPET DEBUG] Caught exception in outer try: " << e.what() << std::endl;' \
	'            return "";' \
	'        } catch (...) {' \
	'            std::cerr << "[SNIPPET DEBUG] Caught unknown exception in outer try" << std::endl;' \
	'            return "";' \
	'        }' \
	'    } catch (Xapian::DatabaseError& e) {' \
	'        std::cerr << "[SNIPPET DEBUG] Caught DatabaseError: " << e.get_description() << std::endl;' \
	'        throw zim::ZimFileFormatError(e.get_description());' \
	'    } catch (const std::exception& e) {' \
	'        std::cerr << "[SNIPPET DEBUG] Caught exception at top level: " << e.what() << std::endl;' \
	'        return "";' \
	'    } catch (...) {' \
	'        std::cerr << "[SNIPPET DEBUG] Caught unknown exception at top level" << std::endl;' \
	'        return "";' \
	'    }' \
	'}' \
	> libzim-9.3.0/src/snippet_diagnostic.tmp
	# Use sed to remove the original getSnippet method completely, then append our diagnostic version
	@echo "Replacing getSnippet() method with diagnostic version..."
	@sed '/^std::string SearchIterator::getSnippet() const {$$/,/^}$$/d' libzim-9.3.0/src/search_iterator.cpp > libzim-9.3.0/src/search_iterator_temp.cpp
	@sed '/^} \/\/ namespace zim$$/i\\n' libzim-9.3.0/src/search_iterator_temp.cpp | sed '/^} \/\/ namespace zim$$/e cat libzim-9.3.0/src/snippet_diagnostic.tmp' > libzim-9.3.0/src/search_iterator.cpp
	@rm libzim-9.3.0/src/snippet_diagnostic.tmp
	@echo "=== DIAGNOSTIC PATCHES APPLIED ==="
	@echo "When you run the test after building, look for [SNIPPET DEBUG] messages in the console"
	
	@echo "=== APPLYING SUGGESTION ITERATOR DIAGNOSTIC PATCHES ==="
	# Add iostream header for debug output to suggestion_iterator.cpp
	sed -i '/#include <stdexcept>/a #include <iostream>' libzim-9.3.0/src/suggestion_iterator.cpp
	
	# Replace the simple getIndexSnippet method with a diagnostic version
	sed -i '/^std::string SuggestionIterator::getIndexSnippet() const {$$/,/^}$$/c\
	std::string SuggestionIterator::getIndexSnippet() const {\
		if (! mp_internal) {\
			return "";\
		}\
	\
		try {\
			std::cerr << "[SUGGESTION DEBUG] Calling Xapian snippet for suggestion..." << std::endl;\
			std::string snippet = mp_internal->mp_mset->snippet(getIndexTitle(), 500, mp_internal->mp_internalDb->m_stemmer);\
			std::cerr << "[SUGGESTION DEBUG] Suggestion snippet generated: " << snippet.length() << " chars" << std::endl;\
			if (snippet.length() > 0) {\
				std::cerr << "[SUGGESTION DEBUG] Snippet preview: " << snippet.substr(0, 50) << "..." << std::endl;\
			}\
			return snippet;\
		} catch (const Xapian::Error& e) {\
			std::cerr << "[SUGGESTION DEBUG] Xapian error in snippet generation: " << e.get_description() << std::endl;\
			return "";\
		} catch (const std::exception& e) {\
			std::cerr << "[SUGGESTION DEBUG] Exception in snippet generation: " << e.what() << std::endl;\
			return "";\
		} catch (...) {\
			std::cerr << "[SUGGESTION DEBUG] Unknown exception in snippet generation" << std::endl;\
			return "";\
		}\
	}' libzim-9.3.0/src/suggestion_iterator.cpp

	@echo "Suggestion iterator patched with detailed exception handling"
	@echo ""

	@echo "=== VERIFYING LIBZIM BUILD ==="	
	@echo "search.cpp - Headers added: $$(grep -c '#include <set>' libzim-*/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Headers added: $$(grep -c '#include <set>' libzim-*/src/suggestion.cpp || echo '0')"
	@echo "search.cpp - Whitelist added: $$(grep -c 'supportedLangs' libzim-*/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Whitelist added: $$(grep -c 'supportedLangs' libzim-*/src/suggestion.cpp || echo '0')"
	@echo "search_iterator.cpp - WASM FALLBACK applied: $$(grep -c 'WASM FALLBACK' libzim-*/src/search_iterator.cpp || echo '0')"
	@echo "search_iterator.cpp - Robust exception handling: $$(grep -c 'HTML parser exceptions' libzim-*/src/search_iterator.cpp || echo '0')"
	@echo "search_iterator.cpp - Smart context fallback: $$(grep -c 'extract context manually' libzim-*/src/search_iterator.cpp || echo '0')"
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