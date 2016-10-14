var sel_uuid, sel_prop;

var grid_settings = {
	'height': 32,
	'width': 32
}
var grid_tiles;
var camera = {x: 0, y: 0};

var cursors;
var pGraphics;

exports.loaded = function() {

}

exports.libraryAdd = function(uuid, name) {
	return {
		map: ''
	}
}

exports.onDblClick = function(uuid, properties) {
	b_canvas.init();

	sel_uuid = uuid;
	sel_prop = properties;

	// loadScene(sel_prop.map);
}

document.addEventListener("canvas.preload", function() {
	var game = b_canvas.pGame;

	
});

document.addEventListener("canvas.create", function() {
	var game = b_canvas.pGame;

	createGrid();
	cursors = game.input.keyboard.createCursorKeys();

});

document.addEventListener("canvas.update", function() {
	var game = b_canvas.pGame;

	/*
	cursors.left

	grid_tiles.tilePosition.x = 0;
	grid_tiles.tilePosition.y = 0;
	*/
});

document.addEventListener("canvas.render", function() {
	var game = b_canvas.pGame;

});

var grid_pointer_start = {x:0, y:0};
function createGrid() {
	var game = b_canvas.pGame;

	pGraphics = game.add.graphics(0,0);

	pGraphics.lineStyle(0.5, 0x000000, 0.5);
	pGraphics.moveTo(0,0);
	pGraphics.lineTo(grid_settings.width,0);
	pGraphics.lineTo(grid_settings.width,grid_settings.height);
	pGraphics.lineTo(0,grid_settings.height);
	pGraphics.lineTo(0,0);
	
	grid_tiles = game.add.tileSprite(0, 0, game.width, game.height, pGraphics.generateTexture(1,0,-2));
	grid_tiles.inputEnabled = true;
	grid_tiles.input.enableDrag();
	grid_tiles.events.onDragStart.add(function(sprite, pointer) {
		sprite.x = 0;
		sprite.y = 0;
		grid_pointer_start.x = pointer.x;
		grid_pointer_start.y = pointer.y;
	}, this);
    grid_tiles.events.onDragUpdate.add(function(sprite, pointer) {
		sprite.x = 0;
		sprite.y = 0;
    	camera = {
    		x: pointer.x - grid_pointer_start.x,
    		y: pointer.y - grid_pointer_start.y
    	}
    	grid_tiles.tilePosition.x = camera.x;
		grid_tiles.tilePosition.y = camera.y;
    }, this);
    grid_tiles.events.onDragEnd.add(function(sprite, pointer) {
		sprite.x = 0;
		sprite.y = 0;
		grid_pointer_start.x = pointer.x;
		grid_pointer_start.y = pointer.y;
    }, this);

	pGraphics.destroy();
}