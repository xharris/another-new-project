/*
 * StatePlay state code
 *
 */

var group_penguin;
var player;

var group_levelblock;

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
        group_levelblock = game.add.group();

		player = new Player();
        
        load_level("starter");
	},

	update: function() {
        //group_penguin.forEach(function(peng){peng.parent_inst.update();});
        player.update();
    }
};

function load_level (name) {
    new LevelBlock(name);
}