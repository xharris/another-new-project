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

	// grid
	this.grid_width = 32;
	this.grid_height = 32;
	this.bold_line_count = 10;

	this.camera = {'x':0, 'y':0};

	this.text_layer = new this.konva.Layer();
	this.grid_layer = new this.konva.Layer();
	this.placer_layer = new this.konva.Layer();
	this.obj_layer = new this.konva.Layer();
	this.grid_group = new this.konva.Group();

	this.curr_place_type = '';
	this.capture_rect = new this.konva.Rect({
		x: 0, y: 0,
		width: _this.width, height: _this.height,
		fill: 'white',
		opacity: 0
	});
	this.obj_layer.add(this.capture_rect);
	this.obj_layer.draw();
	this.placer_img = new this.konva.Image();

	this.createGrid = function(width, height) {
		this.grid_width = width;
		this.grid_height = height;

		this.grid_group.destroy();
		this.grid_group = new this.konva.Group();

		// vertical lines
		var grid_color = "#9E9E9E";
		var grid_bold_color = "#757575";
		for (var w = -(width*this.bold_line_count); w < this.width + ((width*this.bold_line_count)*2); w+=width) {
			var opacity = 0.25;
			if ((w) % (width*this.bold_line_count) == 0)
				opacity = 1;

			var new_line = 
				new Konva.Line({
					points: [w, 0, w, this.height],
					stroke: grid_color,
					strokeWidth: 1,
					opacity: opacity
			    });
			new_line._orientation = "_vertical";
			new_line._w = (width*this.bold_line_count);
			new_line._h = (height*this.bold_line_count);
		   	this.grid_group.add(new_line);
		}
		
		// horizontal lines
		for (var h = -(width*this.bold_line_count); h < this.height + ((height*this.bold_line_count)*2); h+=height) {
			var opacity = 0.25;
			if ((h) % (height*this.bold_line_count) == 0)
				opacity = 1;

			var new_line = 
				new Konva.Line({
					points: [0, h, this.width, h],
					stroke: grid_color,
					strokeWidth: 1,
					opacity: opacity
			    });
			new_line._orientation = "_horizontal";
			new_line._w = (width*this.bold_line_count);
			new_line._h = (height*this.bold_line_count);
		    this.grid_group.add(new_line);
		}
		this.grid_layer.add(this.grid_group);
        this.grid_group.draw();
	}

	this.setPlacer = function(type, options) {
		this.curr_place_type = type;

		if (type === "image") {
			var path = options.path;
			var crop = options.crop;

			// create placer image object
			var placer_img_obj = new Image();
			placer_img_obj.onload = function(){
				if (_this.placer_img)
					_this.placer_img.destroy();
				_this.placer_img = new _this.konva.Image({
					x: 0,
					y: 0,
					image: placer_img_obj,
					width: crop.width,
					height: crop.height,
					crop: crop,
					opacity: 0.5
				});
				_this.placer_layer.add(_this.placer_img);
			};
			placer_img_obj.src = path;
		}
	}

	this.clearPlacer = function(type) {
		if (type === '' || type === this.curr_place_type) {
			// image
			this.placer_img.destroy();
		}
	}

	this.getMouseXY = function(x, y) {
    	var pos = this.stage.getPointerPosition();
    	
    	var mx = pos.x + _this.camera.x;
    	var my = pos.y + _this.camera.y;
    	var signx = Math.sign(mx);
    	var signy = Math.sign(my);

    	mx = Math.abs(mx);
    	my = Math.abs(my);

    	// snap to grid
    	mx -= mx % this.grid_width;
    	my -= my % this.grid_height;

    	mx *= signx;
    	my *= signy;

    	return {x:mx, y:my};
	}

	this.stage = new this.konva.Stage({
		container: _this.sel_id,
		width: window.screen.availWidth,
		height: window.screen.availHeight,
		draggable: true
	});

	this.txt_label = new Konva.Label({
        x: 0,
        y: 0
    });
    this.txt_label.add(new Konva.Tag({
        fill: 'black',
        opacity: 0.5
    }));
	// add mouse coordinate text
	this.txt_coords = new this.konva.Text({
		x: 0,
		y: 0,
		text: '0, 0',
		fontSize: 10,
		fontFamily: 'Calibri',
		fill: '#E0E0E0',
		padding: 1,
		align: 'right',
		wrap: 'none'
    });
    this.txt_label.add(this.txt_coords);
    this.text_layer.add(this.txt_label);

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

		_this.capture_rect.x(_this.camera.x);
		_this.capture_rect.y(_this.camera.y);
	});

    this.stage.on('contentMousedown', function(e){
    	_this.stage.draggable(e.evt.which == 2);
    });

    this.stage.on('contentMouseup', function(e){
    	_this.stage.draggable(false);
    });

    var placing = false;
    var destroying = false;
    this.obj_layer.on('mousedown', function(e) {
    	placing = (e.evt.which == 1);
		destroying = (e.evt.which == 3)
    });

    this.obj_layer.on('mouseup mousemove', function(e){
    	if (e.type === 'mouseup') {
    		if (e.evt.which == 1) {
	    		placing = false;
    		}
    		if (e.evt.which == 3) {
    			destroying = false;
    		}
    	}

	   	// place object
    	if ((e.evt.which == 1) && (e.type === 'mouseup' || (e.type === 'mousemove' && placing))) {
	    	var pos = _this.getMouseXY();
	    	var mx = pos.x;
	    	var my = pos.y;

	    	var new_obj;
	    	var init_scale = 1.5;
	    	if (_this.curr_place_type === "image") {
	    		new_obj = _this.placer_img.clone({
	    			x: mx + _this.placer_img.width()/init_scale,
	    			y: my + _this.placer_img.height()/init_scale,
	    			scaleX: init_scale,
	    			scaleY: init_scale,
	    			offsetX: _this.placer_img.width()/init_scale,
	    			offsetY: _this.placer_img.height()/init_scale
	    		});

	    		// prevent placing tiles right on top of each other
	    		new_obj.on('mouseup mousemove', function(e){
					if (e.type === 'mouseup' && e.evt.which == 3)
						destroying = false;

	    			if (_this.curr_place_type === "image") {
	    				// actually, user is deleting this object
	    				if (e.evt.which == 3 && (e.type === 'mouseup' || (e.type === 'mousemove' && destroying))) {
	    					if (e.target.className === "Image") {
	    						e.target.destroy();
	    						_this.obj_layer.batchDraw();
	    					}
	    				} else
	    					e.cancelBubble = true;
	    			}
	    		});

    			_this.obj_layer.add(new_obj);

	    		// cool shrinking animation (a little misaligned)
	    		var tween = new Konva.Tween({
			        node: new_obj,
			        duration: 0.2,
			        easing: _this.konva.Easings.EaseOut,
			        x: mx,
			        y: my,
			        scaleY: 1,
			        scaleX: 1,
			        offsetX: 0,
			        offsetY: 0,
			        opacity: 1
			    });
			    tween.play();

	    		_this.obj_layer.batchDraw();
	    	}
	    }


    });

    this.stage.on('contentMousemove', function(e){
    	var pos = _this.getMouseXY();
    	var mx = pos.x;
    	var my = pos.y;

    	// move mouse x/y label
    	_this.txt_label.position({
    		x: parseInt(mx - _this.txt_coords.getClientRect().width - 4),
    		y: parseInt(my + 32)
    	});
    	_this.txt_coords.text(mx + ', ' + my);
    	_this.text_layer.draw();

    	// move placer image
    	_this.placer_img.position({
    		x: mx,
    		y: my
    	});
    	_this.placer_layer.draw();
    });

	this.stage.add(this.placer_layer);
    this.stage.add(this.obj_layer);
	this.stage.add(this.grid_layer);
    this.stage.add(this.text_layer);
	this.createGrid(32, 32);

	// zoom in/out
	this.scaleBy = 1.03;
	this.newScale = 1;
	window.addEventListener('wheel', (e) => {
		if (false) {
	        e.preventDefault();
	        var oldScale = _this.stage.scaleX();
	        var mousePointTo = {
	            x: _this.stage.getPointerPosition().x / oldScale - _this.stage.x() / oldScale,
	            y: _this.stage.getPointerPosition().y / oldScale - _this.stage.y() / oldScale,
	        };
	        this.newScale = e.deltaY > 0 ? oldScale * _this.scaleBy : oldScale / _this.scaleBy;
	        _this.stage.scale({ x: this.newScale, y: this.newScale });
	        var newPos = {
	            x: -(mousePointTo.x - _this.stage.getPointerPosition().x / this.newScale) * this.newScale,
	            y: -(mousePointTo.y - _this.stage.getPointerPosition().y / this.newScale) * this.newScale
	        };
	        _this.stage.position(newPos);
	        _this.stage.batchDraw();
	    }
    });
}
