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
		map_data: '',		// elements placed on map
		map_settings: '',	// map_editor settings (snapx, snapy, etc)
		placeables: {},		// sidebar settings
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
            	"<div class='layer-container'>"+
            		"<div class='group-layer-move'>"+
	            		"<button class='ui-button btn-up' title='move layer up in list'><i class='mdi mdi-chevron-up'></i></button>"+
	            		"<button class='ui-button btn-down' title='move layer down in list'><i class='mdi mdi-chevron-down'></i></button>"+
            		"</div>"+
            		"<div class='in-layer-container'>"+
            			"<select class='in-layer' title='Order in which layers are drawn. First in list = drawn first.'></select>"+
            		"</div>"+
            		"<div class='group-layer-edit'>"+
	            		"<button class='ui-button btn-add' title='add a layer'><i class='mdi mdi-plus'></i></button>"+
	            		"<button class='ui-button btn-delete' title='remove current layer'><i class='mdi mdi-minus'></i></button>"+
	            	"</div>"+
            	"</div>"+
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

	// event handlers - categories, objects
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

	// add layers
	$(win_sel + " .sidebar .layer-container .in-layer").on('change', function(e){
		map.setLayer(this.value.toLowerCase().replace("layer ", ""));
	});

	$(win_sel + " .sidebar .layer-container .btn-add").on('click', function(){
		map.addLayer();
	});
	$(win_sel + " .sidebar .layer-container .btn-delete").on('click', function(){
		blanke.showModal("Are you sure you want to remove current layer? All objects on the layer will be removed too.",{
	        "yes": function() {map.removeLayer();},
	        "no": undefined
	    }); 
	});
	$(win_sel + " .sidebar .layer-container .btn-up").on('click', function(){
		map.moveLayerUp();
	});
	$(win_sel + " .sidebar .layer-container .btn-down").on('click', function(){
		map.moveLayerDown();
	});

	// initialize map editor
	map = nwPLUGINS['map_editor'].init({
		id: "main-editor",
		onLayerChange: layerChange
	});
}

function layerChange(current, layers) {
	var layer_names = layers.map(function(l){
		return "layer " + l.toString();
	});
	fillSelect(win_sel + " .sidebar .layer-container .in-layer", layer_names, layer_names[layers.indexOf(current)]);
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
    		"<div class='tile-selector'></div>"+
    		"<div class='selection'></div>"
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
    	$(win_sel + " .tile-selector").on('mousedown', function(e){
    		dragging = true;

    		// reset selection
    		$(win_sel + " .obj-preview > .selection").css({
    			"left": "100%", "top": "100%",
    			"width": "0px", "height": "0px"
    		});

    		map.clearPlacer('image');
    	});

    	$(win_sel + " .tile-selector").on('mouseup', function(){
    		dragging = false;

    		// set placer in map editor
    		var sel_selection = win_sel + " .obj-preview > .selection";
    		if (parseInt($(sel_selection).css('width')) > 0 && parseInt($(sel_selection).css('height')) > 0) {
		    	map.setPlacer('image', {
		    		path: nwPATH.join(b_project.getResourceFolder('image'), obj.path),
		    		crop: {
		    			x: parseInt($(sel_selection).css('left')), y: parseInt($(sel_selection).css('top')),
		    			width: parseInt($(sel_selection).css('width')), height: parseInt($(sel_selection).css('height'))
		    		}
		    	});
		    }
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

				// check if selection can be expanded
				var sel_selection = win_sel + " .obj-preview > .selection";
				var box_x = parseInt($(sel_selection).css('left'));
				var box_y = parseInt($(sel_selection).css('top'));
				var box_width = parseInt($(sel_selection).css('width'));
				var box_height = parseInt($(sel_selection).css('height'));

				var new_x = snapx * tile_prop['[tile]width'];
				var new_y = snapy * tile_prop['[tile]height'];
				var new_width = (snapx * tile_prop['[tile]width']) + tile_prop['[tile]width'] - box_x;
				var new_height = (snapy * tile_prop['[tile]height']) + tile_prop['[tile]height'] - box_y;

				// x/y
				if (new_x < box_x) 
					$(sel_selection).css({
						'left': new_x+'px'
					});
				if (new_y < box_y) 
					$(sel_selection).css({
						'top': new_y+'px'
					});

				// width/height
				if (new_width > box_width) 
					$(sel_selection).css({
						'width': new_width+'px'
					});
				if (new_height > box_height) 
					$(sel_selection).css({
						'height': new_height+'px'
					});
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