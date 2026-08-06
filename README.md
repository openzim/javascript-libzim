# Prototype of libzim in WebAssembly (WASM)

This Repository provides the source code and utilities for compiling the [ZIM File](https://wiki.openzim.org/wiki/ZIM_file_format) reader
[lbizim](https://wiki.openzim.org/wiki/Libzim) from C++ to [WebAssembly](https://developer.mozilla.org/en-US/docs/WebAssembly)
(and [ASM.js](https://developer.mozilla.org/en-US/docs/Games/Tools/asm.js)). Only the reading capabilities of libzim are cureently compiled,
as the compioled binary is intended for use in JavaScript ZIM reader clients.

A prototype in HTML/JS, for testing the WASM version, is provided at https://openzim.github.io/javascript-libzim/tests/prototype/. This
prototype uses WORKERFS as the Emscripten File System and runs in a Web Worker. The file object is mounted before run, and the name is
passed as argument.

There is also an HTML/JS utility for testing the ability of Emscripten File Systems to read large files (muliti-gigabyte) at
https://openzim.github.io/javascript-libzim/tests/test_large_file_access/.

![GitHub Workflow Status (branch)](https://img.shields.io/github/actions/workflow/status/openzim/javascript-libzim/build_libzim_wasm.yml?branch=main) [![CodeFactor](https://www.codefactor.io/repository/github/openzim/javascript-libzim/badge)](https://www.codefactor.io/repository/github/openzim/javascript-libzim)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Nightly and Release versions

WASM and ASM versions are built nightly from the binaries provided (nightly) by [kiwix-build](https://github.com/kiwix/kiwix-build). The artefacts are
made available at https://download.openzim.org/nightly/ (if tests pass). Artefacts for PRs and pushes are attached to the respective workflow run. **Please note that currently, versions built form precompiled binaries lack the snippets support, because this support relies on a patch to the source code to override exceptions-based programme flow which cannot be handled well in WASM.** Therefore, to use the full functionality, it is currently necessary to compile from source using, e.g. `docker run --rm -v $(pwd):/src -u $(id -u):$(id -g) docker-emscripten-libzim:v3 make`.

Released versions are published both in [Releases](https://github.com/openzim/javascript-libzim/releases) and at https://download.openzim.org/release/javascript-libzim/.

These versions are built with both the WORKERFS and the NODEFS [Emscripten File Systems](https://emscripten.org/docs/api_reference/Filesystem-API.html).
Please note that WORKERFS must be run in a Web Worker, and so the JavaScript glue (interface to the C++ code) is provided as a Worker. Messages are sent
to and received from the Worker via [`window.postMessage()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage).

You can change the File Systems and other parameters in the provided [Makefile](https://github.com/openzim/javascript-libzim/blob/main/Makefile) in
this Repository. This recipe needs to be run in an Emscripten-configured system or a customized Emscripten container (see below).

## JavaScript API Bindings

> **⚠️ API Stability Warning**
> 
> The JavaScript API documented below is considered **unstable** until the release of version 1.0 of javascript-libzim (currently on v0.x). Breaking changes may occur between minor versions.
> 
> Additionally, the built W/ASM packages in `tests/prototype/` may be ahead of official releases and may contain experimental alterations to the API that are not yet documented or finalized.
> 
> **Web Worker API:** For the messaging-based Web Worker API (used in the prototype), refer to [`prejs_file_api.js`](prejs_file_api.js) which serves as the Web Worker's header and documents the available actions and message formats.

This section documents the JavaScript API bindings that are available after loading the compiled W/ASM module. The bindings provide access to libzim's core functionality including archive loading, content access, and search capabilities.

### Archive Management

#### `Module.loadArchive(filename: string): void`
Loads a ZIM archive for subsequent operations.
```javascript
Module.loadArchive("path/to/archive.zim");
```

#### `Module.getArticleCount(): number`
Returns the total number of articles in the loaded archive.
```javascript
const count = Module.getArticleCount();
```

### Content Access

#### `Module.getEntryByPath(path: string): EntryWrapper | null`
Retrieves a specific entry by its path in the ZIM archive.
```javascript
const entry = Module.getEntryByPath("A/Wikipedia");
if (entry) {
    console.log(entry.getTitle());
}
```

### Entry Wrapper Class

The `EntryWrapper` class provides access to ZIM entries (articles, redirects, etc.):

- `getPath(): string` - Returns the entry's path
- `getTitle(): string` - Returns the entry's title
- `isRedirect(): boolean` - Returns true if the entry is a redirect
- `getRedirectEntry(): EntryWrapper` - Returns the target entry for redirects
- `getItem(follow: boolean): ItemWrapper` - Returns the item content

### Item Wrapper Class

The `ItemWrapper` class provides access to the actual content of entries:

- `getData(): BlobWrapper` - Returns the content as binary data
- `getMimetype(): string` - Returns the MIME type of the content

### Blob Wrapper Class

The `BlobWrapper` class handles binary content:

- `getContent(): Uint8Array` - Returns the content as a typed array

### Search Functionality

#### Basic Full-Text Search

#### `Module.search(query: string, maxResults: number): vector<EntryWrapper>`
Performs basic full-text search returning entry paths.
```javascript
const results = Module.search("quantum physics", 20);
for (let i = 0; i < results.size(); i++) {
    const entry = results.get(i);
    console.log(entry.getTitle(), entry.getPath());
}
```

**Usage Example:** See [javascript_search_usage_example.js](javascript_search_usage_example.js) for comprehensive examples.

#### Enhanced Search with Snippets

#### `Module.searchWithSnippets(query: string, maxResults: number): vector<SearchIteratorWrapper>`
Performs full-text search with content snippets and metadata.
```javascript
const results = Module.searchWithSnippets("quantum physics", 20);
for (let i = 0; i < results.size(); i++) {
    const result = results.get(i);
    console.log(result.getTitle());
    console.log(result.getSnippet()); // Content excerpt with highlighted terms
    console.log("Score:", result.getScore());
}
```

**Implementation Details:** See [SEARCH_SNIPPETS_IMPLEMENTATION.md](SEARCH_SNIPPETS_IMPLEMENTATION.md) for technical details about snippet generation.

#### Search Iterator Wrapper Class

The `SearchIteratorWrapper` class provides rich search results with content snippets:

- `getPath(): string` - Returns the entry's path
- `getTitle(): string` - Returns the entry's title
- `getSnippet(): string` - Returns content excerpt with search term highlighting
- `getScore(): number` - Returns search relevance score
- `getWordCount(): number` - Returns word count of the article
- `getEntry(): EntryWrapper` - Returns the full entry object

#### Language-Aware Search

#### `Module.searchWithLanguage(query: string, maxResults: number, language?: string): vector<EntryWrapper>`
Performs search with optional language specification.
```javascript
const results = Module.searchWithLanguage("bonjour", 10, "fr");
```

### Suggestion/Autocomplete Functionality

#### Simple Suggestion Function

#### `Module.suggest(query: string, maxResults: number): vector<EntryWrapper>`
Quick title-based suggestions for autocomplete functionality.
```javascript
const suggestions = Module.suggest("wik", 8);
for (let i = 0; i < suggestions.size(); i++) {
    const entry = suggestions.get(i);
    console.log(entry.getTitle());
}
```

#### Advanced Suggestion Classes

#### `Module.SuggestionSearcher` Class
Advanced suggestion functionality with more control:

```javascript
const searcher = new Module.SuggestionSearcher();
const search = searcher.suggest("query");
const matchCount = search.getEstimatedMatches();
const results = search.getResults(0, 10);
```

**SuggestionSearcher Methods:**
- `suggest(query: string): SuggestionSearchWrapper` - Creates a suggestion search

**SuggestionSearchWrapper Methods:**
- `getEstimatedMatches(): number` - Returns estimated total matches
- `getResults(start: number, count: number): vector<EntryWrapper>` - Returns paginated results

**Usage Example:** See [javascript_suggestions_usage_example.js](javascript_suggestions_usage_example.js) for comprehensive examples.

### Vector Operations

All search and suggestion functions return Emscripten vectors with these methods:

- `size(): number` - Returns the number of results
- `get(index: number): T` - Returns the item at the specified index

### Error Handling

All functions include proper error handling. Failed operations typically return:
- `null` for single object returns (e.g., `getEntryByPath`)
- Empty vectors for collection returns (e.g., `search`, `suggest`)
- Empty strings for string returns (e.g., `getSnippet`)

### Complete Usage Examples

For comprehensive usage examples and patterns:
- **Search functionality:** [javascript_search_usage_example.js](javascript_search_usage_example.js)
- **Suggestion functionality:** [javascript_suggestions_usage_example.js](javascript_suggestions_usage_example.js)
- **Search with snippets implementation:** [SEARCH_SNIPPETS_IMPLEMENTATION.md](SEARCH_SNIPPETS_IMPLEMENTATION.md)

## Steps to recompile from source with Docker

This is the easiest (and recommended) compilation method, because all required tools are configured in the Docker image. Ensure you have docker
installed. (This also works in WSL with Docker Desktop installed and configured as per default to work with a WSL VM.)

* Open a terminal at the root of this repository;
* Build the Docker image with the provided Dockerfile (based on https://hub.docker.com/r/emscripten/emsdk, which is based on Debian), adapting the VERSION number of the Emscripten SDK as required:

```
docker build -t "docker-emscripten-libzim:v3" ./docker --build-arg VERSION='3.1.41'
```

* Run the build with:

```
docker run --rm -v $(pwd):/src -v /tmp/emscripten_cache/:/home/emscripten/.emscripten_cache -u $(id -u):$(id -g) -it docker-emscripten-libzim:v3 make
```

If you get failures and wish to make adjustments, you can clean all downloaded and intermediate compiled files with the command `make clean`.

## Steps to recompile manually

* Install Emscripten : https://kripken.github.io/emscripten-site/docs/getting_started/downloads.html
* Install dependencies necessary for compilation. On ubuntu 18.04, you need to activate universe repository and:

```
sudo apt install ninja-build meson pkg-config python3 autopoint libtool autoconf
sudo apt install zlib1g-dev libicu-dev libxapian-dev liblzma-dev
```

* Activate emscripten environment variables with something like `source ./emsdk_env.sh`
* Run `make`.

## Tests

Basic Unit tests are run on each automated build before publishing on the ASM and WASM builds (e.g., `libim-wasm.dev.js` and `libzim-wasm.dev.wasm`).
The units tested are the same as those tested in the prototype (see above) and run on two test ZIMs. The specific tests are:

* mounting a test archive in each of the four libzim builds;
* checking the reported article count;
* loading an article;
* searching.

Tests are run in Chromium browser context (needed in order to test WORKERFS) rather than purely in Node, so they are based on automation of the
prototype, and are available in `/tests/prototype`.

To run tests manually, replace the six `libzim-[w]asm.*.*` files in `tests/prototype` with the versions you wish to test (this is done automatically
if you build using the provided Makefile) and then run the following commands from the root of this Repository:

```
npm install
npm test
```

If you want to test certain build files you can start the server via `npx http-server --port 8080` and then visit `http://127.0.0.1:8080/tests/prototype/index.html?worker=libzim-[w]asm.*.*`.

To run tests in a different browser, copy and adapt the test runner `chromium.e2e.runner.js`. Run it manually like so:

`npx start-server-and-test 'http-server --silent' 8080 'npx mocha ./tests/prototype/chromium.e2e.runner.js'`

## Licence

[GPLv3](https://www.gnu.org/licenses/gpl-3.0) or later, see
[LICENCE](LICENSE) for more details.
