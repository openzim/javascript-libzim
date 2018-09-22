if (typeof (Module) === "undefined") Module = {};
self.addEventListener('message', function(e) {
    var files = e.data.files;
    var action = e.data.action;
    if (action === "init") {        
        console.log(files[0].name);
        Module["arguments"] = ["/work/" + files[0].name];
        Module["preInit"] = function() {
            FS.mkdir("/work");
            FS.mount(WORKERFS, {
                files: files // Array of File objects or FileList
                }, '/work');
            //FS.createLazyFile('/', "tmp.zim", "wiktionary_en_all_2017-03.zim", true, false);
        };
    }
    else {
        var f = new Module.File("/work/" + files[0].name);
        console.log(f.getArticleByUrl("A/Baby_Grand.html"));
    }

