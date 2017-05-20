exports.init = function(options) {
	var new_map = new b_map(options);
	return new_map;
}

exports.settings = [
	{"type" : "number", "name" : "grid w", "default" : 14, "min" : 1, "max" : window.screen.availWidth},
	{"type" : "number", "name" : "grid w", "default" : 14, "min" : 1, "max" : window.screen.availHeight}
]

var b_map = function(options) {
	var _this = this;

	this.sel_id = options.id;
	this.konva = require('./konva.min.js');
	this.width = window.screen.availWidth;
	this.height = window.screen.availHeight;
	this.camera = {'x':0, 'y':0};
	this.bold_line_count = 10;

	this.text_layer = new this.konva.Layer();
	this.grid_layer = new this.konva.Layer();
	this.grid_group = new this.konva.Group();
	this.origin_group = new this.konva.Group();

	this.createGrid = function(width, height) {
		this.grid_group.destroy();
		this.grid_group = new this.konva.Group();

		// vertical lines
		for (var w = -(width*this.bold_line_count); w < this.width + ((width*this.bold_line_count)*2); w+=width) {
			var color = "#3D3D3D";
			if ((w) % (width*this.bold_line_count) == 0)
				color = "#757575";

			var new_line = 
				new Konva.Line({
					points: [w, 0, w, this.height],
					stroke: color,
					strokeWidth: 1
			    });
			new_line._orientation = "_vertical";
			new_line._w = (width*this.bold_line_count);
			new_line._h = (height*this.bold_line_count);
		   	this.grid_group.add(new_line);
		}
		
		// horizontal lines
		for (var h = -(width*this.bold_line_count); h < this.height + ((height*this.bold_line_count)*2); h+=height) {
			var color = "#3D3D3D";
			if ((h) % (height*this.bold_line_count) == 0)
				color = "#757575";

			var new_line = 
				new Konva.Line({
					points: [0, h, this.width, h],
					stroke: color,
					strokeWidth: 1
			    });
			new_line._orientation = "_horizontal";
			new_line._w = (width*this.bold_line_count);
			new_line._h = (height*this.bold_line_count);
		    this.grid_group.add(new_line);
		}
		this.grid_layer.add(this.grid_group);
        this.grid_group.draw();
	}

	this.stage = new this.konva.Stage({
		container: _this.sel_id,
		width: window.screen.availWidth,
		height: window.screen.availHeight,
		draggable: true
	});

	this.stage.on('dragmove', function(e){
		_this.camera.x = -_this.stage.getAttr('x');
		_this.camera.y = -_this.stage.getAttr('y');

		_this.grid_group.getChildren().each(function(line){
			var pos = line.getAbsolutePosition();
			var size = [_this.stage.getWidth(), _this.stage.getHeight()];
			var new_x = -_this.camera.x % line._w;
			var new_y = -_this.camera.y % line._h;

			if (line._orientation === "_vertical") {
				line.setAbsolutePosition({
					'x': new_x,
					'y': 0
				});
				line._x = new_x;
			}
			else if (line._orientation === "_horizontal") {
				line.setAbsolutePosition({
					'x': 0,
					'y': new_y
				});
				line._y = new_y;
			}
		});
	});

	// add mouse coordinate text
	this.txt_coords = new this.konva.Text({
		x: 0,
		y: 0,
		text: '0, 0',
		fontSize: 12,
		fontFamily: 'Calibri',
		fill: '#E0E0E0',
		align: 'right'
    });
    this.text_layer.add(this.txt_coords);

    this.stage.on('contentMousemove', function(e){
    	var pos = _this.stage.getPointerPosition();
    	pos.x += _this.camera.x;
    	pos.y += _this.camera.y;

    	_this.txt_coords.position({
    		x: pos.x,
    		y: pos.y
    	});
    	_this.txt_coords.text(pos.x + ', ' + pos.y);
    	_this.text_layer.draw();
    });

	this.stage.add(this.grid_layer);
    this.stage.add(this.text_layer);
	this.createGrid(32, 32);
}
