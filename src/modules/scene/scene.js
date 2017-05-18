var scene_uuid;
var scene_prop;

var placeables = ["entity", "tiles", "collision"];
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
exports.onDblClick = function(uuid, properties) {
	scene_uuid = uuid;
	scene_prop = properties;

	var konva = require('./konva.min.js');

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
            		"<div class='obj-settings-container'></div>"+
            	"</div>"+
            	"<div class='layer-container'></div>"+
            "</div>"+
            "<div class='main-editor'>"+            
	            "<div id='canvas'></div>"+
	            "<div class='scene-settings'></div>"+
	        "</div>"
    });

	// make sidebar resizable
    $(win_sel + " .sidebar").resizable({
    	handles: "e",
		resize: function(event, ui){
			$(win_sel + " .main-editor").css("margin-left", ui.size.width);
		},
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
}

function getSelectedCategory() {
	return $(win_sel + " .sidebar .in-category").val().toLowerCase();
}

function catSelectChange(value) {
	// check if category is valid
	if (!placeables.includes(value))
		return;

	var new_cat = value.toLowerCase();

	if (new_cat === "entity") {
		// get objects from this category
		var objects = {};
		var uuids = Object.keys(b_library.objects.entity);
		for (var l = 0; l < uuids.length; l++) {
			objects[uuids[l]] = b_library.objects.entity[uuids[l]].name;
		}

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
        	console.log(scene_prop);
        }
    );
}