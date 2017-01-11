/*
 * state0 state code
 *
 */

var SHOW_CROSSHAIR = false;
var TRAIL_LENGTH = 60;
var TIP_SIZE = 3;

function rgbToHex(color) {
	return parseInt('0x'+color.r.toString(16)+color.g.toString(16)+color.b.toString(16), 16);
}


var a = 10,
    b = 28,
    c = 8/3;

var x = 0.01,
    y = 0,
    z = 0;

var c  = 0;

var colors, color;
var points = [];

var state0 = {
	preload: function() {

	},

	create: function() {
        this.game.stage.backgroundColor = "#FFFFFF";
        
		colors = Phaser.Color.HSVColorWheel();
        this.game.scale.setGameSize(800, 600);
        
		this.graphics = this.game.add.graphics(0, 0);
        this.gfx_points = this.game.add.graphics(400, 300);
        this.gfx_history = this.game.add.graphics(400, 300);
        //this.graphics.scale.setTo(0.8, 0.8);
	},
	
    update: function() {
        this.graphics.clear();
        this.gfx_points.clear();
        this.gfx_history.clear();
        
		var dt = 0.01;
        var dx = (a * (y - x)) * dt;
        var dy = (x * (b - z) - y) * dt;
        var dz = ((x * y) - (c * z)) * dt;
        
        x += dx;
        y += dy;
        z += dz;
        
        this.game.debug.text("x: " + x, 20, 20);
        this.game.debug.text("y: " + y, 20, 32);
        this.game.debug.text("z: " + z, 20, 44);
        
        points.push({x: x,y: y,z: z});
       	
        // get color of dot/line
        c += 1;
        if (c > colors.length)
            c = 0; 
        if (colors[c])
            color = colors[c].color;
        
        // crosshair
        var x_offset = 400;
        var y_offset = 300;
        
        if (SHOW_CROSSHAIR) {
            this.graphics.lineStyle(2, color, 1);
            this.graphics.moveTo(0, 0);
            this.graphics.lineTo(x + x_offset, y + y_offset);

            this.graphics.moveTo(this.game.width, 0);
            this.graphics.lineTo(x + x_offset, y + y_offset);

            this.graphics.moveTo(0, this.game.height);
            this.graphics.lineTo(x + x_offset, y + y_offset);

            this.graphics.moveTo(this.game.width, this.game.height);
            this.graphics.lineTo(x + x_offset, y + y_offset);
        }
        
        // draw trail 'history'
        for (var p2 = 0; p2 < points.length; p2++) {
        	point = points[p2];
            
            var opacity = 1;
            if (p2 > points.length - TRAIL_LENGTH) {
                var op_part = p2 - (points.length - TRAIL_LENGTH);
                opacity = (TRAIL_LENGTH - op_part) / TRAIL_LENGTH;
            }
            
            this.gfx_history.lineStyle(2, '#000000', opacity);
            this.gfx_history.moveTo(point.x, point.y);

            if (p2 + 1 < points.length) {
                point = points[p2 + 1];
                this.gfx_history.lineTo(point.x, point.y);
            }
        }

       	// draw color trail
       	var point;
        var trail_length = TRAIL_LENGTH;
        for (var p = 0; p < trail_length; p++) {
           	if (p < points.length && p > 0) {
                point = points[points.length - p];
                
                this.gfx_points.lineStyle(((trail_length - p) / trail_length) * TIP_SIZE, color, (trail_length - p) / trail_length);
                this.gfx_points.moveTo(point.x, point.y);
                
                if (points.length - p + 1 < points.length) {
                    point = points[points.length - p + 1];
                 	this.gfx_points.lineTo(point.x, point.y);
                }
            }
        }
        

    }
};