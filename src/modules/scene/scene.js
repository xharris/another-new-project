const MAP_SAVE_TIME = 500;

var scene_uuid;
var scene_prop;

var placeables = ["entity", "tile", "collision"];
var assoc_obj = {
	"entity" : "entity",
	"tile" : "image"
}

var place_settings = {
	"entity": {
		"" : [
			{"type" : "select", "name" : "icon", "default" : "person", "options" : 
				[
					"person",
					"cat",
					"skull"
				]
			},
			{"type" : "color", "name" : "color", "default" : "#ffffff"},
			{"type" : "number", "name" : "width", "default" : 32, "min" : 0, "max" : 1000000},
			{"type" : "number", "name" : "height", "default" : 32, "min" : 0, "max" : 1000000},
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
	document.addEventListener('project.open', function(e) {
		place_settings.entity[""][1].default = b_library.getRandomBackColor();
	});

	document.addEventListener('ide.close', function(e){
		mapSave();
	});

	document.addEventListener('project.run', function(e){
		mapSave();
	});
};

exports.libraryAdd = function(uuid, name) {
	return {
		map_data: '',		// elements placed on map and map settings
		placeables: {},		// sidebar settings
	}
}

function mapSave(){
	if (map) {
		scene_prop.map_data = b_util.compress(map.export());
    	b_project.autoSaveProject();
	}
}

var curr_category = 'entity';
var curr_object = {};
function updateSidebar() {
	place_settings.entity[""][1].default = b_library.getRandomBackColor();

	// fill in categories
	fillSelect(win_sel + " .sidebar .in-category", placeables, curr_category);
	catSelectChange(curr_category);

	if (curr_object[curr_category] !== undefined) {
		$(win_sel + " .sidebar .in-object option").filter(function() {
		    return $(this).val() == curr_object[curr_category]; 
		}).prop('selected', true);
		objSelectChange(curr_object[curr_category]);
	}
}

var win_sel;
var map;
var mapSaveTimeout;

exports.onDblClick = function(uuid, properties) {
	scene_uuid = uuid;
	scene_prop = properties;

	var scene_html = ""+
            "<div id='main-editor'></div>"+ 
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
            "</div>"
    win_sel = b_ide.setWorkspace("scene", scene_html);

	/*
	win_sel = blanke.createWindow({
        x: 210, 
        y: 50,
        width: 750,
        height: 475,
        class: 'scene',
        title: properties.name,
        html: scene_html,
	    onClose: function(){
	    	mapSave();
	    }
    });
    */

    // initialize map editor
	map = nwPLUGINS['map_editor'].init({
		id: "main-editor",
		loadData: b_util.decompress(scene_prop.map_data),
		onLayerChange: layerChange,
		onMapChange: function() {
			clearTimeout(mapSaveTimeout);
			mapSaveTimeout = setTimeout(mapSave, MAP_SAVE_TIME)
		}
	});

	document.addEventListener("something.saved", updateSidebar);
	document.addEventListener("library.add", updateSidebar);
	document.addEventListener("library.delete", updateSidebar);

	updateSidebar();

	// make sidebar resizable
    $(win_sel + " .sidebar").resizable({
    	handles: "w"
	});

	// event handlers - categories, objects
	$(win_sel + " .sidebar .in-category").on('change', function(e){
		catSelectChange(this.value);
	});
	$(win_sel + " .sidebar .in-object").on('change', function(e){
		objSelectChange(this.value);
	});

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
		map.setLayer(map.layerNameToNum(this.value));
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

	$(win_sel + " #main-editor").on('mouseenter', function(){
		map.enableFocusClick();
	})
}

function layerChange(e) {
	var layer_names = e.layers.map(function(l){
		return e.map.layerNumToName(l);
	});
	fillSelect(win_sel + " .sidebar .layer-container .in-layer", layer_names, layer_names[e.layers.indexOf(e.current)]);
}

function getSelectedCategory() {
	return $(win_sel + " .sidebar .in-category").val().toLowerCase();
}

function catSelectChange(value) {
	// check if category is valid
	if (!placeables.includes(value))
		return;

	curr_category = value;
	var new_cat = value.toLowerCase();

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
		var curr_obj = ifndef(curr_object[curr_category], uuids[0]);
		fillSelect(win_sel + " .sidebar .in-object", uuids, curr_obj);
		objSelectChange(curr_obj);

		// change text values
		$(win_sel + " .sidebar .in-object").children('option').each(function(i) { 
		    $(this).html(objects[$(this).val()]);
		});
	}

}

function updateObj(uuid, new_options){
	map.updateObject("uuid", uuid, new_options);
}

function cleanIconOption(icon) {
	var ret = nwPATH.basename(icon, nwPATH.extname(icon));
	console.log(ret)
	return ret;
}

function objSelectChange(uuid) {
	// check if uuid is valid
	if (!(typeof uuid === 'string' || uuid instanceof String))
		return;

	curr_object[curr_category] = uuid;	
	var category = getSelectedCategory();

	map.clearPlacer();

	// load settings form
    if (!scene_prop.placeables[uuid])
        scene_prop.placeables[uuid] = blanke.extractDefaults(place_settings[category]);
	    blanke.createForm(win_sel + " .sidebar .obj-settings-container", place_settings[category], scene_prop.placeables[uuid],
	        function (type, name, value, subcategory) {
	        	scene_prop.placeables[uuid][name] = value;
	        	
	        	if (category === "entity") {
	        		var icon_path = nwPATH.join(__dirname, "images", cleanIconOption(scene_prop.placeables[uuid].icon) + ".png");
	        		var props = scene_prop.placeables[uuid]

			    	map.setPlacer('rect',{
			    		saveInfo: {
			    			type: "entity",
			    			uuid: uuid
			    		},
			    		icon: icon_path,
			    		color: props['color'],
			    		width: props['width'],
			    		height: props['height'],
			    		resizable: true
			    	});

			    	var new_options = $.extend({}, scene_prop.placeables[uuid]);
			    	new_options.icon = icon_path;

	        		updateObj(uuid, new_options);
	    		}

	        	if (category === "tile") {
	        		fillTileSelectorGrid(uuid);

	        		/* // UNTESTED
	    			var obj = b_library.getByUUID('image', uuid);
					var img_path = nwPATH.join(b_project.getResourceFolder('image'), obj.path)

	        		updateObj(uuid, {path: img_path});
	        		*/
	        	}

	        	b_project.autoSaveProject();
	        }
	    );

    // load object editor html
    $(win_sel + " .sidebar .obj-preview").html('');

    if (category === "entity") {
    	map.setPlacer('rect',{
    		saveInfo: {
    			type: "entity",
    			uuid: uuid
    		},
    		icon: nwPATH.join(__dirname, "images", scene_prop.placeables[uuid]['icon'] + ".png"),
    		color: scene_prop.placeables[uuid]['color'],
    		resizable: true
    	});
    }

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
    		var img_width = $(win_sel + " .obj-preview > .img-preview").width();
	    	var img_height = $(win_sel + " .obj-preview > .img-preview").height();

    		// reset selection
    		$(win_sel + " .obj-preview > .selection").css({
    			"left": img_width+"px", "top": img_height+"px",
    			"width": "0px", "height": "0px"
    		});

    		map.clearPlacer('image');
    	});

    	$(win_sel + " .tile-selector").on('mouseup', function(){
    		dragging = false;

    		// set placer in map editor
    		var sel_selection = win_sel + " .obj-preview > .selection";
    		if (parseInt($(sel_selection).css('width')) > 0 && parseInt($(sel_selection).css('height')) > 0) {
		    	var crop = {
	    			x: parseInt($(sel_selection).css('left')), y: parseInt($(sel_selection).css('top')),
	    			width: parseInt($(sel_selection).css('width')), height: parseInt($(sel_selection).css('height'))
	    		}

		    	map.setPlacer('image', {
		    		saveInfo: {
		    			type: "image",
		    			uuid: uuid,
		    			crop: crop
		    		},
		    		path: nwPATH.join(b_project.getResourceFolder('image'), obj.path),
		    		crop: crop
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