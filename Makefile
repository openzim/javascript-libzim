all: demo_file_api.js
lzma : 
	wget --no-check-certificate https://tukaani.org/xz/xz-5.2.4.tar.gz
	tar xf xz-5.2.4.tar.gz
	cd xz-5.2.4 ; ./autogen.sh
	cd xz-5.2.4 ; emconfigure ./configure --prefix=`pwd`/../lzma
	cd xz-5.2.4 ; emmake make 
	cd xz-5.2.4 ; emmake make install
	
z : 
	wget --no-check-certificate http://zlib.net/zlib-1.2.11.tar.gz
	tar xf zlib-1.2.11.tar.gz
	cd zlib-1.2.11 ; emconfigure ./configure --prefix=`pwd`/../z
	cd zlib-1.2.11 ; emmake make 
	cd zlib-1.2.11 ; emmake make install
	
icubuild : 
	wget --no-check-certificate https://github.com/unicode-org/icu/releases/download/release-63-2/icu4c-63_2-src.tgz
	tar xf icu4c-63_2-src.tgz
	# Quick and dirty way to make ICU handle Double-conversion, and to skip unnecessary compilation steps
	cd icu ; patch -p1 <../patch_icu_for_emscripten.patch
	cd icu/source ; emconfigure ./configure --prefix=`pwd`/../../icubuild
	cd icu/source ; emmake make 
	cd icu/source ; emmake make install

xapian : z
	wget --no-check-certificate https://oligarchy.co.uk/xapian/1.4.10/xapian-core-1.4.10.tar.xz
	tar xf xapian-core-1.4.10.tar.xz
	cd xapian-core-1.4.10; emconfigure ./configure --prefix=`pwd`/../xapian "CFLAGS=-I`pwd`/../z/include -L`pwd`/../z/lib" "CXXFLAGS=-I`pwd`/../z/include -L`pwd`/../z/lib" --disable-backend-remote
	cd xapian-core-1.4.10; emmake make "CFLAGS=-I`pwd`/../z/include -L`pwd`/../z/lib -std=c++11" "CXXFLAGS=-I`pwd`/../z/include -L`pwd`/../z/lib -std=c++11"
	cd xapian-core-1.4.10; emmake make install

libzimbuild : lzma z icubuild xapian
	wget --no-check-certificate -O libzim-4.0.5.tar.gz https://github.com/openzim/libzim/archive/4.0.5.tar.gz
	tar xf libzim-4.0.5.tar.gz
	cd libzim-4.0.5; meson . build
	# Quick and dirty way to tell ninja to compile with emscripten,
	# with the dependencies compiled above,
	# and to remove unnecessary compilation steps
	sed -i -e 's/ c++ / em++ /g' libzim-4.0.5/build/build.ninja
	sed -i -e 's/ cc / emcc /g' libzim-4.0.5/build/build.ninja
	sed -i -e 's#\(build all: phony \).*\(src/libzim.so...... \).*#\1\2#' libzim-4.0.5/build/build.ninja
	# Depending on the environment, the parameters can be surrounded by quotes or not
	sed -i -e "s/'-Iinclude'/'-Iinclude' '-I..\/..\/lzma\/include' '-I..\/..\/z\/include' '-I..\/..\/icubuild\/include' '-I..\/..\/xapian\/include'/g" libzim-4.0.5/build/build.ninja
	sed -i -e "s/ -Iinclude / -Iinclude -I..\/..\/lzma\/include -I..\/..\/z\/include -I..\/..\/icubuild\/include -I..\/..\/xapian\/include /g" libzim-4.0.5/build/build.ninja
	sed -i -e 's/^\( LINK_ARGS =.*\)/\1 -L..\/..\/lzma\/lib -L..\/..\/z\/lib -L..\/..\/icubuild\/lib -L..\/..\/xapian\/lib/g' libzim-4.0.5/build/build.ninja
	# Quick and dirty way to disable MMAP
	cd libzim-4.0.5 ; patch -p1 <../patch_libzim_for_emscripten.patch
	cd libzim-4.0.5; ninja -C build
	mkdir -p libzimbuild/lib libzimbuild/include
	cp libzim-4.0.5/build/src/libzim.so libzimbuild/lib
	cp -ar libzim-4.0.5/include libzimbuild/

