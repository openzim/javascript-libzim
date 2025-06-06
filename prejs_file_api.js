/**
 * Web Worker API for libzim JavaScript bindings
 * 
 * This file provides the pre-JS portion of the web worker that handles ZIM file operations.
 * It is concatenated with postjs_file_api.js during the Emscripten build process (see Makefile)
 * to create a complete web worker script that can be used with WebAssembly or asm.js builds.
 * 
 * Supported actions: getEntryByPath, search, suggest, suggestWithSnippets, getArticleCount, init
 */

self.addEventListener('message', function(e) {
    var action = e.data.action;
    var path = e.data.path;
    var outgoingMessagePort = e.ports[0];
    console.debug('WebWorker called with action=' + action);
    
    // Retrieve content from ZIM archive by path
    if (action === 'getEntryByPath') {
        var follow = e.data.follow;
        var entry = Module[action](path);
        if (entry) {
            var item = {};
            if (follow || !entry.isRedirect()) {
                item = entry.getItem(follow);
                // It's necessary to keep an instance of the blob till the end of this block,
                // to ensure that the corresponding content is not deleted on the C side.
                var blob = item.getData();
                var content = blob.getContent();
                // TODO : is there a more efficient way to make the Array detachable? So that it can be transfered back from the WebWorker without a copy?
                var contentArray = new Uint8Array(content);
                outgoingMessagePort.postMessage({ content: contentArray, mimetype: item.getMimetype(), isRedirect: entry.isRedirect()});
            }
            else {
                outgoingMessagePort.postMessage({ content: new Uint8Array(), isRedirect: true, redirectPath: entry.getRedirectEntry().getPath()});
            }
        }
        else {
            outgoingMessagePort.postMessage({ content: new Uint8Array(), mimetype: 'unknown', isRedirect: false});
        }
    } 
    // Full-text search across ZIM archive content
    else if (action === 'search') {
        var text = e.data.text;
        var numResults = e.data.numResults || 50;
        var entries = Module[action](text, numResults);
        console.debug('Found nb results = ' + entries.size(), entries);
        var serializedEntries = [];
        for (var i=0; i<entries.size(); i++) {
            var entry = entries.get(i);
            serializedEntries.push({path: entry.getPath()});
        }
        outgoingMessagePort.postMessage({ entries: serializedEntries });
    } 
    // Title-based suggestions for autocomplete (faster than full-text search)
    // BACKWARD COMPATIBLE: Returns basic entry information without snippets
    else if (action === 'suggest') {
        var text = e.data.text;
        var numResults = e.data.numResults || 10;
        var suggestions = Module[action](text, numResults);
        console.debug('Found nb suggestions = ' + suggestions.size(), suggestions);
        var serializedSuggestions = [];
        for (var i=0; i<suggestions.size(); i++) {
            var entry = suggestions.get(i);
            serializedSuggestions.push({path: entry.getPath(), title: entry.getTitle()});
        }
        outgoingMessagePort.postMessage({ suggestions: serializedSuggestions });
    } 
    // NEW: Enhanced title-based suggestions with snippet support
    // Returns rich suggestion information including preview snippets
    else if (action === 'suggestWithSnippets') {
        var text = e.data.text;
        var numResults = e.data.numResults || 10;
        var suggestions = Module.suggestWithSnippets(text, numResults);
        console.debug('Found nb suggestions with snippets = ' + suggestions.size(), suggestions);
        var serializedSuggestions = [];
        for (var i=0; i<suggestions.size(); i++) {
            var item = suggestions.get(i);
            var suggestionData = {
                path: item.getPath(),
                title: item.getTitle(),
                hasSnippet: item.hasSnippet()
            };
            // Only include snippet if it exists to minimize message size
            if (item.hasSnippet()) {
                suggestionData.snippet = item.getSnippet();
            }
            serializedSuggestions.push(suggestionData);
        }
        outgoingMessagePort.postMessage({ suggestions: serializedSuggestions });
    }
    // Class-based suggestion search with advanced options
    // Supports both basic entries and enhanced suggestion items with snippets
    else if (action === 'suggestionSearch') {
        var text = e.data.text;
        var start = e.data.start || 0;
        var count = e.data.count || 10;
        var includeSnippets = e.data.includeSnippets || false;
        
        try {
            // Create suggestion searcher and perform search
            var searcher = new Module.SuggestionSearcher();
            var search = searcher.suggest(text);
            var estimatedMatches = search.getEstimatedMatches();
            
            var serializedResults = [];
            
            if (includeSnippets) {
                // Use getSuggestionItems for rich snippet information
                var items = search.getSuggestionItems(start, count);
                console.debug('Found nb suggestion items with snippets = ' + items.size() + ' (estimated total: ' + estimatedMatches + ')');
                
                for (var i=0; i<items.size(); i++) {
                    var item = items.get(i);
                    var itemData = {
                        path: item.getPath(),
                        title: item.getTitle(),
                        hasSnippet: item.hasSnippet()
                    };
                    if (item.hasSnippet()) {
                        itemData.snippet = item.getSnippet();
                    }
                    serializedResults.push(itemData);
                }
            } else {
                // Use getResults for backward compatible entry information
                var entries = search.getResults(start, count);
                console.debug('Found nb suggestion entries = ' + entries.size() + ' (estimated total: ' + estimatedMatches + ')');
                
                for (var i=0; i<entries.size(); i++) {
                    var entry = entries.get(i);
                    serializedResults.push({
                        path: entry.getPath(),
                        title: entry.getTitle()
                    });
                }
            }
            
            outgoingMessagePort.postMessage({ 
                suggestions: serializedResults,
                estimatedMatches: estimatedMatches,
                start: start,
                count: serializedResults.length,
                includeSnippets: includeSnippets
            });
            
        } catch (error) {
            console.error('SuggestionSearch error:', error);
            outgoingMessagePort.postMessage({ 
                error: 'SuggestionSearch failed: ' + error.toString(),
                suggestions: [],
                estimatedMatches: 0
            });
        }
    }
    // Get total number of articles in the ZIM archive
    else if (action === 'getArticleCount') {
        var articleCount = Module[action]();
        outgoingMessagePort.postMessage(articleCount);
    } 
    // Initialize the ZIM archive with file system mounting
    else if (action === 'init') {
        var files = e.data.files;
        var assemblerType = e.data.assemblerType || 'runtime';
        // When using split ZIM files, we need to remove the last two letters of the suffix (like .zimaa -> .zim)
        var baseZimFileName = files[0].name.replace(/\.zim..$/, '.zim');
        Module = {};
        Module['onRuntimeInitialized'] = function() {
            Module.loadArchive('/work/' + baseZimFileName);
            console.debug(assemblerType + ' initialized');
            outgoingMessagePort.postMessage('runtime initialized');
        };
        Module['arguments'] = [];
        for (let i = 0; i < files.length; i++) {
              Module['arguments'].push('/work/' + files[i].name);
        }
        // Mount file system for ZIM file access (Electron vs browser environments)
        Module['preRun'] = function() {
            FS.mkdir('/work');
            if (files[0].readMode === 'electron') {
                var path = files[0].path.replace(/[^\\/]+$/, '');
                FS.mount(NODEFS, {
                    root: path
                }, '/work');    
            } else {
                FS.mount(WORKERFS, {
                    files: files
                }, '/work');
            }
        };
        console.debug('baseZimFileName = ' + baseZimFileName);
        console.debug("Module['arguments'] = " + Module['arguments']);

        // File continues in postjs_file_api.js - handles invalid actions and closes the event listener
        // Between prejs and postjs: Emscripten injects the compiled WebAssembly/asm.js Module code and bindings