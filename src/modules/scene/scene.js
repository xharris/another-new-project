var sel_uuid, sel_prop;

var game;

var grid_settings = {
	'height': 32,
	'width': 32
}
var grid_opacity = 0.1;
var grid_tiles;
var camera = {x: 0, y: 0};

var cursors;
var pGraphics;
var origin_g;

var selected_obj = {
	type: '',
	uuid: '',
	properties: {}
}

exports.loaded = function() {

}

exports.libraryAdd = function(uuid, name) {
	return {
		map: ''
	}
}

exports.onDblClick = function(uuid, properties) {
	b_canvas.init("scene");
	game = b_canvas.pGame;

	sel_uuid = uuid;
	sel_prop = properties;

	// loadScene(sel_prop.map);

	document.addEventListener("library.click", function(e) {
		if (game) {
			if (e.detail.type === "sprite") {
				selected_obj.type = "sprite";
				selected_obj.uuid = e.detail.uuid;
				selected_obj.properties = e.detail.properties;

				console.log('showing ' + selected_obj);
			}
		}
	});
}

exports.canvas = {
	destroy: function() {
		camera_start = {x:0, y:0};
		camera = {x: 0, y: 0};
	},

	preload: function() {
		game = b_canvas.pGame;
	},

	create: function() {
		createGrid();
		cursors = game.input.keyboard.createCursorKeys();
	}
}


var camera_start = {x:0, y:0};
function createGrid() {
	var game = b_canvas.pGame;

	// draw grid tile
	pGraphics = game.add.graphics(0,0);

	pGraphics.lineStyle(0.5, 0x000000, grid_opacity);
	pGraphics.moveTo(0,0);
	pGraphics.lineTo(grid_settings.width,0);
	pGraphics.lineTo(grid_settings.width,grid_settings.height);
	pGraphics.lineTo(0,grid_settings.height);
	pGraphics.lineTo(0,0);

	// draw origin lines
	origin_g = game.add.graphics(0,0);
	origin_g.lineStyle(1, 0x000000, grid_opacity);
	origin_g.moveTo(0 + camera.x, 0);
	origin_g.lineTo(0 + camera.x,game.height);
	origin_g.moveTo(0,0 + camera.y);
	origin_g.lineTo(game.width,0 + camera.y);
	
	grid_tiles = game.add.tileSprite(0, 0, game.width, game.height, pGraphics.generateTexture(1,0,-2));
	grid_tiles.inputEnabled = true;
	grid_tiles.input.enableDrag();

	grid_tiles.events.onDragStart.add(function(sprite, pointer, x, y) {
		sprite.x = 0;
		sprite.y = 0;
	}, this);

	grid_tiles.events.onDragStop.add(function(sprite, pointer) {
		camera_start.x = camera.x;
		camera_start.y = camera.y;
	}, this);

    grid_tiles.events.onDragUpdate.add(function(sprite, pointer, x, y) {
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
		
	}, this);

	pGraphics.destroy();
}

function setGridSize(width, height) {
	grid_settings.width = width;
	grid_settings.height = height;
	grid_tiles.remove();
	createGrid();
}