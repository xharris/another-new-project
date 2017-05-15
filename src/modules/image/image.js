var ZOOM_AMT = 15;

var image_settings = {
    "FilterMode" : [
        {"type" : "select", "name" : "min", "default" : "linear", "options" : ["linear", "nearest"], "tooltip": "How the image is filtered when scaling down."},
        {"type" : "select", "name" : "mag", "default" : "linear", "options" : ["linear", "nearest"], "tooltip": "How the image is filtered when scaling up."},
        {"type" : "number", "name" : "anisotropy", "default" : 1, "min" : 0, "max" : 1000000, "tooltip": "Maximum amount of anisotropic filtering used."}
    ],
    "WrapMode" : [
        {"type" : "select", "name" : "horizontal", "default" : "clampzero", "options" : ["clamp", "repeat", "clampzero", "mirroredrepeat"]},
        {"type" : "select", "name" : "vertical", "default" : "clampzero", "options" : ["clamp", "repeat", "clampzero", "mirroredrepeat"]}
    ]
}

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

exports.onDblClick = function(uuid, properties) {
    var win_sel = blanke.createWindow({
        x: 210, 
        y: 50,
        width: 550,
        height: 350,
        class: 'image',
        title: properties.name,
        html: "<div class='preview-container'>"+
            "<div class='img-preview-container'>"+
                "<img src='"+nwPATH.join(b_project.getResourceFolder('image'), properties.path)+"' class='preview'>"+
            "</div>"+
            
            "<div id='zoom-controls' class='ui-btn-group'>"+
                "<button id='btn-zoom-in' class='ui-button-sphere'>"+
                    "<i class='mdi mdi-plus'></i>"+
                "</button>"+
                "<button id='btn-zoom-out' class='ui-button-sphere'>"+
                    "<i class='mdi mdi-minus'></i>"+
                "</button>"+
            "</div>"+
            "<div class='img-settings'></div>"+
        "</div>"
    });

    // load image preview
    // ...

    // add event listeners for zooming on image
    $(win_sel + " #zoom-controls #btn-zoom-in").on('click', function(){
        zoomImage(win_sel, ZOOM_AMT);
    });
    $(win_sel + " #zoom-controls #btn-zoom-out").on('click', function(){
        zoomImage(win_sel, -ZOOM_AMT);
    });

    // load settings form
    if (!properties.parameters)
        properties.parameters = blanke.extractDefaults(image_settings);
    blanke.createForm(win_sel + " .img-settings", image_settings, properties.parameters,
        function (type, name, value, subcategory) {
            properties.parameters[name] = value;
        }
    );
}

// zoom +1, -1, etc
function zoomImage(sel_parent, amt) {
    var img_sel = sel_parent + " .img-preview-container .preview";
    $(img_sel).css({
        "width": ($(img_sel).width()+($(img_sel).width()*(amt/100)))+"px",
        "height": ($(img_sel).height()+($(img_sel).height()*(amt/100)))+"px"
    })
}

function importImage(path) {
    if (['.jpeg', '.jpg', '.png', '.bmp'].includes(nwPATH.extname(path))) {
    	b_project.importResource('image', path, function(e) {
    		var new_img = b_library.add('image');
    		new_img.path = nwPATH.basename(e);
            new_img.parameters = blanke.extractDefaults(image_settings);
    	});
    }
}

exports.onMouseEnter = function(uuid, properties) {
    // add image preview container
    if ($(".library .img-hover-container").length == 0) {
        $(".library").append("<div class='img-hover-container'></div>");
    }

    // show image preview in library
    if (properties.path.length > 0) {
        $(".library .img-hover-container").append(
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
    $('.library .img-hover-container .img-hover').remove();
}