pugixmlbuild :
	wget --no-check-certificate -O pugixml-1.9.tar.gz https://github.com/zeux/pugixml/archive/v1.9.tar.gz
	tar xf pugixml-1.9.tar.gz
	sed -i -e 's/^BUILD=build.*/BUILD=build\/make-emscripten/' pugixml-1.9/Makefile
	cd pugixml-1.9; emmake make build/make-emscripten/src/pugixml.cpp.o
	mkdir -p pugixmlbuild/lib pugixmlbuild/include
	cp pugixml-1.9/build/make-emscripten/src/pugixml.cpp.o pugixmlbuild/build
	cp pugixml-1.9/src/pugixml.hpp pugixmlbuild/include
	cp pugixml-1.9/src/pugiconfig.hpp pugixmlbuild/include

curlbuild :
	wget --no-check-certificate -O curl-7_64_0.tar.gz https://github.com/curl/curl/archive/curl-7_64_0.tar.gz
	tar xf curl-7_64_0.tar.gz
	cd curl-curl-7_64_0; ./buildconf
	cd curl-curl-7_64_0; emconfigure ./configure --prefix=`pwd`/../curlbuild
	cd curl-curl-7_64_0; emmake make
	cd curl-curl-7_64_0; emmake make install

mustachebuild :
	wget --no-check-certificate -O mustache-3.2.1.tar.gz https://github.com/kainjow/Mustache/archive/v3.2.1.tar.gz
	tar xf mustache-3.2.1.tar.gz
	sed -i -e 's/g++ /em++ /g' Mustache-3.2.1/Makefile
	sed -i -e 's/.\/mustache//g' Mustache-3.2.1/Makefile
	cd Mustache-3.2.1; make
	mkdir -p mustachebuild/lib mustachebuild/include
	cp Mustache-3.2.1/mustache.hpp mustachebuild/include
	cp Mustache-3.2.1/mustache mustachebuild/lib

kiwixlibbuild : libzimbuild pugixmlbuild mustachebuild curlbuild
	wget --no-check-certificate -O libkiwix-4.0.1.tar.gz https://github.com/kiwix/kiwix-lib/archive/4.0.1.tar.gz
	tar xf libkiwix-4.0.1.tar.gz
	cd libkiwix-4.0.1 ; patch -p1 <../patch_kiwixlib_for_emscripten.patch
	# Quick and dirty way to avoid that meson checks some dependencies
	sed -i -e 's/^libzim_dep = .*//g' libkiwix-4.0.1/meson.build
	sed -i -e 's/, libzim_dep//g' libkiwix-4.0.1/meson.build
	sed -i -e 's/^pugixml_dep = .*//g' libkiwix-4.0.1/meson.build
	sed -i -e 's/, pugixml_dep//g' libkiwix-4.0.1/meson.build
	sed -i -e "s/error('Cannot found header mustache.hpp')//g" libkiwix-4.0.1/meson.build
	cd libkiwix-4.0.1; meson . build
	# Quick and dirty way to tell ninja to compile with emscripten,
	# with the dependencies compiled above,
	# and to remove unnecessary compilation steps
	sed -i -e 's/ c++ / em++ /g' libkiwix-4.0.1/build/build.ninja
	sed -i -e 's/ cc / emcc /g' libkiwix-4.0.1/build/build.ninja
	sed -i -e 's#\(build all: phony \).*\(src/libkiwix.so......\).*#\1\2#' libkiwix-4.0.1/build/build.ninja
	# Depending on the environment, the parameters can be surrounded by quotes or not
	sed -i -e "s/'-Iinclude'/'-Iinclude' '-Istatic' '-I..\/..\/libzimbuild\/include' '-I..\/..\/pugixmlbuild\/include' '-I..\/..\/icubuild\/include' '-I..\/..\/mustachebuild\/include' '-I..\/..\/curlbuild\/include'/g" libkiwix-4.0.1/build/build.ninja
	sed -i -e "s/ -Iinclude / -Iinclude -Istatic -I..\/..\/libzimbuild\/include -I..\/..\/pugixmlbuild\/include -I..\/..\/icubuild\/include -I..\/..\/mustachebuild\/include -I..\/..\/curlbuild\/include /g" libkiwix-4.0.1/build/build.ninja
	sed -i -e "s/ '-I\/usr\/include\/x86_64-linux-gnu'//g" libkiwix-4.0.1/build/build.ninja
	sed -i -e "s/ -I\/usr\/include\/x86_64-linux-gnu //g" libkiwix-4.0.1/build/build.ninja
	sed -i -e 's/'-Wnon-virtual-dtor'//g' libkiwix-4.0.1/build/build.ninja
	sed -i -e 's/-Wnon-virtual-dtor//g' libkiwix-4.0.1/build/build.ninja
	sed -i -e 's/^\( LINK_ARGS =.*\)/\1 -L..\/..\/libzimbuild\/lib -L..\/..\/pugixmlbuild\/lib -L..\/..\/icubuild\/lib/g' libkiwix-4.0.1/build/build.ninja
	sed -i -e 's/^\(build all: phony src\/libkiwix.so.4.0.1\).*/\1/g' libkiwix-4.0.1/build/build.ninja
	cd libkiwix-4.0.1; ninja -C build
	mkdir -p kiwixlibbuild/lib kiwixlibbuild/include
	cp libkiwix-4.0.1/build/src/libkiwix.so kiwixlibbuild/lib
	cp -ar libkiwix-4.0.1/include kiwixlibbuild/

