var scene_uuid;
var scene_prop;

var placeables = ["entity", "tile", "collision"];
var place_settings = {
	"entity": {
		"" : [
			{"type" : "select", "name" : "icon", "default" : "player", "options" : 
				[
					"person",
					"cat"
				]
			},
		]
	},
	"tile": {
		"tile size" : [
			{"type" : "number", "name" : "[tile]width", "default" : 16, "min" : 0, "max" : 1000000},
			{"type" : "number", "name" : "[tile]height", "default" : 16, "min" : 0, "max" : 1000000}
		],
		"offset" : [
			{"type" : "number", "name" : "[offset]x", "default" : 0, "min" : 0, "max" : 1000000},
			{"type" : "number", "name" : "[offset]y", "default" : 0, "min" : 0, "max" : 1000000}
		],
		"spacing" : [
			{"type" : "number", "name" : "[spacing]x", "default" : 0, "min" : 0, "max" : 1000000},
			{"type" : "number", "name" : "[spacing]y", "default" : 0, "min" : 0, "max" : 1000000},
		]
	}
}

exports.loaded = function() {

}

exports.libraryAdd = function(uuid, name) {
	return {
		layer_objs: {},		// elements placed on map
		placeables: {},		// sidebar settings
		layer_settings: {}	// snapx, snapy, show_grid, etc...
	}
}

exports.onClose = function(uuid, properties) {

}

var win_sel;
var map;

exports.onDblClick = function(uuid, properties) {
	scene_uuid = uuid;
	scene_prop = properties;

	win_sel = blanke.createWindow({
        x: 210, 
        y: 50,
        width: 750,
        height: 475,
        class: 'scene',
        title: properties.name,
        html: ""+
            "<div class='sidebar'>"+
            	"<div class='object-container'>"+
            		"<select class='in-category'></select>"+
            		"<select class='in-object'></select>"+

            		"<div class='obj-preview'></div>"+
            		"<div class='obj-settings-container'></div>"+
            	"</div>"+
            	"<div class='layer-container'></div>"+
            "</div>"+
            "<div id='main-editor'>"+            
	        "</div>"
    });

	// make sidebar resizable
    $(win_sel + " .sidebar").resizable({
    	handles: "e"
	});

	// fill in categories
	fillSelect(win_sel + " .sidebar .in-category", placeables, placeables[0]);
	catSelectChange('entity');

	// attach event handlers
	$(win_sel + " .sidebar .in-category").on('change', catSelectChange);
	$(win_sel + " .sidebar .in-object").on('change', objSelectChange);

	$(win_sel + " .sidebar .in-category").on('mouseup', function(){
		var open = $(this).data("isopen");
		if (open)
			catSelectChange(this.value);

		$(this).data("isopen", !open);
	});
	$(win_sel + " .sidebar .in-object").on('mouseup', function(){
		var open = $(this).data("isopen");
		if (open)
			objSelectChange(this.value);

		$(this).data("isopen", !open);
	});

	// initialize map editor
	var map = nwPLUGINS['map_editor'].init({
		id: "main-editor"
	});
}

function getSelectedCategory() {
	return $(win_sel + " .sidebar .in-category").val().toLowerCase();
}

function catSelectChange(value) {
	// check if category is valid
	if (!placeables.includes(value))
		return;

	var new_cat = value.toLowerCase();

	var assoc_obj = {
		"entity" : "entity",
		"tile" : "image"
	}

	if (Object.keys(assoc_obj).includes(new_cat)) {
		var obj_type = assoc_obj[new_cat];

		// get objects from this category
		var objects = {};
		var uuids = Object.keys(b_library.objects[obj_type]);
		var new_uuids = [];

		for (var l = 0; l < uuids.length; l++) {
			var obj = b_library.objects[obj_type][uuids[l]]
			var can_add = true;

			if (obj_type === "image" && !obj.parameters["use as tileset"]) {
				can_add = false;
			}

			if (can_add) {
				objects[uuids[l]] = obj.name;
				new_uuids.push(uuids[l]);
			}
		}

		uuids = new_uuids;

		// populate obj select
		fillSelect(win_sel + " .sidebar .in-object", uuids, uuids[0]);
		objSelectChange(uuids[0])

		// change text values
		$(win_sel + " .sidebar .in-object").children('option').each(function(i) { 
		    $(this).html(objects[$(this).val()]);
		});
	}

}

