var nwCONNECT = require('connect');
var nwSERVE = require('serve-static');
var nwBUILD = require('nw-builder');

exports.modules = ['entity', 'image', 'state', 'spritesheet'];
exports.language = 'javascript';
exports.file_ext = 'js';

exports.targets = {
	"html": {
		build: function(objects) {
			var path = nwPATH.join(b_project.curr_project, 'BUILDS', 'html');
			build(path, objects);
		}
	},

	"windows" : {
		build: function(objects) {
			b_console.log('build: windows')
			buildDesktop(objects, 'win');
		}
	},
	"mac" : {
		build: function(objects) {
			b_console.log('build: osx')
			buildDesktop(objects, 'osx');
		}
	},
	"linux" : {
		build: function(objects) {
			b_console.log('build: linux')
			buildDesktop(objects, 'linux');
		}
	}
}

function buildDesktop(objects, os) {
	var path = nwPATH.join(b_project.curr_project, 'temp');
	var build_path = nwPATH.join(b_project.curr_project, 'BUILDS', os);

	nwFILEX.remove(build_path, function(err) {
		if (err) {
			console.error(err);
			b_console.error(
				'Cannot delete '+
				'<a>'+build_path+'</a>'+ // TODO: turn into clickable path
				'. Please delete manually.'
			);
			return;
		}
		b_console.log("removed "+build_path);

		build(path, objects, function(){
			// create package.json
			var win_height_offset = 31;
			var json_text = JSON.stringify({
				'name': 'my-game',
				'version': '1.0.0',
				'main': 'index.html',
				'window': {
					"frame": true,
					"toolbar": false,
					"width": b_project.getSetting("engine", "game width"),
					"height": b_project.getSetting("engine", "game height")-win_height_offset,
					"min_width": b_project.getSetting("engine", "game width"),
					"min_height": b_project.getSetting("engine", "game height")-win_height_offset,
					"max_width": b_project.getSetting("engine", "game width"),
					"max_height": b_project.getSetting("engine", "game height")-win_height_offset,
					"resizable": false,
					"fullscreen": false
				}
			});
			console.log(nwPATH.join(path, 'package.json'))
			nwFILE.writeFile(nwPATH.join(path, 'package.json'), json_text, function(err){
				if (!err) {
					b_console.log('building ' + path)
					var nw = new nwBUILD({
						files: nwPATH.join(path),
						platforms: [os],
						//flavor: 'normal',
						buildDir: build_path
					});
					nw.on('log', b_console.log);
					nw.build().then(function(){
						b_console.success("finished building ("+os+")");
						eSHELL.openItem(build_path);
					}).catch(function(err){
						b_console.error(err);
					});
				}
			});
			
		});
	});
	

}

exports.settings = {
	"initialization" : [
		{
			"type" : "number",
			"name" : "game width",
			"default" : 800,
			"min" : 0,
			"max" : 1000000
		},
		{
			"type" : "number",
			"name" : "game height",
			"default" : 600,
			"min" : 0,
			"max" : 1000000
		},
		{
			"type" : "select",
			"name" : "renderer",
			"default" : "auto",
			"options" : ["auto", "web", "canvas"]
		}
	]
}

var codemirror;
exports.library_const = [
	{
		"name": "index.html",
		dbl_click: function() {
			b_ide.clearWorkspace();
			$(".workspace").append(
				"<div id='code'></div>"
			);

			codemirror = nwPLUGINS['code_editor'].init('code', function(){
				var text = codemirror.getValue();
				nwFILE.writeFile(nwPATH.join(b_project.curr_project, "assets", "index.html"), text, function(err){
					if (err)
						b_console.error(err);
					else
						dispatchEvent('something.saved', {what: 'index.html'});
				});
			});

			nwFILE.readFile(nwPATH.join(b_project.curr_project, "assets", "index.html"), 'utf-8', function(err, data){
				if (!err) {
					codemirror.setValue(data);
				}
			});
		}
	}
]

var last_object_set;
var server_running = false;
var rebuild_timeout = 0;
var REBUILD_TIME = 500;
document.addEventListener("something.saved", function(e){
	if (["project"].includes(e.detail.what)) {
		var rebuild_timeout = setTimeout(rebuild(), REBUILD_TIME);
	}
});

document.addEventListener("assets.modified", function(e) {
	var rebuild_timeout = setTimeout(rebuild(), REBUILD_TIME);
});

