document.addEventListener("filedrop", function(e) {
	importImage(e.detail.path);
});

exports.libraryAdd = function(uuid, name) {
    eDIALOG.showOpenDialog(
        {
            title: "import image",
            properties: ["openFile"],
            filters: [
            	{name: 'All supported image types', extensions: ['jpeg','jpg','png','bmp']},
            	{name: 'JPEG', extensions: ['jpeg','jpg']},
            	{name: 'PNG', extensions: ['png']},
            	{name: 'BMP', extensions: ['bmp']},
            ]
        },
        function (path) {
            if (path) {
                for (var p = 0; p < path.length; p++) {
	                importImage(path[p], uuid);
	            }
            } else {
            	console.log('delete ' + uuid)
            	b_library.delete('image', uuid);
            }
        }
    );
}

function importImage(path, uuid=0) {
	b_project.importResource('image', path, function(e) {
		var new_img;
		if (uuid) {
			new_img = b_library.getByUUID(uuid);
		} else {
			new_img = b_library.add('image');
		}
		new_img.path = nwPATH.join('image', nwPATH.basename(e));
	})
}

exports.onDblClick = function(uuid, properties) {
    console.log(uuid)
    console.log(properties);
}