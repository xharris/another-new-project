var nwAUDIO = require("howler");

var aud_uuid, aud_properties;

var audio_settings = {
	"general" : [
		{"type": "bool", "name": "looping", "default": false},
		{"type": "number", "name": "volume", "default":1, "min":0, "max":1, "step":0.1},
		{"type" : "select", "name" : "type", "default" : "stream", "options" : ["stream", "static"], "tooltip": "stream - long music\nstatic - short sound effects"},
		{"type": "number", "name": "pitch", "default": 1, "min":-16, "max":16, "step":0.1},
	],
	"volume_limits" : [
		{"type": "number", "name": "min", "default":0, "min":0, "max":1, "step":0.1, "tooltip": "not reflected in preview"},
		{"type": "number", "name": "max", "default":1, "min":0, "max":1, "step":0.1, "tooltip": "not reflected in preview"},
	],
	"position" : [
		{"type": "number", "name": "x", "default":0, "min":-1000, "max":1000, "step":1},
		{"type": "number", "name": "y", "default":0, "min":-1000, "max":1000, "step":1},
		{"type": "number", "name": "z", "default":0, "min":-1000, "max":1000, "step":1}
	],
	"cone" : [
		{"type": "number", "name": "innerAngle", "default":360, "min":-360, "max":360, "step":1},
		{"type": "number", "name": "outerAngle", "default":360, "min":-360, "max":360, "step":1},
		{"type": "number", "name": "outerVolume", "default":0, "min":0, "max":1, "step":0.1}
	]
}

exports.libraryAdd = function(uuid, name) {
    eDIALOG.showOpenDialog(
        {
            title: "import audio file",
            properties: ["openFile"],
            filters: [
            	{name: 'All supported audio types', extensions: ['mp3','wav']},
            	{name: 'MP3', extensions: ['mp3']},
            	{name: 'WAV', extensions: ['wav']},
            ]
        },
        function (path) {
            if (path) {
                for (var p = 0; p < path.length; p++) {
	                importAudio(path[p]);
	            }
            } else {
            	b_library.delete(uuid);
            }
        }
    );
    return 0;
}

function importAudio(path) {
    if (['.mp3', '.wav'].includes(nwPATH.extname(path))) {
    	b_project.importResource('audio', path, function(e) {
    		var new_aud = b_library.add('audio');
    		new_aud.path = nwPATH.basename(e);
    		new_aud.parameters = {};

    		// fill in parameters with default values of audio_settings
    		var categories = Object.keys(audio_settings);
    		for (var c = 0; c < categories.length; c++) {
    			var setting;
    			new_aud.parameters[categories[c]] = {};
    			for (var s = 0; s < audio_settings[categories[c]].length; s++) {
    				setting = audio_settings[categories[c]][s];
    				new_aud.parameters[categories[c]][setting.name] = setting.default;
    			}
    		}
    	});
    }
}

var howler;
var rate;
exports.onDblClick = function(uuid, properties) {
	aud_uuid = uuid;
	aud_properties = properties;

	$(".workspace").append(
		"<div class='preview-container'>"+
			"<div id='audio-controls' class='ui-btn-group'>"+
				"<button id='btn-audio-play' class='ui-button-sphere'><i class='mdi mdi-play'></i></button>"+
				"<button id='btn-audio-stop' class='ui-button-sphere'><i class='mdi mdi-stop'></i></button>"+
				"<button id='btn-audio-back' class='ui-button-sphere'><i class='mdi mdi-step-backward'></i></button>"+
				"<button id='btn-audio-forward' class='ui-button-sphere'><i class='mdi mdi-step-forward'></i></button>"+
			"</div>"+
		"</div>"+
		"<div class='inputs-container'></div>"
	);

	// load audio manipulating controls
	blanke.createForm(".workspace > .inputs-container", audio_settings, properties.parameters,
		function (type, name, value, subcategory) {
			aud_properties.parameters[subcategory] = ifndef(aud_properties.parameters[subcategory], {});
			aud_properties.parameters[subcategory][name] = value;

			if (name == "volume")
				howler.volume(value);
			if (name == "looping")
				howler.loop(value);
			if (name == "pitch")
				howler.rate(value);

			if (subcategory == "position") {
				var pos = aud_properties.parameters[subcategory];
				howler.pos(pos.x, pos.y, pos.z);
			}
			if (subcategory == "cone") {
				var props = aud_properties.parameters[subcategory];
				howler.pannerAttr({
					coneInnerAngle: props.innerAngle,
					coneOuterAngle: props.outerAngle,
					coneOuterGain: props.outerVolume
				})
			}
		}
	);

	// create howl for playing the sound
	howler = new nwAUDIO.Howl({
		src: nwPATH.join(b_project.getResourceFolder('audio'), properties.path)
	});

	// music control event binding
	$(".workspace.audio > .preview-container >.ui-btn-group")
	.on('click', '#btn-audio-play', function(){
		howler.play();
	})
	.on('click', '#btn-audio-stop', function(){
		howler.stop();
	})
	.on('click', "#btn-audio-back", function(){
		howler.seek(howler.seek()-5);
	})
	.on('click', "#btn-audio-forward", function(){
		howler.seek(howler.seek()+5);
	});
}
