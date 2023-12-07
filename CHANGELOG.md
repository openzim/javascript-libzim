# Changelog of Libzim JavaScript port

The WASM and ASM ports of libzim for JavaScript applications is built on the official
[libzim releases](https://download.openzim.org/release/libzim/). Early ports, and v0.4 (see reasons below), were created by building the libzim
WASM binary (`libzim.a`) from scratch, but from version 0.1, we have been using the binary produced by
[Kiwix build](https://github.com/kiwix/kiwix-build) as the basis for building the JavaScript application with Emscripten. We release both WASM and
ASM applications. Release packages can be obtained from [Releases](https://github.com/openzim/javascript-libzim/releases) or from
https://download.openzim.org/release/javascript-libzim/.

## Javascript Libzim v0.6 (2023-10-13)

* Extended Unit testing for libzim-[w]asm.*.js by @Rishabhg71
* Compiling production files with DISABLE_EXCEPTION_CATCHING set to False by @Rishabhg71


## Javascript Libzim v0.5 (2023-10-13)
This release is built with Emscripten 3.4.1 and builds the new libzim 9.0.0 from libzim binaries.

* Create Unit tests for builds by @Jaifroid in #62

## Javascript Libzim v0.4 (2023-10-13)

This release uses Emscripten 3.1.41 to build the final ASM/WASM versions from libzim **source** v8.2.1. It is built from source code because
building from the intermediate `libzim.a` binary leads to the broken version released in 0.3. Full-text searching is confirmed to be working in
this release.

Changelog includes changes since v0.2, since the 0.3 release was broken:

* Try to compile with 3.1.41 (current latest) by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/52
* Pull different EMSDK versions according to build type by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/53
* Update libzim version for source build to 8.2.0 by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/54
* Update libzim 8.2.1 for release 0.3 by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/56
* Update prototype with v0.3 by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/57 (reverted)

## Javascript Libzim v0.3 (2023-10-12)

This BROKEN release was based on Emscripten 3.1.41 and updated the libzim dependency to v8.2.1. It was built from the provided `libzim.a` binary.
However, it was discovered subsequent to release that the WASM and ASM versions were partially broken: they can read a ZIM's contents, but cannot
complete a full-text search (Xapian).

* Try to compile with 3.1.41 (current latest) by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/52
* Pull different EMSDK versions according to build type by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/53
* Update libzim version for source build to 8.2.0 by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/54
* Update libzim 8.2.1 for release 0.3 by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/56

## JavaScript Libzim v0.2 (2023-04-17)

This release adds support for running javascript-libzim in a Node JS framework (e.g. an Electron app), and in a webextension using mainfest v3 (complying with the stricter CSP required by such extensions). The release is based on `libzim_wasm-emscripten-8.1.1.tar.gz`.

* Add NODEFS for Electron builds by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/33
* Bring default Github config by @kelson42 in https://github.com/openzim/javascript-libzim/pull/38
* Fix issues identified by codefactor by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/40
* Update location of libzim binary in downloaded archive by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/45
* Compile all versions without dynamic execution by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/48

## JavaScript Libzim v0.1 (2022-12-13)

This is the first release based on binaries provided by [kiwix-build](https://github.com/kiwix/kiwix-build).

* Add GPL3+ licence by @kelson42 in https://github.com/openzim/javascript-libzim/pull/28
* licence + codefactor badges by @kelson42 in https://github.com/openzim/javascript-libzim/pull/29
* Update gh-pages on push to master by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/31
* Rename master to main in actions by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/32
* Add redirect to prototype from Repository root by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/35
* Add options to build wasm from kiwix-build libzim.a by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/37

## JavaScript Libzim v0.0.2 (2022-12-08)

**PRE-RELEASE version**

* Robust makefile and workflow to build dev and production ASM and WASM versions by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/14
* Fixed an issue with pre-release v0.0.1 whereby the production versions had garbled names for some internal functions
* Updated several of the dependencies to their latest versions

## JavaScript Libzim v0.0.1 (2022-12-06)

**PRE-RELEASE version**

* Dirtily recompiled version of libzim in wasm by @mossroy in https://github.com/openzim/javascript-libzim/pull/1
* Update to emsdk 2.0.32 by @mossroy in https://github.com/openzim/javascript-libzim/pull/2
* Upgrade libzim to 6.3.2 by @mossroy in https://github.com/openzim/javascript-libzim/pull/3
* Upgrade libzim to 7.0.0 by @mossroy in https://github.com/openzim/javascript-libzim/pull/4
* First implementation of split ZIM files support by @mossroy in https://github.com/openzim/javascript-libzim/pull/5
* Read images through libzim by @mossroy in https://github.com/openzim/javascript-libzim/pull/6
* Big file test-case for emscripten by @mossroy in https://github.com/openzim/javascript-libzim/pull/7
* Update zlib to 1.2.13 and netbeans conf files by @mossroy in https://github.com/openzim/javascript-libzim/pull/10
* Create an action to build the wasm by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/13
* Add workflow and scripts for upload to kiwix by @Jaifroid in https://github.com/openzim/javascript-libzim/pull/20
