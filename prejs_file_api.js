self.addEventListener("message", function(e) {
    var action = e.data.action;
    var path = e.data.path;
    var outgoingMessagePort = e.ports[0];
    console.debug("WebWorker called with action=" + action);
    if (action === "getEntryByPath") {
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
            outgoingMessagePort.postMessage({ content: new Uint8Array(), mimetype: "unknown", isRedirect: false});
        }
    }
    else if (action === "search") {
        var text = e.data.text;
        var numResults = e.data.numResults || 50;
        var entries = Module[action](text, numResults);
        console.debug("Found nb results = " + entries.size(), entries);
        var serializedEntries = [];
        for (var i=0; i<entries.size(); i++) {
            var entry = entries.get(i);
            serializedEntries.push({path: entry.getPath()});
        }
        outgoingMessagePort.postMessage({ entries: serializedEntries });
    }
    else if (action === "getArticleCount") {
        var articleCount = Module[action]();
        outgoingMessagePort.postMessage(articleCount);
    }
    else if (action === "init") {
        var files = e.data.files;
        var assemblerType = e.data.assemblerType || 'runtime';
        // When using split ZIM files, we need to remove the last two letters of the suffix (like .zimaa -> .zim)
        var baseZimFileName = files[0].name.replace(/\.zim..$/, '.zim');
        Module = {};
        Module["onRuntimeInitialized"] = function() {
            Module.loadArchive("/work/" + baseZimFileName);
            console.debug(assemblerType + " initialized");
            outgoingMessagePort.postMessage("runtime initialized");
        };
        Module["arguments"] = [];
        for (let i = 0; i < files.length; i++) {
              Module["arguments"].push('/work/' + files[i].name);
        }
        Module["preRun"] = function() {
            FS.mkdir("/work");
            if (files[0].readMode === 'electron') {
                var path = files[0].path.replace(/[^\\/]+$/, '');
                FS.mount(NODEFS, {
                    root: path
                }, "/work");    
            } else {
                FS.mount(WORKERFS, {
                    files: files
                }, "/work");
            }
        };
        console.debug("baseZimFileName = " + baseZimFileName);
        console.debug('Module["arguments"] = ' + Module["arguments"])