document.addEventListener("project.open", function(e){
	if (b_project.getData("engine") !== "phaser") return;
	server_running = false;

	// copy index.html template to project folder
	nwFILE.readFile(nwPATH.join(b_project.curr_project, "assets", "index.html"), function(err, data){
		if (err) {
			var html_code = nwFILEX.copy(
				nwPATH.join(__dirname, 'index.html'),
				nwPATH.join(b_project.curr_project, "assets", "index.html")
			);
		}
	});
});


function rebuild() {
	if (server_running) {
		console.log('rebuild');
		var path = nwPATH.join(b_project.curr_project, 'temp');
		build(path, last_object_set);
	}
}

exports.run = function(objects) {
	last_object_set = objects;
	var path = nwPATH.join(b_project.curr_project, 'temp');
	build(path, objects, function(){
		if (!server_running) {
			nwCONNECT().use(nwSERVE(path)).listen(8080, function(){
				server_running = true;
				nwOPEN('http://localhost:8080/');
			});
		}
	});

} 

var building = false;
function build(build_path, objects, callback) {
	if (building) return;
	building = true;

	// get main file template code
	var html_code = nwFILE.readFileSync(nwPATH.join(b_project.curr_project, "assets", "index.html"), 'utf8');
	var js_code = nwFILE.readFileSync(nwPATH.join(__dirname, 'main.js'), 'utf8');

	// ENTITIES
	var script_includes = '';
	for (var e in objects['entity']) {
		var ent = objects['entity'][e];

		script_includes += "<script src=\"assets/scripts/"+ent.code_path.replace(/\\/g,"/")+"\"></script>\n";
	}

	// STATES
	var state_init = '';
	var first_state = '';
	for (var e in objects['state']) {
		var ent = objects['state'][e];

		if (first_state === '') {
			first_state = ent.name;
		}

		script_includes += "\t<script src=\"assets/scripts/"+ent.code_path.replace(/\\/g,"/")+"\"></script>\n";
		state_init += "\tgame.state.add(\'"+ent.name+"\', "+ent.name+");\n";
	}

	if (first_state !== '') {
		state_init += "\tgame.state.start(\'"+first_state+"\');"
	}

	// IMAGES
	var preload = '';
	for (var e in objects['image']) {
		var img = objects['image'][e];

		preload += "\tgame.load.image(\'"+img.name+"\', \'assets/image/"+img.path+"\');\n";
	}
	// SPRITESHEET
	for (var e in objects['spritesheet']) {
		var spr = objects['spritesheet'][e];
		params = spr.parameters;

		preload += "\tgame.load.spritesheet(\'"+spr.name+"\', \'assets/image/"+b_library.getByUUID("image", spr.img_source).path+"\', "+params.frameWidth+", "+params.frameHeight+", "+params.frameMax+", "+params.margin+", "+params.spacing+");\n";
	}

	html_replacements = [
		['<TITLE>', 'my game'],
		['<SCRIPTS>', script_includes]
	];

	js_replacements = [
		["<PRELOAD>", preload],
		["<CREATE>", ""],
		["<STATE_INIT>", state_init],
		["<WIDTH>", b_project.getSetting("engine", "game width")],
		["<HEIGHT>", b_project.getSetting("engine", "game height")],
		['<RENDERER>', b_project.getSetting("engine", "renderer").toUpperCase()]
	];

	for (var h in html_replacements) {
		html_code = html_code.replace(html_replacements[h][0],html_replacements[h][1]);
	}

	for (var r in js_replacements) {
		js_code = js_code.replace(js_replacements[r][0],js_replacements[r][1]);
	}

	nwMKDIRP(nwPATH.join(build_path, 'assets'), function(){
		// move game resources
		b_project.copyResources(nwPATH.join(build_path, 'assets'));

		// copy phaser itself
		nwFILE.readFile(nwPATH.join(build_path, "phaser.min.js"), function(err){
			if (err)
				nwFILEX.copySync(nwPATH.join(__dirname, 'phaser.min.js'), nwPATH.join(build_path, "phaser.min.js"));
		});
		
		// write main game files
		nwFILE.writeFileSync(nwPATH.join(build_path,'index.html'), html_code);
		nwFILE.writeFileSync(nwPATH.join(build_path,'main.js'), js_code);

		building = false;
		if (callback)
			callback();
	});
}