/*
 * Player entity class
 *
 */

function Player() {
	this.penguin = new Penguin();

  	this.vx = 100;
  	this.vy = 250;
  	this.gravity = {
  		x: 0,
  		y: 500
  	}

  	this.penguin.camFollow();

  	game.physics.arcade.enable(this.penguin.spr_main);
	this.penguin.spr_main.body.setCircle(14);
    this.penguin.spr_main.body.collideWorldBounds = true;
    this.penguin.spr_main.body.gravity.y = this.gravity.y;
	this.penguin.spr_main.body.offset.setTo(2.5,4);
}

Player.prototype.update = function() {
	game.physics.arcade.collide(this.penguin.spr_main, layer_ground);

	// left/right movement
  	this.penguin.spr_main.body.velocity.x = 0;
  	if (cursors.left.isDown && !this.penguin.spr_main.body.onWall()) {
     	this.penguin.spr_main.body.velocity.x = -this.vx;
		this.penguin.faceLeft();
    }
  	if (cursors.right.isDown && !this.penguin.spr_main.body.onWall()) {
		this.penguin.spr_main.body.velocity.x = this.vx;
		this.penguin.faceRight();
    }
  
  	// jumping
  	if (cursors.up.isDown && this.penguin.spr_main.body.onFloor()){
		this.penguin.spr_main.body.velocity.y = -this.vy;
    }

    if (!this.penguin.spr_main.body.onFloor()) {
    	this.penguin.animationFall();
    } else if (cursors.left.isDown || cursors.right.isDown) {
  		this.penguin.animationWalk();
    } else {
    	this.penguin.animationStand();
    }


}