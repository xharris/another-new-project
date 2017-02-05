var nwHELPER = nwPLUGINS['build_helper'];

exports.modules = ['entity', 'image', 'state', 'spritesheet'];

// code editor
exports.entity_template = nwPATH.join(__dirname, 'entity_template.lua');
exports.state_template = nwPATH.join(__dirname, 'state_template.lua');
exports.language = 'lua';
exports.file_ext = 'lua';

function getBuildPath() {
	return nwPATH.join(b_project.curr_project, 'BUILDS');
}

exports.targets = {
	"love" : {
		build: function(objects) {
			b_console.log('build: love')

			buildLove(objects, function(path){
				eSHELL.openItem(nwPATH.dirname(path));
			});
		}
	},

	"windows" : {
		build: function(objects) {
			b_console.log('build: windows')

			var build_path = nwPATH.join(getBuildPath(), 'windows',  b_project.getSetting("engine", "title")+'.exe');
			nwMKDIRP(nwPATH.dirname(build_path), function(){

				buildLove(objects, function(path){
					switch(nwOS.platform()) {
						case "win32":
							// combine love.exe and .love
							// Ex. copy /b love.exe+SuperGame.love SuperGame.exe
							cmd = 'copy /b \"'+nwPATH.join(__dirname, "love-0.10.2-win32", "love.exe")+'\"+\"'+path+'\" \"'+build_path+'\"';
							nwCHILD.exec(cmd);

							// copy required dlls
							var other_files = ["love.dll", "lua51.dll", "mpg123.dll", "SDL2.dll"];
							for (var o = 0; o < other_files.length; o++) {
								var file = other_files[o];
								nwFILEX.copy(nwPATH.join(__dirname, "love-0.10.2-win32", file), nwPATH.join(nwPATH.dirname(build_path), file));
							}
							
							eSHELL.openItem(nwPATH.dirname(build_path));
						break;
					}
				});

			});
		}
	},

	"mac" : {
		build: function(objects) {
			var build_path = nwPATH.join(getBuildPath(), 'mac')

			nwMKDIRP(build_path, function(){
				// copy love.app and rename it
				build_path = nwPATH.join(build_path, b_project.getSetting("engine", "title")+'.app');
				nwFILEX.copy(nwPATH.join(__dirname, "love-0.10.2-macosx-x64", "love.app"), build_path, function(){
					// create .love and copy it into app/Contents/Resources/
					buildLove(objects, function(path){
						nwFILEX.copy(path, nwPATH.join(build_path, 'Contents', 'Resources', b_project.getSetting("engine", "title")+'.love'));

						// modify app/Contents/Info.plist			
						plist_repl = [
							['<COMPANY>', 'BlankEXHH'],
							['<TITLE>', b_project.getSetting("engine", "title")]
						];
						plist_path = nwPATH.join(build_path, 'Contents', 'Info.plist');
						nwHELPER.copyScript(plist_path, plist_path, plist_repl);

						eSHELL.openItem(nwPATH.dirname(build_path));
					});
				});
			});
		}
	}
}

exports.run = function(objects) {
	last_object_set = objects;
	var path = nwPATH.join(getBuildPath(), 'temp');
	build(path, objects, function(){
		var cmd = '';
		if (b_project.getSetting("engine","console")) 
			cmd = 'start cmd.exe /K \"'+nwPATH.join(__dirname, "love-0.10.2-win32", "love.exe")+' '+path+'\"';
		else 
			cmd = '\"'+nwPATH.join(__dirname, "love-0.10.2-win32", "love.exe")+'\" \"'+path+'\"';
		
		nwCHILD.exec(cmd);
	});
} 

exports.settings = {
	"misc" : [
		{"type" : "text", "name" : "identity", "default" : "nil"},
		{"type" : "text", "name" : "version", "default" : "0.10.2"},
		{"type" : "bool", "name" : "console", "default" : "false"},
		{"type" : "bool", "name" : "accelerometer joystick", "default" : "true"},
		{"type" : "bool", "name" : "external storage", "default" : "false"},
		{"type" : "bool", "name" : "gamma correct", "default" : "false"}
	],
	"window" : [
		{"type" : "text", "name" : "title", "default" : "Untitled"},
		// icon
		{"type" : "number", "name" : "width", "default" : 800, "min" : 0, "max" : 1000000},
		{"type" : "number", "name" : "height", "default" : 600, "min" : 0, "max" : 1000000},
		{"type" : "bool", "name" : "borderless", "default" : "false"},
		{"type" : "bool", "name" : "resizable", "default" : "true"},
		{"type" : "number", "name" : "minwidth", "default" : 1, "min" : 0, "max" : 1000000},
		{"type" : "number", "name" : "minheight", "default" : 1, "min" : 0, "max" : 1000000},

		{"type" : "bool", "name" : "fullscreen", "default" : "false"},
		{"type" : "select", "name" : "fullscreen type", "default" : "desktop", "options" : ["desktop", "exclusive"]},
		{"type" : "bool", "name" : "vsync", "default" : "true"},

		{"type" : "number", "name" : "msaa", "default" : 0, "min" : 0, "max" : 16},
		{"type" : "number", "name" : "display", "default" : 0, "min" : 0, "max" : 16},
		{"type" : "bool", "name" : "highdpi", "default" : "false"}
		// window.x
		// window.y	
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
				  "\tlocal img = assets:"+img.name+"()\n"+
				  "\treturn anim8.newGrid("+params.frameWidth+", "+params.frameHeight+", img:getWidth(), img:getHeight()), img\n"+
				  "end\n\n";
	}

	// CONF.LUA
	var conf = '';
	for (var cat in exports.settings) {
		for (var s = 0; s < exports.settings[cat].length; s++) {
			var setting = exports.settings[cat][s].name;
			var value = b_project.getSetting("engine", setting)
			var category = cat;

			if (category === "misc") {
				category = "";
			} else {
				category += ".";
			}

			var input_type = exports.settings[cat][s].type;
			if (input_type === "text") {
				if (value !== "nil" || value == undefined) 
					value = "\""+value.addSlashes()+"\"";
			}
			if (input_type === "select") {
				value = "\""+value+"\"";
			}

			if (value != undefined)
				conf += "t."+category+setting.replace(' ','')+" = "+value+"\n";
		}
		conf += "\n";
	}

	main_replacements = [
		['<INCLUDES>', script_includes],
		['<STATE_INIT>', state_init],
		['<FIRST_STATE>', first_state]
	];

	conf_replacements = [
		["<CONF>", conf]
	];

	assets_replacements = [
		['<ASSETS>', assets]
	];

	nwHELPER.copyScript(nwPATH.join(__dirname, 'conf.lua'), nwPATH.join(build_path,'conf.lua'), conf_replacements);
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

function buildLove(objects, callback) {
	var love_path = nwPATH.join(getBuildPath(), 'love', b_project.getSetting("engine", "title")+'.love');
	var path = nwPATH.join(getBuildPath(), 'temp');

	build(path, objects, function(){
		nwHELPER.zip(path, love_path, function(){
			// remove temp folder
			nwFILEX.removeSync(path);
			if (callback) 
				callback(love_path)
		});		
	});
}