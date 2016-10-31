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

exports.onMouseEnter = function(uuid, properties) {
    if (properties.path.length > 0) {
        $(".library").append(
            "<img src='"+nwPATH.join(b_project.curr_project, properties.path)+"' class='img-hover img-hover-"+uuid+"'/>"
        );
        $(".img-hover .img-hover-"+uuid).offset({top: $('.library .object[data-uuid="'+uuid+'"]').position().top});
    }
    $(".library .object[data-uuid='"+uuid+"'").attr("title", properties.path);
}

exports.onMouseLeave = function(uuid, properties) {
    $('.library .img-hover-'+uuid).remove();
}
