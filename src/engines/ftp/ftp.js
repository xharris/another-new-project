var nwFTP = require('ssh2');

exports.disabled = true;

exports.modules = ['file'];
exports.colors = [
	"#ffe082", // amber 200
	"#ffd54f", // amber 300
	"#ffca28", // amber 400
]

exports.settings = {
	"initialization" : [
		{"type" : "text", "name" : "host", "default" : "domain.com"},
		{"type" : "text", "name" : "username", "default" : ""},
		{"type" : "password", "name" : "password", "default" : ""},
		{"type" : "select", "name" : "protocol", "default" : "ftp", "options" : ["ftp", "sftp", "ftps"]},
		{"type" : "number", "name" : "port", "default" : 22, "min" : 0, "max" : 65536},
	
		{"type" : "bool", "name" : "escape", "default" : "true"}
	],

	"other" : [
		{"type" : "text", "name" : "directory", "default" : ""},
	]
}

var ftp, sftp; // ssh2 instance
var init_settings = {};
exports.run = function(objects) {
	// get initialization settings
	for (var cat in exports.settings) {
		for (var s = 0; s < exports.settings[cat].length; s++) {
			var setting = exports.settings[cat][s].name;
			var value = b_project.getSetting("engine", setting)
			var category = cat;

			if (exports.settings[cat][s].type === "password")
				value = b_util.decrypt(value);

			if (category === "initialization") {
				init_settings[setting] = value
			}
		}
	}

	ftp = new nwFTP.Client();
	ftp.on('ready', function(){
		ftp.sftp(function(err, _sftp){
			if (err) throw err;
			sftp = _sftp;

			b_library.reset();
			load_path(b_project.getSetting("engine", "directory"), '.library .object-tree > .children');
		});
	}).connect(init_settings);
}

exports.loaded = function() {
	document.addEventListener("library.dbl_click", function(e){
		//e.detail.{type: type, uuid: uuid, properties: b_library.getByUUID(type, uuid)}
		if (e.detail.type === 'file') {
			code = nwPLUGINS['code_editor'].init('code', saveFile);
			file_path = '/'+e.detail.properties.path;
			var data = '';
			var file = sftp.createReadStream(file_path, {
				flags: 'r',
				encoding: 'utf-8',
				//handle: null,
				//mode: 0o666,
				autoClose: true
			}).on('readable', () => {
				// open file
				b_ide.clearWorkspace();
				$(".workspace").append(
					"<div id='code'></div>"
				);

				data = file.read();
			}).on('data', (chunk) => {
				console.log(chunk)
				code.setValue(chunk);
				console.log(`Received ${chunk.length} bytes of data.`);
			});
		}
	});


	document.addEventListener('project.open', function(e) {
		b_project.getEngine().run();
	});

	document.addEventListener("library.folder.click", function(e){
		if ($(e.detail.selector + ' > .children').children().length == 0) {
			var folder_path = '';

			var parent_folders = $(e.detail.selector).parents(".folder").map(function() {
				return $(this).children('.name').html();
			}).get().reverse();
			var folders = b_project.getSetting("engine", "directory").split('/').concat(parent_folders);
			folders.push($(e.detail.selector).children('.name').html());
			// remove blank folders
			folders = folders.filter(function(v){return v!==''});

			// final folder path
			var folder_path = folders.join('/');

			load_path(folder_path, e.detail.selector + ' > .children');
		}
	});
}

function load_path (path, sel) {
	console.log('/'+path + ',' + sel)
	sftp.readdir('/'+path, function(err, list){
		//console.log('loading /'+path + ',' + sel)
		if (err) {
			b_console.error('permission denied: ' + path);
			return;
		}

		console.log(list.length + ' items in ' + path)
		// sort alphabetically
		list.sort(function(a, b){
			return (a.filename <= b.filename ? -1 : 1);
		});

		for (var d = 0; d < list.length; d++) {
			setTimeout(function(f, selector, filepath, progress){
				b_ide.setProgress(progress);

				if (f.attrs.isDirectory()) {
					var sel_folder = b_library.addFolder(selector, f.filename);
				}
				else if (f.attrs.isFile()) {
					var new_file = b_library.add('file', undefined, selector);
					new_file.name = f.filename
					new_file.path = filepath + '/' + f.filename;
					b_library.rename(new_file.uuid, f.filename);

					// give data attribute to file
					$(selector + " > .file[data-uuid='"+new_file.uuid+"']").attr("path", filepath + '/' + f.filename)
				}
			}, 5, list[d], sel, path, d/list.length * 100);
		}

		// reset progress bar
		setTimeout(function(){
			b_ide.setProgress(0);
		}, 5 * list.length + 1);

	});
}

var code;
var file_path = '';

function saveFile() {
	console.log('save ' + file_path)
	var text = code.getValue();
	var file = sftp.createWriteStream(file_path, {
		flags: 'r',
		encoding: 'utf-8',
		//handle: null,
		//mode: 0o666,
		autoClose: true 
	}).on('open', () => {
		file.write(text);
		dispatchEvent('something.saved', {what: 'main.lua'});
	});
}
