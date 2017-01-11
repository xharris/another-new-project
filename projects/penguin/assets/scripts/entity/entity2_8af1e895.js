/*
 * Player entity class
 *
 */

function Player() {
	this.penguin = new Penguin(50,0);

  	this.vx = 120;
  	this.vy = 300;
  	this.gravity = {
  		x: 0,
  		y: 550
  	}

  	//this.penguin.camFollow();

  	game.physics.arcade.enable(this.penguin.spr_main);
	  this.penguin.spr_main.body.setCircle(12);
    this.penguin.spr_main.body.collideWorldBounds = false;
    this.penguin.spr_main.body.gravity.y = this.gravity.y;
	  this.penguin.spr_main.body.offset.setTo(-12,8);
}

Player.prototype.update = function() {
    game.physics.arcade.overlap(this.penguin.spr_main, group_layerground, this.collisionHandler, null);

  	// left/right movement
  	this.penguin.spr_main.body.velocity.x = 0;
  	if (cursors.left.isDown && !cursors.right.isDown && !this.penguin.spr_main.body.onWall()) {
     	this.penguin.spr_main.body.velocity.x = -this.vx;
  	  this.penguin.faceLeft();
    }
  	if (cursors.right.isDown && !cursors.left.isDown && !this.penguin.spr_main.body.onWall()) {
  	this.penguin.spr_main.body.velocity.x = this.vx;
  	  this.penguin.faceRight();
    }

  	// jumping
  	if (cursors.up.isDown && this.penguin.spr_main.body.onFloor()){
  	this.penguin.spr_main.body.velocity.y = -this.vy;
    }

    if (!this.penguin.spr_main.body.onFloor()) {
    	this.penguin.animationFall();
    } else if ((cursors.left.isDown || cursors.right.isDown) && this.penguin.spr_main.body.deltaAbsX()) {
  		this.penguin.animationWalk();
    } else {
    	this.penguin.animationStand();
    }
}

Player.prototype.collisionHandler = function(player, layer) {
    game.physics.arcade.collide(player, layer);
}