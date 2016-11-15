var sel_uuid, sel_prop;

var game;
var game_objects = {};
var groups = {};

var grid_settings = {
	'height': 33,
	'width': 33
}
var grid_opacity = 0.1;
var grid_tiles;
var camera = {x: 0, y: 0};
var camera_enabled = true;

var cursors;
var pGraphics;
var origin_g;

var selected_obj = {
	type: '',
	uuid: '',
	properties: {}
}

var k_ctrl;

var placeables = ["entity", "tile"];

exports.loaded = function() {

}

exports.libraryAdd = function(uuid, name) {
	return {
		map: ''
	}
}

exports.onClose = function(uuid, properties) {
	game = undefined;

	// save all data to json

}

exports.onDblClick = function(uuid, properties) {
	b_canvas.init("scene");
	game = b_canvas.pGame;

	sel_uuid = uuid;
	sel_prop = properties;

	for (var p in placeables) {
		var type = placeables[p];
		game_objects[type] = ifndef(game_objects[type], []);
	}

	$(".workspace").append(
		"<div class='data-bar'>"+
			"<div class='mouse-coords'>"+
				"<div class='title'>mouse</div>"+
				"<div class='x'></div>"+
				"<div class='y'></div>"+
			"</div>"+
			"<div class='grid-size'>"+
				"<div class='title'>grid</div>"+
				"<input class='ui-input' data-input='width' type='number' value='"+grid_settings.width+"'>"+
				"<input class='ui-input' data-input='height' type='number' value='"+grid_settings.height+"'>"+
			"</div>"+
			"<div class='tooltip'>"+
				"<div class='title'></div>"+
				"<div class='x'></div>"+
				"<div class='y'></div>"+
			"</div>"+
		"</div>"
	);

	$(".workspace.scene .grid-size").on('change', 'input', function(){
		grid_settings[$(this).data('input')] = parseInt($(this).val());
		createGrid();
	});

	// loadScene(sel_prop.map);
}

document.addEventListener("library.select", function(e) {
	if (game) {
		for (var p in placeables) {
			var type = placeables[p];
			if (e.detail.type === type) {
				selected_obj.type = type;
				selected_obj.uuid = e.detail.uuid;
				selected_obj.properties = e.detail.properties;
			}
		}

		if (e.detail.type === "tile") {
			if (!game) return;

			// open up tile selector
			b_library.disableDrag();

			var img_uuid = selected_obj.properties.img_source;
			var tile_img_src = nwPATH.join(b_project.curr_project, b_library.getByUUID('image', img_uuid).path);

			$(".library .object[data-uuid='"+e.detail.uuid+"']").append(
				"<div class='tile-selector'>"+
					"<img src='"+tile_img_src+"'>"+
					"<div class='frame-container'></div>"+
				"</div>"
			);

			// add tile grid
			var sheet_data = selected_obj.properties.parameters;
			$(".tile-selector > img")[0].onload = function() {
				var img_width = $(".tile-selector > img").width();
				var img_height = $(".tile-selector > img").height();

				var frame_count = (img_width * img_height) / ((sheet_data.tileWidth + sheet_data.tileMarginX) * (sheet_data.tileHeight + sheet_data.tileMarginY));
				var col_count = img_width / (sheet_data.tileWidth + sheet_data.tileMarginX);

			    for (var f = 0; f < frame_count; f++) {
			    	var x = f * sheet_data.tileWidth;
			    	var y = 0;
			    	if (f >= col_count) {
			    		var row = Math.floor(f / (img_height / (sheet_data.tileHeight + sheet_data.tileMarginY)));
			    		x = (f - (col_count * row)) * (sheet_data.tileWidth + sheet_data.tileMarginX);
			    		y = Math.floor(f / col_count) * sheet_data.tileHeight;
			    	}

			    	var width = sheet_data.tileWidth;
			    	var height = sheet_data.tileHeight;

			    	$(".tile-selector .frame-container").append(
			    		"<div class='frame-box' data-frame='"+f+"' data-x='"+x+"' data-y='"+y+"' data-width='"+width+"' data-height='"+height+"'></div>"
			    	);
			    }
			    $(".tile-selector .frame-container").css({
			    	'width': img_width
			    });
			    $(".tile-selector .frame-container .frame-box").css({
			    	'width': sheet_data.tileWidth,
			    	'height': sheet_data.tileHeight,
			        'margin-right': sheet_data.tileMarginX,
			        'margin-bottom': sheet_data.tileMarginY
			    });				
			}

			$(".tile-selector").on('click', '.frame-box', function(e) {
				$(".tile-selector .frame-box").removeClass("selected");
				$(this).addClass("selected");
			});
		}
	}
});

