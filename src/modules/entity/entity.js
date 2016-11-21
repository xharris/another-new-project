var obj_uuid,
	obj_prop;

var codemirror;

require('codemirror/mode/xml/xml');
require('codemirror/mode/javascript/javascript');
require('codemirror/mode/css/css');
require('codemirror/mode/htmlmixed/htmlmixed');

var nwCODE = require("codemirror/lib/codemirror");

function setCodePath() {
	obj_prop.code_path = nwPATH.join('entity', obj_prop.name + '_' + obj_uuid + '.js');
}

function getCodePath() {
	return nwPATH.join(b_project.getResourceFolder('scripts'), obj_prop.code_path);
}

exports.libraryAdd = function(uuid, name) {
	return {
		code_path: nwPATH.join('entity', name + '_' + uuid + '.js'),
	}
}

exports.onDblClick = function(uuid, properties) {
	obj_uuid = uuid;
	obj_prop = properties;

	$(".workspace.entity").append(
		"<div id='code'></div>"
	);

	codemirror = nwCODE(document.getElementById("code"), {
		mode: 'javascript',
		lineWrapping: true,
		extraKeys: {
			'Ctrl-Space': 'autocomplete'
		},
		lineNumbers: true,
		theme: 'monokai',
		value: ""
	});

	loadScript(uuid);
}

exports.onClose = function(uuid) {
	saveScript();

	b_project.autoSaveProject();
}



function loadScript(uuid) {
	console.log(obj_prop)
	nwMKDIRP(nwPATH.join(nwPATH.dirname(getCodePath())), function() {
		try {
			var code = nwFILE.readFileSync(getCodePath(), 'utf8');
			codemirror.setValue(code);
		} catch (e) {
			// make script file if it doesn't exist
			saveScript();
		}
	});
}

function saveScript(retry=false) {
	if (obj_prop.code_path === '') {
		obj_prop.code_path = nwPATH.join('entity', obj_prop.name + '_' + obj_uuid + '.js');
	}
	var code = codemirror.getValue();
	// get template if there's no code
	if (code === "") {
		code = nwFILE.readFileSync(nwPATH.join(__dirname, "entity_template.js"), 'utf8');

		var replacements = [
			['UUID', obj_uuid],
			['NAME', obj_prop.name]
		];

	for (var r in replacements) {
		code = code.replace(new RegExp('<'+replacements[r][0]+'>', 'g'), replacements[r][1]);
	}

		codemirror.setValue(code);
	}
	nwFILE.writeFile(getCodePath(), code, function(err) {
		if (err && !retry) {
			// try again
			obj_prop.code_path = nwPATH.join('entity', obj_prop.name + '_' + obj_uuid + '.js');
			saveScript(true);
		}
	});
}