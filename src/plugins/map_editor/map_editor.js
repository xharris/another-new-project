var MAP_SAVE_TIME = 250 ;

exports.init = function(options) {
	var new_map = new b_map(options);
	return new_map;
}

exports.settings = [
	{"type" : "number", "name" : "grid w", "default" : 32, "min" : 1, "max" : window.screen.availWidth},
	{"type" : "number", "name" : "grid h", "default" : 32, "min" : 1, "max" : window.screen.availHeight}
]

var b_map = function(options) {
	var _this = this;

	this.sel_id = options.id;
	this.onLayerChange = options.onLayerChange; // when a layer is added, moved up, moved down, deleted
	this.onMapChange = options.onMapChange;
	this.saveData = ifndef(options.loadData, {});

	this.konva = require('./konva.min.js');
	this.width = window.screen.availWidth;
	this.height = window.screen.availHeight;

	// grid
	this.grid_width = ifndef(b_project.getPluginSetting("map_editor", "grid w"), 32);
	this.grid_height = ifndef(b_project.getPluginSetting("map_editor", "grid h"), 32);
	this.bold_line_count = 10;

	this.scaleBy = 1.03;// how much to change scale on wheel
	this.newScale = 1;	// current scale of stage

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

	// placer: polygon
	this.placer_poly = new this.konva.Line();
	this.placing_poly = false;
	this.placing_poly_arr = [];

	this.focusClick = false;

	this.createGrid = function(width, height) {
		this.grid_width = width;
		this.grid_height = height;

		this.grid_group.destroy();
        this.grid_layer.draw();
		this.grid_group = new this.konva.Group();

		// vertical lines
		var grid_color = "#9E9E9E";
		for (var grid_w = -(this.width - (this.width % width)); grid_w < this.width*2; grid_w+=width){
			var opacity = 0.15;
			var w = grid_w*this.newScale;
			var strokeWidth = grid_w == 0 ? 4 : 1;
			if ((grid_w) % (width*this.bold_line_count) == 0)
				opacity = .5;

			var new_line = 
				new Konva.Line({
					points: [w, -this.height, w, this.height],
					stroke: grid_color,
					strokeWidth: strokeWidth,
					opacity: opacity
			    });
			new_line._orientation = "_vertical";
			new_line._w = (width*this.bold_line_count);
			new_line._h = (height*this.bold_line_count);
			new_line.listening(false);
		   	this.grid_group.add(new_line);
		}
		
		// horizontal lines
		for (var grid_h = -(this.height - (this.height % height)); grid_h < this.height*2; grid_h+=height){
			var opacity = 0.15;
			var h = grid_h*this.newScale;
			var strokeWidth = grid_h == 0 ? 4 : 1;
			if ((grid_h) % (height*this.bold_line_count) == 0)
				opacity = .5;

			var new_line = 
				new Konva.Line({
					points: [-this.width, h, this.width, h],
					stroke: grid_color,
					strokeWidth: strokeWidth,
					opacity: opacity
			    });
			new_line._orientation = "_horizontal";
			new_line._w = (width*this.bold_line_count);
			new_line._h = (height*this.bold_line_count);
			new_line.listening(false);
		    this.grid_group.add(new_line);
		}
		this.grid_layer.add(this.grid_group);
        this.grid_layer.draw();
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

		if (this.onMapChange)
			this.onMapChange();
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
			layer.destroy();
			
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
		var saveInfo = $.extend({}, options.saveInfo);

		delete options.saveInfo;
		options = ifndef(options.placeInfo, options);

		var saveData = {
			placeType: type,
			saveInfo: saveInfo,
			placeInfo: options
		};

		function retObj(obj, add_to_layer=false) {
			obj.setAttr("_save", saveData);

			if (callback) callback(obj.clone().setAttr("_save", saveData));
			else if(add_to_layer) {
				_this.placer_layer.add(obj);
				_this.placer_layer.draw();
			}
		}

		// TILE
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
					opacity: 0.5,
					name: "image"
				});

				retObj(_this.placer_img, true);
			};
			placer_img_obj.src = path;
		}

		// RECT ONLY
		if (type === "rect") {
			if (_this.placer_rect)
				_this.placer_rect.destroy();
			_this.placer_rect = new _this.konva.Group({
				name: "rect"
			});

			// icon
			var placer_img_obj = new Image();
			placer_img_obj.onload = function(){
				if (_this.placer_rect_img)
					_this.placer_rect_img.destroy();

				// rect
				var placer_rect = new _this.konva.Rect({
					x: 0, y: 0,
					width: options.width,
					height: options.height,
					stroke: options.color,
					strokeWidth: 2,
					perfectDrawEnabled: false
				});

				_this.placer_rect.add(placer_rect);

				_this.placer_rect_img = new _this.konva.Image({
					x: _this.grid_width/2,
					y: _this.grid_height/2,
					image: placer_img_obj,
					offsetX: Math.floor(options.width/2),
					offsetY: options.height/2,
					width: options.width,
					height:  options.height
				});

				//_this.placer_rect_img.cache();
				//_this.placer_rect_img.filters([_this.konva.Filters.RGBA]);
				_this.placer_rect.add(_this.placer_rect_img);

				retObj(_this.placer_rect);
			};
			placer_img_obj.src = options.icon;
		}

		// polygon
		if (type === "polygon") {
			_this.placer_poly = new _this.konva.Line({
				points: [],
				fill: options.color,
				stroke: options.color,
				strokeWidth: 1,
				opacity: 0.5,
				closed: true
			});

			retObj(_this.placer_poly);
		}
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

	var last_place = {x:undefined, y:undefined, layer:undefined};
	this._clearLastPlace = function(){
		last_place = {x:undefined, y:undefined, layer:undefined};
	}

	this._placeObj = function(x, y, type, obj, layer) {
		// prevent layering object on top of each other
		if (last_place.layer === layer && (last_place.x == x && last_place.y == y))
			return;
		last_place.x = x;
		last_place.y = y;
		last_place.layer = layer;

		layer = ifndef(layer, _this.curr_layer);
		var obj_layer = _this.getLayer(layer);
	    var new_obj;	

	    function transferSettings() {
			new_obj = obj.clone().setAttr("_save", obj.getAttr("_save"));
			obj_layer.add(new_obj);
	    }

		if (type === "rect") {
			obj.x(x);
			obj.y(y);

			/*
			this.placer_rect_img.cache();
			this.placer_rect_img.filters([this.konva.Filters.RGBA]);
			*/

			// transfer serialization info
			transferSettings()
    	}

    	if (type === "image") {
	    	var init_scale = 1.5;
	    	console.log(x, y)

    		new_obj = obj.clone({
    			x: x + obj.width()/init_scale,
    			y: y + obj.height()/init_scale,
    			scaleX: init_scale,
    			scaleY: init_scale,
    			offsetX: obj.width()/init_scale,
    			offsetY: obj.height()/init_scale
    		});

    		// transfer serialization info
    		transferSettings()

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
		        opacity: 1
		    });
		    tween.play();
    	}

    	if (type === "polygon") {
    		new_obj = obj.clone({
    			points: [x, y]
    		});
			transferSettings();
			_this.placing_poly=new_obj;
    	}

    	// prevent placing tiles right on top of each other
		if (new_obj)
		new_obj.on('mouseup mousemove', function(e){
			var evt_obj = e.target;
			var potential_parents = evt_obj.findAncestors("."+_this.curr_place_type, true);
			if (potential_parents.length > 0)
				evt_obj = potential_parents[0];

			// can destroy if:
			// 		correct mouse button
			//		on MouseUp
			// 		currenlty editing the same type of object

			if (e.type === 'mouseup' && e.evt.which == 3)
				destroying = false;

			// placer is placing on a different layer
			var group = evt_obj.findAncestors('Group');

			// find the Group that's a layer
			var id, layer_name;
			for (var g = 0; g < group.length; g++) {
				id = group[g].id();
				if (id !== undefined && id.includes("layer"))
					layer_name = id;
			}
			if (layer_name !== undefined && _this.layerNameToNum(layer_name) === _this.curr_layer) { 

				// actually, user is deleting this object
				if (e.evt.which == 3 && (e.type === 'mouseup' || (e.type === 'mousemove' && destroying)) && _this.curr_place_type === evt_obj.name()) {
					_this._clearLastPlace();
					evt_obj.destroy();
					_this.obj_layer.batchDraw();

					if (_this.onMapChange)
						_this.onMapChange();
				} else {
					var mouse = _this.getMouseXY();
					if (last_place.x === mouse.x && last_place.y === mouse.y)
						e.cancelBubble = true;
				}
    		}
		});

	   	if (type != '')
			_this.obj_layer.batchDraw();

		if (_this.onMapChange)
			_this.onMapChange();
	}

	var updateObjectTimeout;
	this.updateObject = function() {
		clearTimeout(updateObjectTimeout);
		updateObjectTimeout = setTimeout(this._updateObject, MAP_SAVE_TIME, arguments);
	}

	this._updateObject = function() {
		var args = arguments[0];

		var save_info_key = args[0];
		var save_info_value = args[1];
		var new_options = args[2];

		function changeIcon(obj, icon) {
			var new_img = new Image();
			new_img.onload = function(){
				obj.setImage(new_img);
			};
			new_img.src = icon;
		}

		// iterate through layers
		var layer_num = 0;
		var layers = _this.obj_layer.getChildren().toArray();
		for (var l = 0; l < layers.length; l++) {
			var layer = layers[l];
			layer_num = layer.id();

			if (layer_num !== undefined) {
				// iterate through children of the layer
				var children = layer.getChildren().toArray();
				for (var c = 0; c < children.length; c++) {
					var node = children[c];

					var obj_save = node.getAttr("_save");

					if (obj_save.saveInfo[save_info_key] === save_info_value) {
						obj_save.placeInfo = new_options;

						// RECT
						if (obj_save.placeType === "rect") {
							node.getChildren().each(function(sub_node){
								if (sub_node.getClassName() === "Rect")  {								
									// change outline color
									var tween = new Konva.Tween({
								        node: sub_node,
								        duration: 0.2,
								        easing: _this.konva.Easings.EaseOut,
								        stroke: new_options.color,
								        width: new_options.width,
								        height: new_options.height
								    });
								    tween.play();
								}

								if (sub_node.getClassName() === "Image") {
									// changle icon size
									var tween = new Konva.Tween({
								        node: sub_node,
								        duration: 0.2,
								        easing: _this.konva.Easings.EaseOut,
								        width: new_options.width,
								        height: new_options.height
								    });
								    tween.play();
								    // change icon image
								    changeIcon(sub_node, new_options.icon);
								}
							});
						}

						// TILE
						if (obj_save.placeType === "image") {

						}
					}

					// save new options
					node.setAttr("_save", obj_save);
				}
			}
		}
		_this.obj_layer.batchDraw();
	}
	
	this.getMouseXY = function(x, y) {
    	var pos = this.stage.getPointerPosition();
    	
    	var mx = pos.x + _this.camera.x;
    	var my = pos.y + _this.camera.y;
    	var signx = Math.sign(mx);
    	var signy = Math.sign(my);

    	//mx = Math.abs(mx);
    	//my = Math.abs(my);

    	// snap to grid
    	mx -= (mx % this.grid_width);
    	my -= (my % this.grid_height);

    	if (mx < 0) mx += this.grid_width;
    	if (my < 0) my += this.grid_height;

    	//mx *= signx;
    	//my *= signy;

    	return {x:mx, y:my};
	}

	this._save = function() {
		var saveData = {"layers":{}};

		// iterate through layers
		var layer_num = 0;
		var layers = _this.obj_layer.getChildren().toArray();
		for (var l = 0; l < layers.length; l++) {
			var layer = layers[l];
			layer_num = layer.id();

			if (layer_num !== undefined) {
				saveData.layers[layer_num] = [];

				// iterate through children of the layer
				var children = layer.getChildren().each(function(node, n){
					(function(node, layer, n){

						var node_data = node.getAttr("_save");

						var obj_saveInfo = node_data.saveInfo;
						var obj_placeInfo = node_data.placeInfo;

						obj_placeInfo.x = node.x();
						obj_placeInfo.y = node.y();

						var obj_save = {
							"placeType": node_data.placeType,
							"placeInfo": $.extend({}, obj_placeInfo),
							"saveInfo": obj_saveInfo
						}

						saveData.layers[layer].push($.extend({}, obj_save));

					})(node, layer_num, n);
				});
			}
		}
		_this.saveData = saveData;
		return saveData;
	}

	this.export = function() {
		return JSON.stringify(this._save());
	}

	this.import = function(data) {	
		// check data vailidity
		if (!(data !== undefined && data.length > 3))
			return;

		var load_data = JSON.parse(data);

		// temporarily disable onMapChange;
		var old_onMapChange = this.onMapChange;
		this.onMapChange = undefined;

		// iterate layers
		var layers = Object.keys(load_data.layers);
		for (var l = 0; l < layers.length; l++) {
			var layer = layers[l];
			this.setLayer(this.layerNameToNum(layer));

			// iterate objects
			var arr_layer = load_data.layers[layer]
			for (var o = 0; o < arr_layer.length; o++) {
				var obj = load_data.layers[layer][o];

				/*
				(function(_obj, _layer){
					_this._getPlacerObj(_obj.placeType, _obj, function(new_obj){
						_this._clearLastPlace();
						_this._placeObj(_obj.placeInfo.x, _obj.placeInfo.y, obj.placeType, new_obj, _this.layerNameToNum(_layer));
					});
				})(obj, layer);
				*/

				this.placeObj(obj.placeType, obj.placeInfo.x, obj.placeInfo.y, obj, this.layerNameToNum(layer));
			}
		}
		this.clearPlacer();
		this.obj_layer.batchDraw();

		// re-enable onMapChange
		this.onMapChange = old_onMapChange;
	}

	this.enableFocusClick = function() {
		this.focusClick = true;
		this.stage.container().style.cursor = 'pointer';
	}

	this.disableFocusClick = function() {
    	document.activeElement.blur();
		this.focusClick = false;
		this.stage.container().style.cursor = 'default';
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

	this.stage.on('dragmove', function(){
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
	   	if (_this.placing_poly && e.type === "mouseup") {
	   		if (_this.focusClick) {
    			_this.disableFocusClick();
    		} else {
		   		var pos = _this.getMouseXY();

		   		if (e.evt.which == 1) {
		   			// prevent layering object on top of each other
					if (last_place.layer === _this.curr_layer && (last_place.x == pos.x && last_place.y == pos.y))
						return;
					last_place.x = pos.x;
					last_place.y = pos.y;
					last_place.layer = _this.getLayer(_this.curr_layer);

					// append point to polygon
	    			var cur_points = _this.placing_poly.points();
	    			cur_points.push(pos.x, pos.y);
	    			_this.placing_poly.points(cur_points);
	    			var saveData = _this.placing_poly.getAttr("_save")

	    			// add new circle handle
	    			var new_circ = new _this.konva.Circle({
	    				x: pos.x,
	    				y: pos.y,
	    				radius: 4,
	    				stroke: saveData.placeInfo.color,
	    				strokeWidth: 2
	    			});
	    			_this.placing_poly_arr.push(new_circ);
	    			_this.obj_layer.add(new_circ);

	    			_this.obj_layer.draw();
		   		}

		   		if (e.evt.which == 3 && _this.placing_poly_arr.length >= 2) {
		   			// remove last set of coordinates
	    			var cur_points = _this.placing_poly.points();
	    			cur_points.pop();
	    			cur_points.pop();
	    			_this.placing_poly.points(cur_points);

	    			console.log(_this.placing_poly_arr.length)
	    			_this.placing_poly_arr[_this.placing_poly_arr.length-1].destroy();

	    			_this.obj_layer.draw();
		   		}
		   	}
	   	}
	   	else if ((e.evt.which == 1) && !in_drag && (e.type === 'mouseup' || (e.type === 'mousemove' && placing))) {
    		if (_this.focusClick) {
    			_this.disableFocusClick();
    		} else {
		    	var pos = _this.getMouseXY();
		    	var mx = pos.x;
		    	var my = pos.y;

		    	var obj;
		    	switch(_this.curr_place_type) {
		    		case "image": 	obj = _this.placer_img; break;
		    		case "rect": 	obj = _this.placer_rect; break;
		    		case "polygon": 	obj = _this.placer_poly; break;
		    	}
		    	_this._placeObj(mx, my, _this.curr_place_type, obj);
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
	this.createGrid(this.grid_width, this.grid_height);

	this.stage.draggable(false);

	// initial obj layer (0)
	this.setLayer(this.curr_layer);

	// load any saved data
	this.import(options.loadData);

	this.refreshScene = function() {
		this.width = window.screen.availWidth/this.newScale;
		this.height = window.screen.availHeight/this.newScale;
		_this.createGrid(this.grid_width, this.grid_height);
	}

	// zoom in/out
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
	        _this.refreshScene();
	        _this.stage.batchDraw();
	    }
    });

    $(this.sel_id).on("mousewheel", function(e) {
    	console.log(e)
	});

	document.addEventListener('blanke.form.change', function(e) {
		if (e.detail.name === "grid w" || e.detail.name === "grid h") {
			if (e.detail.name === "grid w") _this.grid_width = e.detail.value;
			if (e.detail.name === "grid h") _this.grid_height = e.detail.value;

			_this.createGrid(_this.grid_width, _this.grid_height);
		}
	});
}