function objSelectChange(uuid) {
	// check if uuid is valid
	if (!(typeof uuid === 'string' || uuid instanceof String))
		return;

	var category = getSelectedCategory();

	// load settings form
    if (!scene_prop.placeables[uuid])
        scene_prop.placeables[uuid] = blanke.extractDefaults(place_settings[category]);
    blanke.createForm(win_sel + " .sidebar .obj-settings-container", place_settings[category], scene_prop.placeables[uuid],
        function (type, name, value, subcategory) {
        	scene_prop.placeables[uuid][name] = value;

        	if (category === "tile") {
        		fillTileSelectorGrid(uuid);
        	}

        	b_project.autoSaveProject();
        }
    );

    if (category === "tile") {
    	var obj = b_library.getByUUID('image', uuid);

    	$(win_sel + " .sidebar .obj-preview").html(
    		"<img class='img-preview' src='"+nwPATH.join(b_project.getResourceFolder('image'), obj.path)+"'/>"+
    		"<div class='tile-selector'></div>"
    	);

    	// set tile selector size to image size
    	$(win_sel + " .obj-preview > .img-preview").load(function(){
    		var img_width = $(win_sel + " .obj-preview > .img-preview").width();
	    	var img_height = $(win_sel + " .obj-preview > .img-preview").height();

	    	$(win_sel + " .obj-preview > .tile-selector").css({
	    		"width" : img_width + 'px',
	    		"height" : img_height + 'px'
	    	});
        	
        	fillTileSelectorGrid(uuid);	
    	});
    	

    	// tile selection events
    	var tile_prop = scene_prop.placeables[uuid];
    	var dragging = false;
    	$(win_sel + " .tile-selector").on('mousedown', function(){
    		dragging = true;

    		// reset selection
    		//$(win_sel + " .tile-selector > .selection").
    	});
    	$(win_sel + " .tile-selector").on('mouseup', function(){
    		dragging = false;
    	});

    	$(win_sel + " .tile-selector").on('mousemove', function(e){
    		if (dragging) {
    			var offset = $(this).offset(); 
    			var mx = e.pageX - offset.left;
   				var my = e.pageY - offset.top;

   				var snapx = Math.floor((mx - tile_prop['[offset]x']) / (tile_prop['[tile]width'] + tile_prop['[spacing]x']));
   				var snapy = Math.floor((my - tile_prop['[offset]y']) / (tile_prop['[tile]height'] + tile_prop['[spacing]y']));

   				if (snapx < 0) snapx = 0;
   				if (snapy < 0) snapy = 0;

   				console.log(snapx, snapy);
    		}
    	});
    }
}

function fillTileSelectorGrid(uuid) {
	var props = scene_prop.placeables[uuid];

	// set up tiles html
	var grid_html = "";
	var size = ($(win_sel + " .obj-preview > .img-preview").width() * $(win_sel + " .obj-preview > .img-preview").height()) / (props['[tile]width'] * props['[tile]height']);
	for (var i = 0; i < size; i++) {
		grid_html += "<div class='grid-tile'></div>";
	}

	// add tiles to container
	$(win_sel + " .tile-selector").html(grid_html);

	// set dimensions/spacing
	$(win_sel + " .tile-selector").css({
		"padding-left": props['[offset]x'] + 'px',
		"padding-top": props['[offset]y'] + 'px'
	});
	$(win_sel + " .tile-selector > .grid-tile").css({
		"width": props['[tile]width'] + 'px',
		"height": props['[tile]height'] + 'px',
		"margin-right": props['[spacing]x'] + 'px',
		"margin-top": props['[spacing]y'] + 'px',
	});

	$(win_sel + " .sidebar").trigger("resize");
}