document.addEventListener("library.deselect", function(e) {
	b_library.enableDrag();

	selected_obj = {
		type: '',
		uuid: '',
		properties: {}
	};

	$(".tile-selector").remove();
});

// place_obj should be structured like 'selected_obj' ^^^^^^^
function placeObject(place_obj, x, y) {
	var type = place_obj.type;
	var uuid = place_obj.uuid;
	var properties = place_obj.properties;

	var ret_obj;

	// place whatever is selected
	if (type === "entity") {
		// draw a rectangle
		var graphic = game.add.graphics(x, y);
	    graphic.lineStyle(1, 0x0000FF, 1);
		graphic.beginFill(0x0000FF, 0.25);
	    graphic.drawRect(0, 0, grid_settings.width, grid_settings.height);
	    
	    setupObject(graphic, uuid, properties.name);

	    ret_obj = graphic;
	}

	if (type === "tile") {		
		if ($(".tile-selector .frame-box.selected").length > 0) {
			var el_frame = $(".tile-selector .frame-box.selected");
			var new_tile = game.add.sprite(x, y, b_library.getByUUID("image", properties.img_source).name);
			var crop = new Phaser.Rectangle($(el_frame).data('x'), $(el_frame).data('y'), $(el_frame).data('width'), $(el_frame).data('height'));
			new_tile.crop(crop);

			if (new_tile) {
				setupObject(new_tile, uuid, properties.name + '(' + $(el_frame).data('frame') + ')');
				
				ret_obj = new_tile;
			}
		}
	}

	return ret_obj;
}

// give object variables for camera movement and setup dragging
function setupObject(obj, uuid, tooltip) {
	obj.uuid = uuid;
	obj.tooltip = tooltip;
	obj.real_x = obj.x - camera.x;
    obj.real_y = obj.y - camera.y;
	obj.inputEnabled = true;
	obj.input.enableDrag(true);	
	obj.input.enableSnap(grid_settings.width, grid_settings.height, true, true);
	obj.snapX = grid_settings.width;
	obj.snapY = grid_settings.height;
	obj.events.onDragStart.add(function(sprite, pointer, x, y) {
		
	});
	obj.events.onDragUpdate.add(function(sprite, pointer, x, y) {
		sprite.input.snapOnDrag = !k_ctrl.isDown;
			 
		sprite.real_x = sprite.x - camera.x;
		sprite.real_y = sprite.y - camera.y;	
		
	});		
	obj.events.onInputOver.add(function(sprite, pointer) {
		// show tooltip
		$(".workspace .data-bar .tooltip > .title").html(sprite.tooltip);
		$(".workspace .data-bar .tooltip > .x").html(sprite.real_x);
		$(".workspace .data-bar .tooltip > .y").html(sprite.real_y);
	});
	obj.events.onInputOut.add(function() {
		// hide tooltip
		$(".workspace .data-bar .tooltip > .title").html("");
		$(".workspace .data-bar .tooltip > .x").html("");
		$(".workspace .data-bar .tooltip > .y").html("");
	});
}

