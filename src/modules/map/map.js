document.addEventListener("filedrop", function(e) {
	importMap(e.detail.path);
});

exports.libraryAdd = function(uuid, name) {
    eDIALOG.showOpenDialog(
        {
            title: "import map",
            properties: ["openFile"],
            filters: [
            	{name: 'Tiled Map', extensions: ['tmx']},
            ]
        },
        function (path) {
            if (path) {
                for (var p = 0; p < path.length; p++) {
	                importMap(path[p]);
	            }
            } else {
            	b_library.delete(uuid);
            }
        }
    );
    return 0;
}

function importMap(path) {
    if (nwPATH.extname(path) === ".tmx") {
    	b_project.importResource('map', path, function(e) {
    		var new_img = b_library.add('map');
    		new_img.path = nwPATH.join(b_project.getResourceFolder('map'), nwPATH.basename(e));
    	});
    }
}
