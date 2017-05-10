document.addEventListener("filedrop", function(e) {
	importMap(e.detail.path);
});

exports.libraryAdd = function(uuid, name) {
    return {
        
    };
}

function importMap(path) {
    if (nwPATH.extname(path) === ".tmx") {
    	b_project.importResource('map', path, function(e) {
    		var new_img = b_library.add('map');
    		new_img.path = nwPATH.join(b_project.getResourceFolder('map'), nwPATH.basename(e));
    	});
    }
}