exports.canvas = {
	destroy: function() {
		camera_start = {x:0, y:0};
		camera = {x: 0, y: 0};
	},

	preload: function() {
		game = b_canvas.pGame;

		for (var cat in b_library.objects) {
			for (var o in b_library.objects[cat]) {
				var obj = b_library.objects[cat][o];

				if (cat === "image") {
					var img_path = nwPATH.join(b_project.curr_project, obj.path);
					game.load.image(obj.name, img_path);
				}
				if (cat === "spritesheet") {
					var img_path = nwPATH.join(b_project.curr_project, b_library.getByUUID(obj.img_source).path)
					game.load.spritesheet(obj.name, img_path, obj.frameWidth, obj.frameHeight, obj.frameMax, obj.margin, obj.spacing)
				}
			}
		}
	},

	create: function() {
		createGrid();
		cursors = game.input.keyboard.createCursorKeys();
		k_ctrl = game.input.keyboard.addKey(Phaser.Keyboard.CONTROL);

		game.input.onTap.add(function(p) {
			var place_x = p.x;
			var place_y = p.y;

			var mx = p.x - (camera.x % grid_settings.width);
			var my = p.y - (camera.y % grid_settings.height);

			var place_x = (mx - (mx % grid_settings.width)) + (camera.x % grid_settings.width);
			var place_y = (my - (my % grid_settings.height)) + (camera.y % grid_settings.height);

			var obj = placeObject(selected_obj, place_x, place_y);

	    	if (obj) 
	    		game_objects[selected_obj.type].push(obj);
		});

		game.input.addMoveCallback(function(pointer, x, y) {
			var mx = x - camera.x;
			var my = y - camera.y;

			$(".workspace .data-bar > .mouse-coords .x").html(mx);
			$(".workspace .data-bar > .mouse-coords .y").html(my);
		});
	}
}


var camera_start = {x:0, y:0};
function createGrid() {
	var game = b_canvas.pGame;

	if (pGraphics) pGraphics.destroy();
	if (origin_g) origin_g.destroy();
	if (grid_tiles) grid_tiles.destroy();

	// "+ 1" is to compensate for border size
	var grid_width = grid_settings.width + 1;
	var grid_height =  grid_settings.height + 1;

	// draw grid tile
	pGraphics = game.add.graphics(0,0);

	pGraphics.lineStyle(0.5, 0x000000, grid_opacity);
	pGraphics.moveTo(0,0);
	pGraphics.lineTo(grid_width,0);
	pGraphics.lineTo(grid_width,grid_height);
	pGraphics.lineTo(0,grid_height);
	pGraphics.lineTo(0,0);

	// draw origin lines
	origin_g = game.add.graphics(0,0);
	origin_g.lineStyle(1, 0x000000, grid_opacity);
	origin_g.moveTo(0 + camera.x, 0);
	origin_g.lineTo(0 + camera.x,game.height);
	origin_g.moveTo(0,0 + camera.y);
	origin_g.lineTo(game.width,0 + camera.y);
	
	grid_tiles = game.add.tileSprite(0, 0, game.width, game.height, pGraphics.generateTexture(1,0,-2));
	grid_tiles.z = 1000;
	grid_tiles.inputEnabled = true;
	grid_tiles.input.enableDrag();

	grid_tiles.tilePosition.x = camera.x;
	grid_tiles.tilePosition.y = camera.y;

	grid_tiles.events.onDragStart.add(function(sprite, pointer, x, y) {
		sprite.x = 0;
		sprite.y = 0;
	}, this);

	grid_tiles.events.onDragStop.add(function(sprite, pointer) {
		camera_start.x = camera.x;
		camera_start.y = camera.y;
	}, this);

    grid_tiles.events.onDragUpdate.add(function(sprite, pointer, x, y) {
    	if (!camera_enabled) return;

		sprite.x = 0;
		sprite.y = 0;

		camera.x = camera_start.x + x;
		camera.y = camera_start.y + y;
		
		grid_tiles.tilePosition.x = camera.x;
		grid_tiles.tilePosition.y = camera.y;

		// update origin position
		origin_g.clear();
		origin_g.lineStyle(1, 0x000000, grid_opacity);
		origin_g.moveTo(0 + camera.x, 0);
		origin_g.lineTo(0 + camera.x,game.height);
		origin_g.moveTo(0,0 + camera.y);
		origin_g.lineTo(game.width,0 + camera.y);

		//game.camera.x = camera.x;
		//game.camera.y = camera.y;

		for (var cat in game_objects) {
			for (var obj=0; obj < game_objects[cat].length; obj += 1) {
				var gObj = game_objects[cat][obj];

				gObj.x = gObj.real_x + camera.x;
				gObj.y = gObj.real_y + camera.y;

				gObj.input.snapOffsetX = camera.x;
				gObj.input.snapOffsetY = camera.y;
				
			}
		}
		
	}, this);

	pGraphics.destroy();
}

function setGridSize(width, height) {
	grid_settings.width = width;
	grid_settings.height = height;
	grid_tiles.remove();
	createGrid();
}