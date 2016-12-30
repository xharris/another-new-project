/*
 * LevelBlock entity class
 *
 */

var last_block_added;
var map_ground;
var layer_ground;
var total_width = 0;
var total_height = 0;

var offset = {x:0,y:0};

function LevelBlock(level_name, data) {
	var _this = this;

	this.start = {x:0, y:0};
	this.end = {x:0, y:0};

	if (!total_width) 
		total_width = game.world.width/32;
	if (!total_height) 
		total_height = 0;//game.world.height / 32;

	if (!map_ground) {
		map_ground = game.add.tilemap();
		map_ground.addTilesetImage('img_grnd_normal');
	    map_ground.setCollisionByExclusion([]);
	}
	    
	this.loadData(data)
}

LevelBlock.prototype.loadData = function(data) {  
	var map = data.map;
	this.start = data.start;
	this.end = data.end;

	total_width += map[0].length;
	total_height += map.length;

	if (total_width < game.width/32)
		total_width = game.width/32;
	if (total_height < game.height/32)
		total_height = game.height/32;

	if (!layer_ground) {
	    layer_ground = map_ground.create('ground', total_width, total_height, 32, 32);
	    game.physics.arcade.enable(layer_ground);
   		group_layerground.add(layer_ground);
	}

	//game.world.setBounds(0, -(total_height*32), (total_width*32), game.world.height + (total_height*32));

    for (var r = 0; r < map.length; r++) {
        for (var c = 0; c < map[r].length; c++) {
            var tile_type = map[r][c];     

           	switch (tile_type) {
                // normal ground
                case 1:
                    var index = 0;
                    // figure out other tile stuff later...

                   	map_ground.putTile(index, c + offset.x, r + offset.y, layer_ground);
                break;
            }
        }
    }

	// align the next level with the loaded level
	if (this.end.x > this.start.x) 
		offset.x += this.end.x - this.start.x;
	else 
		offset.x -= this.end.x - this.start.x;

	if (this.end.y > this.start.y)
		offset.y += this.end.y - this.start.y;
	else
		offset.y -= this.end.y - this.start.y;

	console.log('new offset');
	console.log(offset);

    last_block_added = this;
}

LevelBlock.killBlock = function(tile) {
	map_ground.removeTile(tile.x, tile.y);
}