/*
 * state0 state code
 *
 */


var a = 10,
    b = 8/3,
    c = 28;

var x = 0.01,
    y = 0,
    z = 0;
var dx = 0,
    dy = 0,
    dz = 0;
var dt = 0.01;
var c  = 0;

var colors;

var state0 = {
	preload: function() {

	},

	create: function() {
		colors = Phaser.Color.HSVColorWheel();
        console.log(colors);
        this.game.scale.setGameSize(800, 600);
        
		this.graphics = this.game.add.graphics(400,300);
	},
	
    update: function() {
        dx = a * (y - x);
        dy = x * (c - z) - y;
        dz = x * y - b * z;
        
        x += dx * dt;
        y += dy * dt;
        z += dz * dt;
        
        c += 1;
        if (c > colors.length)
            c = 0;
        
        if (colors[c]) {
            this.graphics.beginFill('rgba(0,150,255,1)', 1);
            this.graphics.drawCircle(x, y, 5);
        }
    }
};