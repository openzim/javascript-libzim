# Prototype of libzim in WebAssembly (WASM)

This Repository provides the source code and utilities for compiling the [ZIM File](https://wiki.openzim.org/wiki/ZIM_file_format) reader [lbizim](https://wiki.openzim.org/wiki/Libzim) from C++ to [WebAssembly](https://developer.mozilla.org/en-US/docs/WebAssembly) (and [ASM.js](https://developer.mozilla.org/en-US/docs/Games/Tools/asm.js)).

A prototype in HTML/JS, for testing the WASM version, is provided at https://openzim.github.io/javascript-libzim/tests/prototyep/. This prototype uses WORKERFS as the Emscripten File System and runs in a Web Worker. The file object is mounted before run, and the name is passed as argument.

There is also an HTML/JS utility for testing the ability of Emscripten File Systems to read large files (muliti-gigabyte) at https://openzim.github.io/javascript-libzim/tests/test_large_file_access/.

## Steps to recompile manually

- Install emscripten : https://kripken.github.io/emscripten-site/docs/getting_started/downloads.html
- Install dependencies necessary for compilation. On ubuntu 18.04, you need to activate universe repository and:

```
sudo apt install ninja-build meson pkg-config python3 autopoint libtool autoconf
sudo apt install zlib1g-dev libicu-dev libxapian-dev liblzma-dev
```

- activate emscripten environment variables with something like `source ./emsdk_env.sh`
- run `make`

## Steps to recompile with Docker

While being at the root of this repository:
 - Build the Docker image with the provided Dockerfile (based on https://hub.docker.com/r/emscripten/emsdk, which is based on Debian):

```
docker build -t "docker-emscripten-libzim:v3" ./docker
```

 - Run the build with:

```
docker run --rm -v $(pwd):/src -v /tmp/emscripten_cache/:/home/emscripten/.emscripten_cache -u $(id -u):$(id -g) -it docker-emscripten-libzim:v3 make
```
