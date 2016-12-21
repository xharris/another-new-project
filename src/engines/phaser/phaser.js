var nwCONNECT = require('connect');
var nwSERVE = require('serve-static');

exports.targets = {
	"html": {
		build: function(objects) {
			var path = nwPATH.join(b_project.curr_project, 'BUILDS', 'html');
			build(path, objects);
		}
	},

	"windows" : {
		build: function(objects) {
			var path = nwPATH.join(b_project.curr_project, 'BUILDS', 'windows');
			build(path, objects);
		}
	}
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

var last_object_set;
var server_running = false;
document.addEventListener("something.saved", function(e){
	if (server_running && ["entity", "state", "project"].includes(e.detail.what)) {
		var path = nwPATH.join(b_project.curr_project, 'temp');
		build(path, last_object_set);
	}
});

document.addEventListener("project.open", function(e){
	server_running = false;
})

exports.run = function(objects) {
	last_object_set = objects;
	var path = nwPATH.join(b_project.curr_project, 'temp');
	build(path, objects);

	if (!server_running) {
		nwCONNECT().use(nwSERVE(path)).listen(8080, function(){
			server_running = true;
			nwOPEN('http://localhost:8080/');
		});
	}
} 

function build(build_path, objects, callback) {
	// get main file template code
	var html_code = nwFILE.readFileSync(nwPATH.join(__dirname, 'index.html'), 'utf8');
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

	html_code = html_code.replace("<SCRIPTS>", script_includes);

	js_replacements = [
		["<PRELOAD>", preload],
		["<CREATE>", ""],
		["<STATE_INIT>", state_init],
		["<WIDTH>", 500],
		["<HEIGHT>", 200],
		['<RENDERER>', b_project.getSetting("engine", "renderer").toUpperCase()]
	];

	for (var r in js_replacements) {
		js_code = js_code.replace(js_replacements[r][0],js_replacements[r][1]);
	}

	nwMKDIRP(nwPATH.join(build_path, 'assets'), function(){
		// move game resources
		b_project.copyResources(nwPATH.join(build_path, 'assets'));

		// copy phaser itself
		nwFILEX.copySync(nwPATH.join(__dirname, 'phaser.min.js'), nwPATH.join(build_path, "phaser.min.js"));
	
		// write main game files
		nwFILE.writeFileSync(nwPATH.join(build_path,'index.html'), html_code);
		nwFILE.writeFileSync(nwPATH.join(build_path,'main.js'), js_code);

		if (callback)
			callback();
	});
}