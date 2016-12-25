/*
 * st_main state code
 *
 */

var font_style = {
  	font: "20px Arial",
    fill: "#ff0044",
    align: "center"
};
var map_width;
var map_height;

var keys;

var new_player;
var camera_scale = 2;

var dirt_map, dirt_layer;
var grass_layer, grass_map;

var st_main = {
	preload: function() {
        _load_assets();
	},

	create: function() {
        keys = game.input.keyboard.createCursorKeys();
        game.stage.backgroundColor = "#673AB7";//"#b3e5fc";
        game.physics.startSystem(Phaser.Physics.ARCADE);
        
        map_width = 900;
        map_height = 900;
        
        var tile_map_width = Math.ceil(map_width / 32);
        var tile_map_height = Math.ceil(map_height / 32);
        
		// create layer of normal dirt
        dirt_map = game.add.tilemap();
        dirt_map.addTilesetImage("img_dirt");
        
        dirt_layer = dirt_map.create("main_dirt", tile_map_width, tile_map_height, 32, 32); 
        dirt_layer.resizeWorld(); 
        
        grass_map = game.add.tilemap();
        grass_map.addTilesetImage("img_grass");
        
        grass_layer = grass_map.create("main_grass", Math.ceil(map_width / 4), 3, 4, 32);
        
       	// place random dirt
        for (var x = 0; x < tile_map_width; x++) {            
         	for (var y = 3; y < tile_map_height; y++) {
             	dirt_map.putTile(Math.floor(Math.random() * 3), x, y, dirt_layer);
            }
        }
        
        // place random grass
        for (var g = 0; g < Math.ceil(map_width / 4); g++) {
            grass_map.putTile(Math.floor(Math.random() * 2), g, 2, grass_layer);
        }
                                 
        dirt_map.setCollisionBetween(0,2);
        dirt_map.setTileIndexCallback([0,1,2], hitDirt, this);
        
        new_player = new Player();
        new_player.setPosition(0, 0);
        
       	cam_follow(new_player);

    },
    
    update: function() {
        game.physics.arcade.collide(new_player.char_sprite, dirt_layer);
        
		new_player.handleKeys(keys);
        new_player.update();
    },
    
    render: function() {
     	new_player.render();  
        game.debug.body(dirt_map);
    }
};

function cam_follow (player) { 
	st_main.camera.follow(player.char_sprite);
	game.world.scale.set(camera_scale);
    player.setCameraScale(camera_scale);
}

function hitDirt(sprite, tile) {
    // yes the return numbers are switched
    dirt_map.replace(tile.index, 3, tile.x, tile.y, 1, 1, dirt_layer);
}