var game,
	curr_img,
	sprite,
	sheet_uuid,
	sheet_prop;

exports.libraryAdd = function(uuid, name) {
	return {
		img_source: ''
	}
}

exports.onDblClick = function(uuid, properties) {
    b_canvas.init("spritesheet");
    sheet_uuid = uuid;
    sheet_prop = properties;
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

	    $(".workspace").append(
	        "<div class='inputs-section'>"+
	        	"<div class='ui-input-group'>"+
	        		"<select class='ui-select sp-image'>"+
	        			"<option value='' disabled selected hidden>image source</option>"+
	        			sel_images+
	        			"</select>"+
	        	"</div>"+
	        "</div>"
	    );

	    // set chosen image and events
	    loadImage(sheet_prop.img_source);

	    $(".workspace .sp-image").val(sheet_prop.img_source);
	    $(".workspace .sp-image").on('change', function() {
	    	b_library.getByUUID('spritesheet', sheet_uuid).img_source = $(this).val();
	    	var new_img = 'img_'+$(this).val();

			loadImage($(this).val());

	    	b_project.autoSaveProject();
	    });
	}
	
}

function loadImage(uuid) {
	game = b_canvas.pGame;

	var img_path = nwPATH.join(b_project.curr_project, b_library.getByUUID('image', uuid).path);

	var load = new Phaser.Loader(game);
	load.image('img_'+uuid, img_path).onFileComplete.addOnce(_loadSprite)
	load.start();
}

function _loadSprite(progress, cacheKey, success, totalLoaded, totalFiles) {
	game = b_canvas.pGame;

	if (success) {
		if (sprite) {
			sprite.destroy();
		}
		sprite = game.add.sprite(5, 51, cacheKey);
	}
}