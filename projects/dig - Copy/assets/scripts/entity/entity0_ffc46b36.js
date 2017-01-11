/*
 * entity0 entity class
 *
 */

var GRID_SIZE = 32;

function Player() {
	this.x = 0;
  	this.y = 0;
  	this.v = 1;
  	this.angle = 0;
  	this.xscale = 1;
  	this.yscale = 1;
  
  	this.body = {
		x: 8,
      	y: 4,
      	w: 15,
      	h: 23
    }
  
  	this.char_sprite = game.add.sprite(this.x, this.y, "img_player");
  	this.char_sprite.smoothed = true;
  
  	game.physics.enable(this.char_sprite);
  
  	this.char_sprite.body.setSize(this.body.w, this.body.h, this.body.x, this.body.y);
  
  	this.last_x_dir = 0;
  	this.last_y_dir = 0;
  
  	this.last_walk_dir = 'r';
  
  	this.camera_scale = 1;
  	this.grid_size = (GRID_SIZE / this.camera_scale);
}

Player.prototype.setPosition = function(x, y) {
  	this.char_sprite.anchor.setTo(0.5);

  	this.x = x - (x % this.grid_size);
  	this.y = y - (y % this.grid_size);
}

Player.prototype.setCameraScale = function(new_scale) {/*
 	this.camera_scale = new_scale;
  	this.char_sprite.body.setSize(
        this.body.w / new_scale, 
        this.body.h / new_scale, 
        this.body.x / new_scale, 
        this.body.y / new_scale
    ); */
}

Player.prototype.update = function() {
  	this.grid_size = (GRID_SIZE / this.camera_scale);
  
  	//this.char_sprite.angle = this.angle;
  	this.bo
  
  	this.char_sprite.body.rotation = this.angle;
}

Player.prototype.render = function() {
	this.char_sprite.x = (this.x + (this.grid_size / 2)) * this.camera_scale;
  	this.char_sprite.y = (this.y + (this.grid_size / 2)) * this.camera_scale;
  
  	this.char_sprite.scale.x = this.xscale;
  	this.char_sprite.scale.y = this.yscale;
  
	game.debug.body(this.char_sprite);
}

Player.prototype.handleKeys = function(keys) {
  	var x_mod = this.x % this.grid_size / this.camera_scale;
  	var y_mod = this.y % this.grid_size / this.camera_scale;
  
  	var x_min = Math.floor(this.x / this.grid_size) * this.grid_size,
        x_max = Math.ceil(this.x / this.grid_size) * this.grid_size,                                         
        y_min = Math.floor(this.y / this.grid_size) * this.grid_size,
        y_max = Math.ceil(this.y / this.grid_size) * this.grid_size;
  
  	game.debug.text("x: " + this.x + ", xmod: " + x_mod, 20, 20);
  	game.debug.text("y: " + this.y + ", ymod: " + y_mod, 20, 32);
  
  	if (keys.left.isDown || keys.right.isDown) {
      	// decimal velocity case
      	if (this.v % 1 != 0 && y_mod <= (this.v) && y_mod > 0) {
			this.y = (Math.abs(y_min - this.y) < Math.abs(y_max - this.y) ? y_min : y_max);
        }
      	y_mod = this.y % this.grid_size;
      
		if (y_mod == 0) {
          	if (keys.left.isDown) {
            	this.x -= this.v; 
              	this.last_x_dir = -1;
              	this.last_walk_dir = 'l';
              	
                this.xscale = -1;
                this.angle = 0;
         	}
          	if (keys.right.isDown) {
            	this.x += this.v; 
              	this.last_x_dir = 1;
              	this.last_walk_dir = 'r';
              
                this.xscale = 1;
                this.angle = 0;
          	}
          	
          	this.angle = 0;
          
      	} else {
        	// y is not within grid constraints, move to closest row
          	
          	// code that auto detects direction to move in
        	// var direction = (Math.abs(this.y - y_min) < Math.abs(this.y - y_max)) ? -1 : 1;
          
            this.y += this.v * this.last_y_dir;
      	}     

    } else
    if (keys.up.isDown || keys.down.isDown) {
      	// decimal velocity case
      	if (this.v % 1 != 0 && x_mod <= (this.v) && x_mod > 0) {
			this.x = (Math.abs(x_min - this.x) < Math.abs(x_max - this.x) ? x_min : x_max);
        }
      	x_mod = this.x % this.grid_size;
      
     	if (x_mod == 0) {
            if (keys.up.isDown) {
                this.y -= this.v; 
              	this.last_y_dir = -1;
              
              	// rotated animation
              	switch (this.last_walk_dir) {
                	case 'l':
                    	this.xscale = -1;
                        this.angle = 90;
                  		break;
                  	case 'r':
                    	this.xscale = 1;
                        this.angle = -90;
                    	break;
                  	case 'd':
                    	this.xscale *= -1;
                    	break;
                }
              
              	this.last_walk_dir = 'u';
            }
            if (keys.down.isDown) {
                this.y += this.v; 
              	this.last_y_dir = 1;
              
              	// rotated animation
              	switch (this.last_walk_dir) {
                	case 'l':
                    	this.xscale = -1;
                        this.angle = -90;
                  		break;
                  	case 'r':
                    	this.xscale = 1;
                        this.angle = 90;
                    	break;
                  	case 'u':
                    	this.xscale *= -1;
                    	break;
                }
              
              	this.last_walk_dir = 'd';
            }
          	
          	
        } else {
        	// x is not within grid constraints, move to closest row
        	//var direction = (Math.abs(this.x - x_min) < Math.abs(this.x - x_max)) ? -1 : 1;
            this.x += this.v * this.last_x_dir;      
        }

    }
}