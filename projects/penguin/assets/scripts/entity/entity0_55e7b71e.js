/*
 * Penguin entity class
 *
 */


function Penguin(x=0, y=0) {
	  this.x = x;
  	this.y = y;
  
    this.ani_frame = 0;
  	this.ani_walk_speed = 15;
  
  	this.spr_main = game.add.sprite(this.x, this.y, '');
    this.spr_outline = game.add.sprite(0, 0, 'spr_penguin');
  	this.spr_fill = game.add.sprite(0, 0, 'spr_penguin_fill');
  
  	this.spr_outline.animations.add('walk');
  	this.spr_outline.play('walk', 15, true);
  	this.spr_outline.parent_inst = this;
  
  	group_penguin.add(this.spr_main);
  
  	this.spr_fill.animations.add('walk');
  	this.spr_fill.play('walk', 15, true);
  	this.spr_fill.tint = Math.random() * 0xffffff;
  
  	// keeping outline and fill sprite together
    this.spr_main.addChild(this.spr_fill);
    this.spr_main.addChild(this.spr_outline);

    this.spr_outline.anchor.setTo(.5, 0);
  	this.spr_fill.anchor.setTo(.5,0);

    this.spr_outline.smoothed = false;
    this.spr_fill.smoothed = false;
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
    this.spr_outline.play('walk', this.ani_walk_speed, true);
    this.spr_fill.play('walk', this.ani_walk_speed, true);
}

Penguin.prototype.animationStand = function() {
    this.spr_outline.animations.frame = 0; 
    this.spr_fill.animations.frame = 0; 
    this.spr_outline.animations.stop(); 
    this.spr_fill.animations.stop();
}

Penguin.prototype.animationFall = function() {
    this.spr_outline.animations.frame = 1; 
    this.spr_fill.animations.frame = 1; 
    this.spr_outline.animations.stop(); 
    this.spr_fill.animations.stop();
}