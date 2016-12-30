/*
 * LevelBlock entity class
 *
 */

function LevelBlock(level_name) {
	var _this = this;

	this.map_ground = game.add.tilemap();
	this.map_ground.addTilesetImage('img_grnd_normal');
    this.map_ground.setCollisionByExclusion([]);

    $.getJSON("http://localhost:8080/assets/levels/"+level_name+".json", function(data) {
    	_this.loadData(data);

	    


    }).fail(function(){
        console.log('error');
    });
}

LevelBlock.prototype.loadData = function(data) {  
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

    layer_ground = map_ground.create('ground', 50, 50, 32, 32);
    layer_ground.resizeWorld(); 

    group_levelblock.add(layer_ground);
}