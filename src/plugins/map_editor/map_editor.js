exports.init = function(options) {
	var new_map = new b_map(options);
	return new_map;
}

exports.settings = [
	{"type" : "number", "name" : "grid w", "default" : 14, "min" : 1, "max" : window.screen.availWidth},
	{"type" : "number", "name" : "grid h", "default" : 14, "min" : 1, "max" : window.screen.availHeight}
]

var b_map = function(options) {
	var _this = this;

	this.sel_id = options.id;
	this.onLayerChange = options.onLayerChange; // when a layer is added, moved up, moved down, deleted
	this.onSave = options.onSave;
	this.saveData = ifndef(options.loadData, {});

	this.konva = require('./konva.min.js');
	this.width = window.screen.availWidth;
	this.height = window.screen.availHeight;

	// grid
	this.grid_width = 32;
	this.grid_height = 32;
	this.bold_line_count = 10;

	this.camera = {'x':0, 'y':0};
	this.curr_layer = 0;
	this.arr_layers = [];

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

	// placer: image
	this.placer_img = new this.konva.Image();

	// placer: rect
	this.placer_rect = new this.konva.Group();

	this.createGrid = function(width, height) {
		this.grid_width = width;
		this.grid_height = height;

		this.grid_group.destroy();
		this.grid_group = new this.konva.Group();

		// vertical lines
		var grid_color = "#9E9E9E";
		for (var w = -(width*this.bold_line_count); w < this.width + ((width*this.bold_line_count)*2); w+=width) {
			var opacity = 0.15;
			if ((w) % (width*this.bold_line_count) == 0)
				opacity = 0.5;

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

	this._triggerLayerChange = function() {
	    // set opacity of all layers
	    this.obj_layer.getChildren().each(function(layer){
	    	layer.opacity(0.2);
	    });

	   	// change opacity for current layer
	   	this.obj_layer.find("#layer"+this.curr_layer.toString()).opacity(1);

	    this.obj_layer.batchDraw();	
		if (this.onLayerChange) this.onLayerChange({
			map: this,
			current: this.curr_layer, 
			layers: this.arr_layers
		});

		_this._autoSave();
	}

	this.setLayer = function(num) {
		this.curr_layer = parseInt(num, 10);
		if (this.obj_layer.find("#"+this.layerNumToName(num)).length == 0) {
			var new_group = new this.konva.Group({id: this.layerNumToName(num)});
			this.obj_layer.add(new_group);
			new_group.moveToTop();
			this.arr_layers.push(num);
		}
		this._triggerLayerChange();	
	}

	this.addLayer = function() {
		var next_layer = this.curr_layer;
		while (this.arr_layers.includes(next_layer)) {
			next_layer++;
		}
		this.setLayer(next_layer);
	}

	this.getLayer = function(num) {
		var layer = ifndef(num, this.curr_layer);

		if (typeof layer === "number")
			layer = this.layerNumToName(layer)
		if (typeof layer === "object")
			return layer;

		return this.obj_layer.find("#"+layer)[0];
	}

	this.layerNameToNum = function(name) {
		try {
			return parseInt(name.toLowerCase().replace("layer", "").trim(), 10);
		} catch (e) {
			console.error("Cannot find layer '" + name + "'");
		}
	}

	this.layerNumToName = function(num) {
		return 'layer'+num.toString();
	}

	this.moveLayerUp = function(num) {
		var layer_num = ifndef(num, this.curr_layer);
		var layer = this.getLayer(num);
		if (layer) {
			// can layer be moved up further?
			var i_curr_layer = this.arr_layers.indexOf(layer_num);

			if (i_curr_layer > 0) {
				// swap positions in array
				var temp = this.arr_layers[i_curr_layer]
				this.arr_layers[i_curr_layer] = this.arr_layers[i_curr_layer-1];
				this.arr_layers[i_curr_layer-1] = temp;

				// move the layer object
				layer.moveUp();
				this._triggerLayerChange();
			}
		}
	}

	this.moveLayerDown = function(num) {
		var layer_num = ifndef(num, this.curr_layer);
		var layer = this.getLayer(num);
		if (layer) {
			// can layer be moved down further?
			var i_curr_layer = this.arr_layers.indexOf(layer_num);

			if (i_curr_layer < this.arr_layers.length - 1) {
				// swap positions in array
				var temp = this.arr_layers[i_curr_layer]
				this.arr_layers[i_curr_layer] = this.arr_layers[i_curr_layer+1];
				this.arr_layers[i_curr_layer+1] = temp;

				// move the layer object
				layer.moveDown();
				this._triggerLayerChange();
			}
		}
	}

	this.removeLayer = function(num) {
		var layer_num = ifndef(num, this.curr_layer);
		var layer = this.getLayer(layer_num);

		if (layer && this.arr_layers.length > 1) {
			layer.remove();
			
			// move to previous layer
			var new_layer_index = this.arr_layers.indexOf(layer_num) - 1;
			if (new_layer_index < 0)
				new_layer_index = 0

			// remove the layer
			this.arr_layers.splice(this.arr_layers.indexOf(layer_num), 1);

			this.setLayer(this.arr_layers[new_layer_index]);
		}
	}

	this.getLayerList = function() {
		return this.arr_layers;
	}

	this.clearPlacer = function(type='') {
		if (type === '' || type === this.curr_place_type) {
			// image
			this.placer_img.destroy();
			// rect
			this.placer_rect.destroy();
		}
	}

	// callback is called when the placer is ready to place
	this.setPlacer = function(type, options, callback) {
		this.curr_place_type = type;

		this._getPlacerObj(type, options, callback);
	}

	this._getPlacerObj = function(type, options, callback) {
		// organize saveData
		var new_placeInfo = $.extend({}, options);
		delete new_placeInfo.saveInfo;
		var saveData = {
			placeType: type,
			saveInfo: options.saveInfo,
			placeInfo: new_placeInfo
		};

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

				_this.placer_img.setAttr("_save", saveData)

				if (callback) callback(_this.placer_img.clone().setAttr("_save", saveData));
				else {
					_this.placer_layer.add(_this.placer_img);
				}
			};
			placer_img_obj.src = path;
		}

		// RECT ONLY
		if (type === "rect") {
			if (_this.placer_rect)
				_this.placer_rect.destroy();
			_this.placer_rect = new _this.konva.Group();

			// icon
			var placer_img_obj = new Image();
			placer_img_obj.onload = function(){
				if (_this.placer_rect_img)
					_this.placer_rect_img.destroy();

				// rect
				var placer_rect = new _this.konva.Rect({
					x: 0, y: 0,
					width: _this.grid_width,
					height: _this.grid_height,
					stroke: options.color,
					strokeWidth: 2
				});

				_this.placer_rect.add(placer_rect);

				_this.placer_rect_img = new _this.konva.Image({
					x: _this.grid_width/2,
					y: _this.grid_height/2,
					image: placer_img_obj,
					offsetX: placer_img_obj.width/2,
					offsetY: placer_img_obj.height/2
				});

				_this.placer_rect_img.cache();
				_this.placer_rect_img.filters([_this.konva.Filters.RGBA]);
				_this.placer_rect.add(_this.placer_rect_img);

				_this.placer_rect.setAttr("_save", saveData);

				if (callback) callback(_this.placer_rect.clone().setAttr("_save", saveData));
			};
			placer_img_obj.src = options.icon;
		}

		// polygon
		if (type === "polygon");
	}

	this.placeObj = function(type, x, y, options, layer) {
		var layer_obj = ifndef(this.getLayer(layer), this.getLayer())
		function callbackClosure(_x, _y, _type, _layer, callback) {
			return function(obj) {
				return callback(_x, _y, _type, obj, _layer);
			}
		}
		this.setPlacer(type, options, callbackClosure(x, y, type, layer_obj, this._placeObj));
	}

	this._placeObj = function(x, y, type, obj, layer) {
		layer = ifndef(layer, _this.curr_layer);
		var obj_layer = _this.getLayer(layer);

		if (type === "rect") {
			obj.x(x);
			obj.y(y);

			/*
			this.placer_rect_img.cache();
			this.placer_rect_img.filters([this.konva.Filters.RGBA]);
			*/

			// transfer serialization info
			var new_obj = obj.clone().setAttr("_save", obj.getAttr("_save"));

    		obj_layer.add(new_obj);
			_this._autoSave();
    	}

    	if (type === "image") {
	    	var new_obj;
	    	var init_scale = 1.5;

    		new_obj = obj.clone({
    			x: x + obj.width()/init_scale,
    			y: y + obj.height()/init_scale,
    			scaleX: init_scale,
    			scaleY: init_scale,
    			offsetX: obj.width()/init_scale,
    			offsetY: obj.height()/init_scale
    		});

    		// prevent placing tiles right on top of each other
    		new_obj.on('mouseup mousemove', function(e){
				if (e.type === 'mouseup' && e.evt.which == 3)
					destroying = false;

				// placer is placing on a different layer
				var group = e.target.findAncestors('Group');
				if (_this.layerNameToNum(group[0].id()) === _this.curr_layer) { 

	    			if (type === "image") {
	    				// actually, user is deleting this object
	    				if (e.evt.which == 3 && (e.type === 'mouseup' || (e.type === 'mousemove' && destroying))) {
	    					if (e.target.className === "Image") {
	    						e.target.destroy();
	    						_this.obj_layer.batchDraw();
								_this._autoSave();
	    					}
	    				} else
	    					e.cancelBubble = true;
	    			}
	    		}


    		});

    		// transfer serialization info
    		new_obj.setAttr("_save", _this.placer_img.getAttr("_save")); 
			obj_layer.add(new_obj);

    		// cool shrinking animation (a little misaligned)
    		var tween = new Konva.Tween({
		        node: new_obj,
		        duration: 0.2,
		        easing: _this.konva.Easings.EaseOut,
		        x: x,
		        y: y,
		        scaleY: 1,
		        scaleX: 1,
		        offsetX: 0,
		        offsetY: 0,
		        opacity: 1,
		        onFinish: function() {
		        	_this._autoSave();
		        }
		    });
		    tween.play();
    	}

	   	if (type != '')
			_this.obj_layer.batchDraw();
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

	this._autoSave = function() {
		save_timeout = setTimeout(this.save, PROJECT_SAVE_TIME);
	}

	this.save = function() {
		_this.saveData = {"layers":{}}; // indexes are layers

		// iterate through layers
		var layer_num = 0;
		_this.obj_layer.getChildren(function(layer){
			layer_num = layer.id();

			if (layer_num !== undefined) {
				_this.saveData.layers[layer_num] = [];

				// iterate through children of the layer
				layer.getChildren(function(node){
					var obj_save = node.getAttr("_save");
					var obj_saveInfo = obj_save.saveInfo;
					var obj_placeInfo = obj_save.placeInfo;

					obj_placeInfo.x = node.x();
					obj_placeInfo.y = node.y();

					_this.saveData.layers[layer_num].push({
						"placeType": obj_save.placeType,
						"placeInfo": obj_placeInfo,
						"saveInfo": obj_saveInfo
					});
				});	
			}
		});

		if (_this.onSave)
			_this.onSave(JSON.stringify(_this.saveData));
	}

	this.export = function() {
		this.save();
		return this.saveData;
	}

	this.import = function(data) {	
		// check data vailidity
		if (!(data !== undefined && data.length > 3))
			return;

		var load_data = JSON.parse(data);

		// iterate layers
		var layers = Object.keys(load_data.layers);
		for (var l = 0; l < layers.length; l++) {
			var layer = layers[l];
			this.setLayer(this.layerNameToNum(layer));

			// iterate objects
			var arr_layer = load_data.layers[layer]
			for (var o = 0; o < arr_layer.length; o++) {
				var obj = load_data.layers[layer][o];

				this.placeObj(obj.placeType, obj.placeInfo.x, obj.placeInfo.y, obj.placeInfo, this.layerNameToNum(layer));
			}
		}
		this.clearPlacer();
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

    var in_drag = false;
    $(window).on('keypress', function(e){
    	if (e.keyCode == 32) { // SPACE
    		in_drag = true;
    		_this.stage.draggable(true);
    	}
    });

    $(window).on('keyup', function(e){
    	if (e.keyCode == 32) { // SPACE
    		in_drag = false;
    		_this.stage.draggable(false);
    	}
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

		_this.capture_rect.x(_this.camera.x);
		_this.capture_rect.y(_this.camera.y);
	});

    this.stage.on('contentMousedown', function(e){
    	if (e.evt.which == 2)
	    	_this.stage.draggable(true);
    });

    this.stage.on('contentMouseup', function(e){
    	_this.stage.draggable(false);
    });

    var placing = false;
    var destroying = false;
    this.obj_layer.on('mousedown', function(e) {
    	placing = (e.evt.which == 1 && !in_drag);
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
    	if ((e.evt.which == 1) && !in_drag && (e.type === 'mouseup' || (e.type === 'mousemove' && placing))) {
	    	var pos = _this.getMouseXY();
	    	var mx = pos.x;
	    	var my = pos.y;

	    	var obj;
	    	switch(_this.curr_place_type) {
	    		case "image": 	obj = _this.placer_img; break;
	    		case "rect": 	obj = _this.placer_rect; break;
	    	}
	    	_this._placeObj(mx, my, _this.curr_place_type, obj);
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

	this.stage.draggable(false);

	// initial obj layer (0)
	this.setLayer(this.curr_layer);

	// load any saved data
	this.import(options.loadData);

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
