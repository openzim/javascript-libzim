self.addEventListener("message", function(e) {
    var t0 = performance.now();
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
                var t1 = performance.now();
                var blob = item.getData();
                var t2 = performance.now();
                var content = blob.getContent();
                var t3 = performance.now();
                // TODO : is there a more efficient way to make the Array detachable? So that it can be transfered back from the WebWorker without a copy?
                var contentArray = new Uint8Array(content);
                var t4 = performance.now();
                outgoingMessagePort.postMessage({ content: contentArray, mimetype: item.getMimetype(), isRedirect: entry.isRedirect()});
                var t5 = performance.now();
                var getTime = Math.round(t1 - t0);
                var getDataTime = Math.round(t2 - t1);
                var getContentTime = Math.round(t3 - t2);
                var copyArrayTime = Math.round(t4 - t3);
                var postMessageTime = Math.round(t5 - t4);
                var totalTime = Math.round(t5 - t0);
                console.debug("content length = " + content.length + " read in " + totalTime + " ms"
                        + " (" + getTime + " ms to find the entry, "
                        + getDataTime + " ms for getData, "
                        + getContentTime + " ms for getContent, "
                        + copyArrayTime + " ms for array copying, "
                        + postMessageTime + " ms for postMessage"
                        + ")");
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
        // When using split ZIM files, we need to remove the last two letters of the suffix (like .zimaa -> .zim)
        var baseZimFileName = files[0].name.replace(/\.zim..$/, '.zim');
        Module = {};
        Module["onRuntimeInitialized"] = function() {
            console.debug("runtime initialized");
            Module.loadArchive("/work/" + baseZimFileName);
            outgoingMessagePort.postMessage("runtime initialized");
        };
        Module["arguments"] = [];
        for (let i = 0; i < files.length; i++) {
            Module["arguments"].push("/work/" + files[i].name);
        }
        Module["preRun"] = function() {
            FS.mkdir("/work");
            FS.mount(WORKERFS, {
                files: files
                }, "/work");
        };
        console.debug("baseZimFileName = " + baseZimFileName);
        console.debug('Module["arguments"] = ' + Module["arguments"])

