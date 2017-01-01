var nwHELPER = nwPLUGINS['build_helper'];

exports.modules = ['entity', 'image', 'state', 'spritesheet'];

// code editor
exports.entity_template = nwPATH.join(__dirname, 'entity_template.lua');
exports.state_template = nwPATH.join(__dirname, 'state_template.lua');
exports.language = 'lua';
exports.file_ext = 'lua';

exports.targets = {
	"windows" : {
		build: function(objects) {
			b_console.log('build: windows')
			buildDesktop(objects, 'win');
		}
	}
}

exports.run = function(objects) {
	last_object_set = objects;
	var path = nwPATH.join(b_project.curr_project, 'BUILDS', 'love');
	build(path, objects, function(){
		nwCHILD.exec('\"'+nwPATH.join(__dirname, "love-0.10.2-win32", "love.exe")+'\" \"'+path+'\"', function(err, stdout, stderr){

		})
	});
} 

exports.settings = {
	"misc" : [
		{"type" : "bool", "name" : "console", "default" : "false"},
		{"type" : "bool", "name" : "accelerometer joystick", "default" : "true"},
		{"type" : "bool", "name" : "external storage", "default" : "false"},
		{"type" : "bool", "name" : "gamma correct", "default" : "false"}
	],
	"window" : [
		{"type" : "text", "name" : "title", "default" : "Untitled"},
		{"type" : "number", "name" : "game width", "default" : 800, "min" : 0, "max" : 1000000},
		{"type" : "number", "name" : "game height", "default" : 600, "min" : 0, "max" : 1000000},

		{"type" : "select", "name" : "fullscreen type", "default" : "desktop", "options" : ["dekstop", "exclusive"]},
		{"type" : "bool", "name" : "vsync", "default" : "true"}
	], 
	"modules" : [
		{"type" : "bool", "name" : "audio", "default" : "true"},
		{"type" : "bool", "name" : "event", "default" : "true"},
		{"type" : "bool", "name" : "graphics", "default" : "true"},
		{"type" : "bool", "name" : "image", "default" : "true"},
		{"type" : "bool", "name" : "joystick", "default" : "true"},
		{"type" : "bool", "name" : "keyboard", "default" : "true"},
		{"type" : "bool", "name" : "math", "default" : "true"},
		{"type" : "bool", "name" : "mouse", "default" : "true"},
		{"type" : "bool", "name" : "physics", "default" : "true"},
		{"type" : "bool", "name" : "sound", "default" : "true"},
		{"type" : "bool", "name" : "system", "default" : "true"},
		{"type" : "bool", "name" : "timer", "default" : "true"},
		{"type" : "bool", "name" : "touch", "default" : "true"},
		{"type" : "bool", "name" : "video", "default" : "true"},
		{"type" : "bool", "name" : "window", "default" : "true"},
		{"type" : "bool", "name" : "thread", "default" : "true"}
	]
}

var codemirror;
exports.library_const = [
	{
		"name": "main.lua",
		dbl_click: function() {
			b_ide.clearWorkspace();
			$(".workspace").append(
				"<div id='code'></div>"
			);

			codemirror = nwPLUGINS['code_editor'].init('code', function(){
				var text = codemirror.getValue();
				nwFILE.writeFile(nwPATH.join(b_project.curr_project, "assets", "main.lua"), text, function(err){
					if (err)
						b_console.error(err);
					else
						dispatchEvent('something.saved', {what: 'main.lua'});
				});
			});

			nwFILE.readFile(nwPATH.join(b_project.curr_project, "assets", "main.lua"), 'utf-8', function(err, data){
				if (!err) {
					codemirror.setValue(data);
				}
			});
		}
	}
]

document.addEventListener("project.open", function(e){
	if (b_project.getData("engine") !== "love2d") return;
	// copy main.lua template to project folder
	nwFILE.readFile(nwPATH.join(b_project.curr_project, "assets", "main.lua"), function(err, data){
		if (err) {
			var html_code = nwFILEX.copy(
				nwPATH.join(__dirname, 'main.lua'),
				nwPATH.join(b_project.curr_project, "assets", "main.lua")
			);
		}
	});
});

var building = false;
function build(build_path, objects, callback) {
	if (building) return;
	building = true;

	// ENTITIES
	var script_includes = '';
	for (var e in objects['entity']) {
		var ent = objects['entity'][e];

		if (ent.code_path.length > 1)
			script_includes += ent.name + " = require \"assets/scripts/"+ent.code_path.replace(/\\/g,"/").replace('.lua','')+"\"\n";
	}

	// STATES
	var state_init = '';
	var first_state = '';
	for (var e in objects['state']) {
		var ent = objects['state'][e];

		if (first_state === '') {
			first_state = ent.name;
		}

		if (ent.code_path.length > 1)
			script_includes += ent.name + " = require \"assets/scripts/"+ent.code_path.replace(/\\/g,"/").replace('.lua','')+"\"\n";

		//state_init += "\tlocal "+ent.name+" = {}\n";
	}

	var assets = '';

	// IMAGES
	for (var e in objects['image']) {
		var img = objects['image'][e];

		assets += "function assets:"+img.name+"()\n"+
			 	  "\treturn love.graphics.newImage(\'assets/image/"+img.path+"\');\n"+
			 	  "end\n\n";			  
	}

	// SPRITESHEET
	for (var e in objects['spritesheet']) {
		var spr = objects['spritesheet'][e];
		var img = b_library.getByUUID("image", spr.img_source);

		params = spr.parameters;

		assets += "function assets:"+spr.name+'()\n'+
				  "\tlocal img = self:"+img.name+"()\n"+
				  "\treturn anim8.newGrid("+params.frameWidth+", "+params.frameHeight+", img:getWidth(), img:getHeight());\n"+
				  "end\n\n";
	}

	main_replacements = [
		['<INCLUDES>', script_includes],
		['<STATE_INIT>', state_init],
		['<FIRST_STATE>', first_state],
		['<IMAGES>', images],
		['<SPRITES>', sprites]
	];

	conf_replacements = [
		["<WIDTH>", b_project.getSetting("engine", "game width")],
		["<HEIGHT>", b_project.getSetting("engine", "game height")]
	];

	assets_replacements = [
		['<ASSETS>', assets]
	];

	nwHELPER.copyScript(nwPATH.join(__dirname, 'love.conf'), nwPATH.join(build_path,'love.conf'), conf_replacements);
	nwHELPER.copyScript(nwPATH.join(__dirname, 'assets.lua'), nwPATH.join(build_path,'assets.lua'), assets_replacements);

	nwMKDIRP(nwPATH.join(build_path, 'assets'), function(){
		nwHELPER.copyScript(nwPATH.join(b_project.curr_project, "assets", "main.lua"), nwPATH.join(build_path,'main.lua'), main_replacements);

		// move game resources
		b_project.copyResources(nwPATH.join(build_path, 'assets'));
		nwFILEX.copy(nwPATH.join(__dirname, "plugins"), nwPATH.join(build_path, 'plugins'), function(err) {
			if (!err) {
				nwFILE.unlink(nwPATH.join(build_path, 'assets', 'main.lua'), function(err){
					// zip up .love (HEY: change line from folder to .love)
					// ...
				
					building = false;
					if (callback)
						callback();
				});
			}
		});
	});
}