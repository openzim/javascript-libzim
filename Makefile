all: demo_file_api.js
lzma : 
	wget https://tukaani.org/xz/xz-5.2.4.tar.gz
	tar xvf xz-5.2.4.tar.gz
	cd xz-5.2.4 ; ./autogen.sh
	cd xz-5.2.4 ; emconfigure ./configure --prefix=`pwd`/../lzma
	cd xz-5.2.4 ; emmake make 
	cd xz-5.2.4 ; emmake make install
	
z : 
	wget http://zlib.net/zlib-1.2.11.tar.gz
	tar xvf zlib-1.2.11.tar.gz
	cd zlib-1.2.11 ; emconfigure ./configure --prefix=`pwd`/../z
	cd zlib-1.2.11 ; emmake make 
	cd zlib-1.2.11 ; emmake make install
	
icubuild : 
	wget http://download.icu-project.org/files/icu4c/62.1/icu4c-62_1-src.tgz
	tar xvf icu4c-62_1-src.tgz
	# Quick and dirty way to make ICU handle Double-conversion, and to skip unnecessary compilation steps
	cd icu ; patch -p1 <../patch_icu_for_emscripten.patch
	cd icu/source ; emconfigure ./configure --prefix=`pwd`/../../icubuild
	cd icu/source ; emmake make 
	cd icu/source ; emmake make install

xapian : z
	wget https://oligarchy.co.uk/xapian/1.4.7/xapian-core-1.4.7.tar.xz
	tar xvf xapian-core-1.4.7.tar.xz
	cd xapian-core-1.4.7; emconfigure ./configure --prefix=`pwd`/../xapian "CFLAGS=-I`pwd`/../z/include -L`pwd`/../z/lib" "CXXFLAGS=-I`pwd`/../z/include -L`pwd`/../z/lib" --disable-backend-remote
	cd xapian-core-1.4.7; emmake make "CFLAGS=-I`pwd`/../z/include -L`pwd`/../z/lib -std=c++11" "CXXFLAGS=-I`pwd`/../z/include -L`pwd`/../z/lib -std=c++11"
	cd xapian-core-1.4.7; emmake make install

libzimbuild : lzma z icubuild xapian
	git clone https://github.com/openzim/libzim.git
	cd libzim; meson . build
	# Quick and dirty way to tell ninja to compile with emscripten,
	# with the dependencies compiled above,
	# and to remove unnecessary compilation steps
	sed -i -e 's/ c++ / em++ /g' libzim/build/build.ninja
	sed -i -e 's/ cc / emcc /g' libzim/build/build.ninja
	sed -i -e 's#\(build all: phony src/libzim.so...... \).*#\1#' libzim/build/build.ninja
	sed -i -e 's/-Iinclude/-Iinclude -I..\/..\/lzma\/include -I..\/..\/z\/include -I..\/..\/icubuild\/include -I..\/..\/xapian\/include/g' libzim/build/build.ninja
	sed -i -e 's/^\( LINK_ARGS =.*\)/\1 -L..\/..\/lzma\/lib -L..\/..\/z\/lib -L..\/..\/icubuild\/lib -L..\/..\/xapian\/lib/g' libzim/build/build.ninja
	# Quick and dirty way to disable MMAP
	cd libzim ; patch -p1 <../patch_libzim_for_emscripten.patch
	cd libzim; ninja -C build
	mkdir -p libzimbuild/lib libzimbuild/include
	cp libzim/build/src/libzim.so libzimbuild/lib
	cp -ar libzim/include libzimbuild/

demo_file_api.js: libzimbuild demo_file_api.cpp my_glue_wrapper.cpp prejs_file_api.js postjs_file_api.js glue.js
	em++ demo_file_api.cpp libzimbuild/lib/libzim.so -Ilibzimbuild/include -fdiagnostics-color=always -pipe -Wall -Winvalid-pch -Wnon-virtual-dtor -Werror -std=c++11 -O0 -g -D_LARGEFILE64_SOURCE=1 -D_FILE_OFFSET_BITS=64 -pthread --pre-js prejs_file_api.js --post-js postjs_file_api.js --post-js glue.js -s DISABLE_EXCEPTION_CATCHING=0 -s "EXTRA_EXPORTED_RUNTIME_METHODS=['ALLOC_NORMAL','printErr','ALLOC_STACK','ALLOC_STATIC','ALLOC_DYNAMIC','ALLOC_NONE']" -s DEMANGLE_SUPPORT=1 -s ALLOW_MEMORY_GROWTH=1

clean_dependencies :
	rm -rf lzma z icubuild xapian
	rm -rf xz-5.2.4 xz-5.2.4.tar.gz
	rm -rf zlib-1.2.11 zlib-1.2.11.tar.gz
	rm -rf icu icu4c-62_1-src.tgz
clean_libzim :
	rm -rf libzim libzimbuild
clean_demo :
	rm a.out.*
clean : clean_dependencies clean_libzim clean_demo

.PHONY : all clean clean_libzim clean_dependencies clean_demo
