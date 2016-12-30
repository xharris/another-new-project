/*
 * StatePlay state code
 *
 */

var group_penguin;
var player;

var group_layerground;
var map_ground,
    layer_ground;
var levels = {};

var cursors;

var kill_wall;

var address = "http://localhost:8080/";

var promises = [];


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
        group_layerground = game.add.group();

		player = new Player();

        // parse information about levels
        $.getJSON(address+"assets/levels.json", function(data){
            levels.list = data.levels;
            levels.data = {};

            for (var i = 0; i < levels.list.length; i++) {
                (function(levels, i){ 
                    promises.push(
                        $.getJSON(address+"assets/levels/"+levels.list[i]+".json", function(data){
                            levels.data[levels.list[i]] = data;
                        }).fail(function(){
                            console.log('error loading level '+levels.list[i]);
                        })
                    );
                })(levels, i);
            }
            $.when.apply($, promises).then(function() {
                load_level("starter");
                load_random_level();
                load_random_level();
                load_random_level();
            }, function() {
                // error occurred
            });
/*

            */
        }).fail(function(){
            console.log('error loading level list');
        });
        

        // setup fragging wall
        kill_wall = {
            x: 0,
            speed: 1,
            line: new Phaser.Line(0,game.world.top,0,game.world.bottom),

            update: function(){
                if (layer_ground) {
                    this.x += this.speed;
                    this.line.setTo(this.x, game.world.top, this.x, game.world.bottom);
                    var tile_hits = layer_ground.getRayCastTiles(this.line, 4, false, false);

                    for (var i = 0; i < tile_hits.length; i++) {
                        LevelBlock.killBlock(tile_hits[i]);
                    }
                }
            }
        }
	},

	update: function() {
        player.update();

        kill_wall.update()
    },

    render: function() {
        //game.debug.geom(game.world.bounds);
        game.debug.geom(kill_wall.line);
    }
};

function load_level (name) {
    console.log('loading ' +name)
    new LevelBlock(name, levels.data[name]);
}

function load_random_level () {
    load_level(levels.list[game.rnd.integerInRange(0, levels.list.length-1)]);
}

function collisionCallback() {
    console.log(arguments);
    return false;
}