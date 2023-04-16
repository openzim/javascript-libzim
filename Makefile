SHELL := /bin/bash

all: build/lib/libzim.a libzim-wasm.dev.js libzim-asm.dev.js libzim-wasm.js libzim-asm.js large_file_access.js

release: libzim-asm.js libzim-wasm.js libzim-asm.dev.js libzim-wasm.dev.js large_file_access.js

nightly: libzim-asm.js libzim-wasm.js libzim-asm.dev.js libzim-wasm.dev.js large_file_access.js

libzim_release:
	wget -N $$(wget -q https://download.openzim.org/release/libzim/feed.xml -O - | grep -E -o -m1 "<link>[^<]+wasm-emscripten[^<]+</link>" | sed -E "s:</?link>::g")
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
	tar xf xz-5.2.4.tar.gz
	cd xz-5.2.4 ; ./autogen.sh
	cd xz-5.2.4 ; emconfigure ./configure --prefix=`pwd`/../build
	cd xz-5.2.4 ; emmake make 
	cd xz-5.2.4 ; emmake make install
	
build/lib/libz.a :
 	# Version not yet available in dev.kiwix.org
	wget -N https://zlib.net/zlib-1.2.13.tar.gz
	tar xf zlib-1.2.13.tar.gz
	cd zlib-1.2.13 ; emconfigure ./configure --prefix=`pwd`/../build
	cd zlib-1.2.13 ; emmake make
	cd zlib-1.2.13 ; emmake make install
	
build/lib/libzstd.a :
	# Origin: https://github.com/facebook/zstd/releases/download/v1.4.4/zstd-1.4.4.tar.gz 
	[ ! -f zstd-*.tar.gz ] && wget -N https://dev.kiwix.org/kiwix-build/zstd-1.5.2.tar.gz || true
	tar xf zstd-1.5.2.tar.gz
	cd zstd-1.5.2/build/meson ; meson setup --cross-file=../../../emscripten-crosscompile.ini -Dbin_programs=false -Dbin_contrib=false -Dzlib=disabled -Dlzma=disabled -Dlz4=disabled --prefix=`pwd`/../../../build --libdir=lib builddir
	cd zstd-1.5.2/build/meson/builddir ; ninja
	cd zstd-1.5.2/build/meson/builddir ; ninja install
	
build/lib/libicudata.so : 
	# Version not yet available in dev.kiwix.org
	wget -N https://github.com/unicode-org/icu/releases/download/release-71-1/icu4c-71_1-src.tgz
	tar xf icu4c-71_1-src.tgz
	# It's no use trying to compile examples
	sed -i -e 's/^SUBDIRS =\(.*\)$$(DATASUBDIR) $$(EXTRA) $$(SAMPLE) $$(TEST)\(.*\)/SUBDIRS =\1\2/' icu/source/Makefile.in
	cd icu/source ; emconfigure ./configure --prefix=`pwd`/../../build
	cd icu/source ; emmake make 
	cd icu/source ; emmake make install

build/lib/libxapian.a : build/lib/libz.a
	# Origin: https://oligarchy.co.uk/xapian/1.4.18/xapian-core-1.4.18.tar.xz
	[ ! -f xapian-*.tar.gz ] && wget -N https://dev.kiwix.org/kiwix-build/xapian-core-1.4.18.tar.xz || true
	tar xf xapian-core-1.4.18.tar.xz
        # Some options coming from https://github.com/xapian/xapian/tree/master/xapian-core/emscripten
	# cd xapian-core-1.4.18; emconfigure ./configure --prefix=`pwd`/../build "CFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" "CXXFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" CPPFLAGS='-DFLINTLOCK_USE_FLOCK' CXXFLAGS='-Oz -s USE_ZLIB=1 -fno-rtti' --disable-backend-honey --disable-backend-inmemory --disable-shared --disable-backend-remote
	cd xapian-core-1.4.18; emconfigure ./configure --prefix=`pwd`/../build "CFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" "CXXFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib" --disable-shared --disable-backend-remote
	cd xapian-core-1.4.18; emmake make "CFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib -std=c++11" "CXXFLAGS=-I`pwd`/../build/include -L`pwd`/../build/lib -std=c++11"
	cd xapian-core-1.4.18; emmake make install

build/lib/libzim.a : build/lib/liblzma.so build/lib/libz.a build/lib/libzstd.a build/lib/libicudata.so build/lib/libxapian.a
	# Origin: wget -N --content-disposition https://github.com/openzim/libzim/archive/7.2.2.tar.gz
	[ ! -f libzim-*.tar.xz ] && wget -N https://download.openzim.org/release/libzim/libzim-8.1.0.tar.xz || true
	tar xf libzim-8.1.0.tar.xz
	# It's no use trying to compile examples
	sed -i -e "s/^subdir('examples')//" libzim-8.1.0/meson.build
	cd libzim-8.1.0; PKG_CONFIG_PATH=/src/build/lib/pkgconfig meson --prefix=`pwd`/../build --cross-file=../emscripten-crosscompile.ini . build -DUSE_MMAP=false
	cd libzim-8.1.0; ninja -C build
	cd libzim-8.1.0; ninja -C build install

# Development WASM version for testing with WORKERFS and NODEFS, completely unoptimized
libzim-wasm.dev.js: libzim_bindings.cpp prejs_file_api.js postjs_file_api.js
	em++ -o libzim-wasm.dev.js --bind libzim_bindings.cpp -I/src/build/include -L/src/build/lib -lzim -llzma -lzstd -lxapian -lz -licui18n -licuuc -licudata -lpthread -lm -fdiagnostics-color=always -pipe -Wall -Winvalid-pch -Wnon-virtual-dtor -Werror -std=c++11 -O0 -g --pre-js prejs_file_api.js --post-js postjs_file_api.js -s WASM=1 -s DYNAMIC_EXECUTION=0 -s DISABLE_EXCEPTION_CATCHING=0 -s "EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','printErr','ALLOC_STACK','print']" -s DEMANGLE_SUPPORT=1 -s INITIAL_MEMORY=83886080 -s ALLOW_MEMORY_GROWTH=1 -lworkerfs.js -lnodefs.js
	cp libzim-wasm.dev.* tests/prototype/

# Development ASM version for testing with WORKERFS and NODEFS, completely unoptimized
libzim-asm.dev.js: libzim_bindings.cpp prejs_file_api.js postjs_file_api.js
	em++ -o libzim-asm.dev.js --bind libzim_bindings.cpp -I/src/build/include -L/src/build/lib -lzim -llzma -lzstd -lxapian -lz -licui18n -licuuc -licudata -lm -fdiagnostics-color=always -pipe -Wall -Winvalid-pch -Wnon-virtual-dtor -Werror -std=c++11 -O0 -g --pre-js prejs_file_api.js --post-js postjs_file_api.js -s WASM=0 --memory-init-file 0 -s DISABLE_EXCEPTION_CATCHING=0 -s DYNAMIC_EXECUTION=0 -s "EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','printErr','ALLOC_STACK','print']" -s DEMANGLE_SUPPORT=1 -s INITIAL_MEMORY=83886080 -s ALLOW_MEMORY_GROWTH=1 -lworkerfs.js -lnodefs.js

# Production WASM version with WORKERFS and NODEFS, optimized and packed
libzim-wasm.js: libzim_bindings.cpp prejs_file_api.js postjs_file_api.js
	em++ -o libzim-wasm.js --bind libzim_bindings.cpp -I/src/build/include -L/src/build/lib -lzim -llzma -lzstd -lxapian -lz -licui18n -lpthread -licuuc -licudata -O3 --pre-js prejs_file_api.js --post-js postjs_file_api.js -s WASM=1 -s "EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','printErr','ALLOC_STACK','print']" -s INITIAL_MEMORY=83886080 -s ALLOW_MEMORY_GROWTH=1 -s DYNAMIC_EXECUTION=0 -lworkerfs.js -lnodefs.js

# Production ASM version with WORKERFS and NODEFS, optimized and packed
libzim-asm.js: libzim_bindings.cpp prejs_file_api.js postjs_file_api.js
	em++ -o libzim-asm.js --bind libzim_bindings.cpp -I/src/build/include -L/src/build/lib -lzim -llzma -lzstd -lxapian -lz -licui18n -licuuc -licudata -O3 --pre-js prejs_file_api.js --post-js postjs_file_api.js -s WASM=0 --memory-init-file 0 -s MIN_EDGE_VERSION=40 -s "EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','printErr','ALLOC_STACK','print']" -s INITIAL_MEMORY=83886080 -s ALLOW_MEMORY_GROWTH=1 -s DYNAMIC_EXECUTION=0 -lworkerfs.js -lnodefs.js

# Test case: for testing large files
large_file_access.js: test_file_bindings.cpp prejs_test_file_access.js postjs_test_file_access.js
	em++ -o large_file_access.js --bind test_file_bindings.cpp -std=c++11 -O0 --pre-js prejs_test_file_access.js --post-js postjs_test_file_access.js -lworkerfs.js
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
