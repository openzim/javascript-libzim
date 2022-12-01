self.addEventListener("message", function(e) {
    var outgoingMessagePort = e.ports[0];
    console.debug("WebWorker called");
    var files = e.data.files;
    var fileName = files[0].name;
    Module = {};
    Module["onRuntimeInitialized"] = function() {
        console.debug("runtime initialized");
        var result = Module["test_big_file"]("/work/" + fileName);
        outgoingMessagePort.postMessage(result);
    };
    Module["arguments"] = [ "/work/" + fileName ];
    Module["preRun"] = function() {
        FS.mkdir("/work");
        FS.mount(WORKERFS, {
            files: files
            }, "/work");
    };
    console.debug("fileName = " + fileName);