demo_file_api.js: kiwixlibbuild demo_file_api.cpp prejs_file_api.js postjs_file_api.js
	em++ --bind demo_file_api.cpp libzimbuild/lib/libzim.so kiwixlibbuild/lib/libkiwix.so -Ilibzimbuild/include -Ikiwixlibbuild/include -Iicubuild/include -fdiagnostics-color=always -pipe -Wall -Winvalid-pch -Wnon-virtual-dtor -Werror -std=c++11 -O0 -g -D_LARGEFILE64_SOURCE=1 -D_FILE_OFFSET_BITS=64 -pthread --pre-js prejs_file_api.js --post-js postjs_file_api.js -s DISABLE_EXCEPTION_CATCHING=0 -s "EXTRA_EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','printErr','ALLOC_STACK','ALLOC_STATIC','ALLOC_DYNAMIC','ALLOC_NONE','print']" -s DEMANGLE_SUPPORT=1 -s TOTAL_MEMORY=83886080

clean_dependencies :
	rm -rf lzma z icubuild xapian pugixmlbuild aria2build mustachebuild curlbuild
	rm -rf xz-5.2.4 xz-5.2.4.tar.gz*
	rm -rf zlib-1.2.11 zlib-1.2.11.tar.gz*
	rm -rf xapian-core-1.4.10 xapian-core-1.4.10.tar.xz*
	rm -rf icu icu4c-63_2-src.tgz*
	rm -rf pugixml-1.9 pugixml-1.9.tar.gz*
	rm -rf aria2-release-1.34.0 aria2-release-1.34.0.tar.gz*
	rm -rf curl-curl-7_64_0 curl-7_64_0.tar.gz*
	rm -rf Mustache-3.2.1 mustache-3.2.1.tar.gz*
clean_libzim :
	rm -rf libzim-4.0.5 libzimbuild
	rm -rf libzim-4.0.5.tar.gz
clean_kiwixlib :
	rm -rf libkiwix-4.0.1 kiwixlibbuild
	rm -rf libkiwix-4.0.1.tar.gz
clean_demo :
	rm a.out.*
clean : clean_dependencies clean_libzim clean_kiwixlib clean_demo

.PHONY : all clean clean_libzim clean_dependencies clean_demo
