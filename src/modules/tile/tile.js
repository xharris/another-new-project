var game,
	image,
	sprite,
	sheet_uuid,
	sheet_prop;

var sheet_data = {};
var frame_rects = [];

exports.libraryAdd = function(uuid, name) {
	return {
		img_source: '',
		parameters: {		
			tileWidth: 20,
			tileHeight: 20,
            tileMarginX: 0,
            tileMarginY: 0
		}
	}
}

exports.onDblClick = function(uuid, properties) {
	$(".workspace").append(
		"<div class='preview-container'>"+
			"<div class='img-preview-container'>"+
				"<img src='' class='preview'>"+
				"<div class='frame-box-container'></div>"+
			"</div>"+
		"</div>"
	);
	
    sheet_uuid = uuid;
    sheet_prop = properties;
    sheet_data = sheet_prop.parameters;

	   // get usable images
    var sel_images = '';
    for (var img in b_library.objects.image) {
    	var obj = b_library.objects.image[img];
    	sel_images += 
    		"<option value='"+img+"'>"+obj.name+"</option>";
    }

    $(".workspace").append(
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
        		"<input type='number' name='tileWidth' min='0' value='"+sheet_data.tileWidth+"'>"+
        	"</div>"+
        	"<div class='ui-input-group'>"+
        		"<label>height</label>"+
        		"<input type='number' name='tileHeight' min='0' value='"+sheet_data.tileWidth+"'>"+
        	"</div>"+
            "<div class='ui-input-group'>"+
                "<label>margin x</label>"+
                "<input type='number' name='tileMarginX' min='0' value='"+sheet_data.tileMarginX+"'>"+
            "</div>"+
            "<div class='ui-input-group'>"+
                "<label>margin y</label>"+
                "<input type='number' name='tileMarginY' min='0' value='"+sheet_data.tileMarginY+"'>"+
            "</div>"+
        "</div>"
    );

    $(".workspace .inputs-section").on('change', 'input', function(){
    	b_library.getByUUID('tile', sheet_uuid).parameters[$(this).attr('name')] = parseInt($(this).val());

    	sheet_data = b_library.getByUUID('tile', sheet_uuid).parameters;

    	loadImage(sheet_prop.img_source);
    });

    // set chosen image and events
    if (sheet_prop.img_source != '') {
	    loadImage(sheet_prop.img_source);
	}

    $(".workspace .sp-image").val(sheet_prop.img_source);
    $(".workspace .sp-image").on('change', function() {
    	b_library.getByUUID('tile', sheet_uuid).img_source = $(this).val();
    	var new_img = 'img_'+$(this).val();

		loadImage($(this).val());

    	b_project.autoSaveProject();
    });
}

function loadImage(uuid) {
	game = b_canvas.pGame;

	var img_path = nwPATH.join(b_project.curr_project, b_library.getByUUID('image', uuid).path);

	$(".img-preview-container > img").attr("src", img_path);

    updatePreview();
}

function updatePreview() {
	b_project.autoSaveProject();

    var img_width = $(".img-preview-container > img").width();
    var img_height = $(".img-preview-container > img").height();

	// change width/height input constraints
	$(".inputs-section input[name='tileWidth']").attr('max', img_width);
	$(".inputs-section input[name='tileHeight']").attr('max', img_width);
	if ($(".inputs-section input[name='tileWidth']").val() > img_width) {
		$(".inputs-section input[name='tileWidth']").val(img_width);
	}
	if ($(".inputs-section input[name='tileHeight']").val() > img_height) {
		$(".inputs-section input[name='tileHeight']").val(img_height);
	}

    $(".workspace .frame-box-container").empty();
    $(".workspace .frame-box-container").width(img_width)
    									.height(img_height);

    $(".workspace .img-info .width").html(img_width);
    $(".workspace .img-info .height").html(img_height);

    var frame_count = (img_width * img_height) / ((sheet_data.tileWidth + sheet_data.tileMarginX) * (sheet_data.tileHeight + sheet_data.tileMarginY));
    for (var f = 0; f < frame_count; f++) {
    	$(".workspace .frame-box-container").append(
    		"<div class='frame-box' data-number='"+f+"'></div>"
    	);
    }
    $(".workspace .frame-box-container .frame-box").css({
    	'width': sheet_data.tileWidth,
    	'height': sheet_data.tileHeight,
        'margin-right': sheet_data.tileMarginX,
        'margin-bottom': sheet_data.tileMarginY
    });
}