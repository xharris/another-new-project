var game,
	image,
	sprite,
	sheet_uuid,
	sheet_prop;

var sheet_data = {};
var frame_rects = [];

/*
var sprite_settings = {
	"Spritesheet" : [
		{"type" : "select", "name" : "min", "default" : "linear", "options" : ["linear", "nearest"]},
		{"type" : "number", "name" : "anisotropy", "default" : 1, "min" : 0, "max" : 1000000}
	]
}
*/

exports.libraryAdd = function(uuid, name) {
	return {
		img_source: '',
		parameters: {		
			frameWidth: 20,
			frameHeight: 20,
			frameMax: -1,
			margin: 0,
			spacing: 0,
			speed: 10
		}
	}
}

var win_sel;
exports.onDblClick = function(uuid, properties) {
	win_sel = blanke.createWindow({
        x: 210, 
        y: 50,
        width: 550,
        height: 350,
        class: 'spritesheet',
        title: properties.name,
        html: "<div class='preview-container'>"+
			"<div class='img-preview-container'>"+
				"<img src='' class='preview'>"+
				"<div class='frame-box-container'></div>"+
			"</div>"+
			"<div id='main-canvas'></div>"+
		"</div>"
	});
    b_canvas.init("spritesheet");
    sheet_uuid = uuid;
    sheet_prop = properties;
    sheet_data = sheet_prop.parameters;
}

exports.canvas = {
	preload: function() {
		game = b_canvas.pGame;
	   // get usable images
	    var sel_images = '';
	    for (var img in b_library.objects.image) {
	    	var obj = b_library.objects.image[img];
	    	sel_images += 
	    		"<option value='"+img+"'>"+obj.name+"</option>";
	    }

	    $(win_sel + " .content").append(
	        "<div class='inputs-section'>"+
        		"<select class='ui-select sp-image'>"+
        			"<option value='' disabled selected hidden>image source</option>"+
        			sel_images+
        		"</select>"+
        		"<div class='img-info'>"+
        			"<span class='width'></span> x <span class='height'></span>"+
        		"</div>"+
	        	"<div class='ui-input-group'>"+
	        		"<label>width</label>"+
	        		"<input type='number' name='frameWidth' min='0' value='"+sheet_data.frameWidth+"'>"+
	        	"</div>"+
	        	"<div class='ui-input-group'>"+
	        		"<label>height</label>"+
	        		"<input type='number' name='frameHeight' min='0' value='"+sheet_data.frameHeight+"'>"+
	        	"</div>"+
	        	"<div class='ui-input-group'>"+
	        		"<label>count</label>"+
	        		"<input type='number' name='frameMax' min='-1' value='"+sheet_data.frameMax+"'>"+
	        	"</div>"+
	        	"<div class='ui-input-group'>"+
	        		"<label>margin</label>"+
	        		"<input type='number' name='margin' min='0' value='"+sheet_data.margin+"'>"+
	        	"</div>"+
	        	"<div class='ui-input-group'>"+
	        		"<label>spacing</label>"+
	        		"<input type='number' name='spacing' min='0' value='"+sheet_data.spacing+"'>"+
	        	"</div>"+
	        	"<div class='ui-input-group'>"+
	        		"<label>speed</label>"+
	        		"<input type='number' name='speed' min='1' value='"+sheet_data.speed+"'>"+
	        	"</div>"+
	        "</div>"
	    );

	    $(win_sel + " .inputs-section").on('change', 'input', function(){
	    	b_library.getByUUID('spritesheet', sheet_uuid).parameters[$(this).attr('name')] = parseInt($(this).val());

	    	sheet_data = b_library.getByUUID('spritesheet', sheet_uuid).parameters;

	    	loadImage(sheet_prop.img_source);
	    });

	    // set chosen image and events
	    if (sheet_prop.img_source != '') {
		    loadImage(sheet_prop.img_source);
		}

	    $(win_sel + " .sp-image").val(sheet_prop.img_source);
	    $(win_sel + " .sp-image").on('change', function() {
	    	b_library.getByUUID('spritesheet', sheet_uuid).img_source = $(this).val();
	    	var new_img = 'img_'+$(this).val();

			loadImage($(this).val());

	    	b_project.autoSaveProject();
	    });
	}
}

function loadImage(uuid) {
	game = b_canvas.pGame;
	game.transparent = true;

	var img_path = nwPATH.join(b_project.getResourceFolder('image'), b_library.getByUUID('image', uuid).path);

	$(".img-preview-container > img").attr("src", img_path);

	var load = new Phaser.Loader(game);
	//load.image('img_'+uuid, img_path).onFileComplete.addOnce(_loadImage)
	load.spritesheet('spr_'+uuid, img_path,
		sheet_data.frameWidth,
		sheet_data.frameHeight,
		(sheet_data.frameMax == 0 ? 1 : sheet_data.frameMax),
		sheet_data.margin,
		sheet_data.spacing
	).onFileComplete.addOnce(_loadImage)
	load.start();
}

function _loadImage(progress, cacheKey, success, totalLoaded, totalFiles) {
	game = b_canvas.pGame;

	if (success) {
		updatePreview(cacheKey);
	}
}

function updatePreview(img_key) {
	b_project.autoSaveProject();

	// desroy already made preview
	if (sprite) {
		sprite.destroy();
	}
	try {
		//game.cache.removeSpriteSheet(img_key);
	} catch(e) {}

	sprite = game.add.sprite(0, 0, img_key);
	sprite.animations.add('anim');
    sprite.animations.play('anim', sheet_data.speed, true);

    var img_width = $(".img-preview-container > img").width();
    var img_height = $(".img-preview-container > img").height();

    // resize canvas
    game.scale.setGameSize(img_width, img_height);

	// change width/height input constraints
	$(".inputs-section input[name='frameWidth']").attr('max', img_width);
	$(".inputs-section input[name='frameHeight']").attr('max', img_width);
	if ($(".inputs-section input[name='frameWidth']").val() > img_width) {
		$(".inputs-section input[name='frameWidth']").val(img_width);
	}
	if ($(".inputs-section input[name='frameHeight']").val() > img_height) {
		$(".inputs-section input[name='frameHeight']").val(img_height);
	}

    $(win_sel + " .frame-box-container").empty();
    $(win_sel + " .frame-box-container").width(img_width)
    									.height(img_height);

    $(win_sel + " .img-info .width").html(img_width);
    $(win_sel + " .img-info .height").html(img_height);

    // add img frame rectangles
    var frame_count = sheet_data.frameMax;
    if (frame_count == -1) {
    	var fw = sheet_data.frameWidth;
    	var fh = sheet_data.frameHeight;

    	var h_count = (img_width - (img_width % fw)) / fw;
    	var v_count = (img_height - (img_height % fh)) / fh;

    	frame_count = h_count * v_count;
    }
    if (frame_count == 0) {
    	frame_count = 1;
    }

    for (var f = 0; f < frame_count; f++) {
    	$(win_sel + " .frame-box-container").append(
    		"<div class='frame-box' data-number='"+f+"'></div>"
    	);
    }
    $(win_sel + " .frame-box-container .frame-box").css({
    	'width': sprite.width,
    	'height': sprite.height,
    	'margin': sheet_data.margin,
    	'margin-right': sheet_data.margin + sheet_data.spacing
    });
}