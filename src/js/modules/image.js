document.addEventListener("filedrop", function(e) {
	importImage(e.detail.path);
});

function importImage(path) {
	b_project.importResource('image', path, function(e) {
		var new_img = b_library.add('image');
		new_img.path = nwPATH.join('image', nwPATH.basename(e));

		console.log(b_library);
	})
}

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
	                importImage(path[p]);
	            }
            }
        }
    );
}