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

exports.run = function(objects) {
	console.log('running')
} 

function build(build_path, objects) {
	nwMKDIRP(nwPATH.join(build_path, 'assets'), function(){
		// move game resources
		b_project.copyResources(nwPATH.join(build_path, 'assets'));

		// copy phaser itself
		nwFILEX.copySync(nwPATH.join(__dirname, 'phaser.min.js'), nwPATH.join(build_path, "phaser.min.js"));
	});

	// get template code
	var html_code = nwFILE.readFileSync(nwPATH.join(__dirname, 'index.html'), 'utf8');
	var js_code = nwFILE.readFileSync(nwPATH.join(__dirname, 'main.js'), 'utf8');

	var script_includes = '';
	for (var e in objects['entity']) {
		var ent = objects['entity'][e];

		script_includes += "<script src=\"assets/scripts/entity/"+ent.code_path.replace(/\\/g,"/")+"\"></script>"
	}
	html_code = html_code.replace("<SCRIPTS>", script_includes);

	console.log(html_code);

	js_code = js_code.replace("<WIDTH>", 800);
	js_code = js_code.replace("<HEIGHT>", 600);

	console.log(js_code);
}