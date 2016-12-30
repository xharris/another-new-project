/*
 * StatePlay state code
 *
 */

var group_penguin;
var player;

var map_ground,
    layer_ground;

var cursors;

var StatePlay = {
	preload: function() {
		_load_assets();
	},

	create: function() {
        // setup some general things
        game.stage.backgroundColor = "#e0f7fa";
        cursors = game.input.keyboard.createCursorKeys();
        game.physics.startSystem(Phaser.Physics.ARCADE);
        
        group_penguin = game.add.group();
        map_ground = game.add.tilemap();
        map_ground.addTilesetImage('img_grnd_normal');
        map_ground.setCollisionByExclusion([]);
        layer_ground = map_ground.create('ground', 50, 50, 32, 32);
        layer_ground.resizeWorld(); 
      
		player = new Player();
        
        load_level("starter");
	},

	update: function() {
        //group_penguin.forEach(function(peng){peng.parent_inst.update();});
        player.update();
    }
};
function load_level (name) {
    $.getJSON("http://localhost:8080/assets/levels/"+name+".json", function(data) {
        var map = data.map;
        
        for (var r = 0; r < map.length; r++) {
            for (var c = 0; c < map[r].length; c++) {
                var tile_type = map[r][c];
                
               	switch (tile_type) {
                    // normal ground
                    case 1:
                        var index = 0;
                        // figure out other tile stuff later...
                       	map_ground.putTile(index, c, r, 'ground');
                    break;
                }
            }
        }
    }).fail(function(){
        console.log('error');
    });
}