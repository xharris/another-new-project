/*
 * Penguin entity class
 *
 */


function Penguin(x=0, y=0) {
	this.x = x;
  	this.y = y;
  
    this.ani_frame = 0;
  	this.ani_walk_speed = 15;
  
  	this.spr_main = game.add.sprite(this.x, this.y, 'spr_penguin');
  	this.spr_fill = game.add.sprite(this.x, this.y, 'spr_penguin_fill');
  
  	this.spr_main.animations.add('walk');
  	this.spr_main.play('walk', 15, true);
  	this.spr_main.parent_inst = this;
  
  	group_penguin.add(this.spr_main);
  
  	this.spr_fill.animations.add('walk');
  	this.spr_fill.play('walk', 15, true);
  	this.spr_fill.tint = Math.random() * 0xffffff;
  
  	// keeping main and fill sprite together
  	this.spr_main.addChild(this.spr_fill);
  	this.spr_main.anchor.setTo(.5,.5);
  	this.spr_fill.anchor.setTo(.5,.5);
}

Penguin.prototype.camFollow = function() {
  	//game.camera.scale.setTo(2);
 	game.camera.follow(this.spr_main); 
}

Penguin.prototype.faceLeft = function() {
    this.spr_main.scale.x = -1;
}

Penguin.prototype.faceRight = function() {
    this.spr_main.scale.x = 1;
}

Penguin.prototype.animationWalk = function() {
    this.spr_main.play('walk', this.ani_walk_speed, true);
    this.spr_fill.play('walk', this.ani_walk_speed, true);
}

Penguin.prototype.animationStand = function() {
    this.spr_main.animations.frame = 0; 
    this.spr_fill.animations.frame = 0; 
    this.spr_main.animations.stop(); 
    this.spr_fill.animations.stop();
}

Penguin.prototype.animationFall = function() {
    this.spr_main.animations.frame = 1; 
    this.spr_fill.animations.frame = 1; 
    this.spr_main.animations.stop(); 
    this.spr_fill.animations.stop();
}