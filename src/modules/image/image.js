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
	                importImage(path[p]);
	            }
            } else {
            	b_library.delete(uuid);
            }
        }
    );
    return 0;
}

function importImage(path) {
    if (['.jpeg', '.jpg', '.png', '.bmp'].includes(nwPATH.extname(path))) {
    	b_project.importResource('image', path, function(e) {
    		var new_img = b_library.add('image');
    		new_img.path = nwPATH.basename(e);
    	});
    }
}

exports.onMouseEnter = function(uuid, properties) {
    // show image preview in library
    if (properties.path.length > 0) {
        $(".library").append(
            "<img src='"+nwPATH.join(b_project.getResourceFolder('image'), properties.path)+"' class='img-hover img-hover-"+uuid+"'/>"
        );
        $(".img-hover .img-hover-"+uuid).offset({top: $('.library .object[data-uuid="'+uuid+'"]').position().top});
    }

    // set tooltip
    var img = new Image();
    img.onload = function() {
      $(".library .object[data-uuid='"+uuid+"'").attr("title", 
            properties.path+"\n"+
            "Dimensions: "+this.width+" x "+this.height
       );
    }
    img.src = nwPATH.join(b_project.getResourceFolder('image'), properties.path);

}

exports.onMouseLeave = function(uuid, properties) {
    $('.library .img-hover').remove();
}
