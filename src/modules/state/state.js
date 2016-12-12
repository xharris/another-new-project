var obj_uuid,
	obj_prop;

var codemirror;

function setCodePath() {
	obj_prop.code_path = nwPATH.join('state', obj_prop.name + '_' + obj_uuid + '.js');
}

function getCodePath() {
	return nwPATH.join(b_project.getResourceFolder('scripts'), obj_prop.code_path);
}

exports.libraryAdd = function(uuid, name) {
	return {
		code_path: nwPATH.join('state', name + '_' + uuid + '.js'),
	}
}

exports.onDblClick = function(uuid, properties) {
	obj_uuid = uuid;
	obj_prop = properties;

	$(".workspace.state").append(
		"<div id='code'></div>"
	);

	codemirror = nwPLUGINS["code_editor"].init('code', {
		mode: 'javascript',
		extraKeys: {
			'Ctrl-Space': 'autocomplete',
			'Ctrl-S': saveScript
		},
		lineNumbers: true,
		theme: 'monokai',
		value: "",
		indentUnit: 4
	});

	loadScript(uuid);
}

exports.onClose = function(uuid) {
	saveScript();

	b_project.autoSaveProject();
}



function loadScript(uuid) {
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
		obj_prop.code_path = nwPATH.join('state', obj_prop.name + '_' + obj_uuid + '.js');
	}
	var code = codemirror.getValue();
	// get template if there's no code
	if (code === "") {
		code = nwFILE.readFileSync(nwPATH.join(__dirname, "state_template.js"), 'utf8');

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
			obj_prop.code_path = nwPATH.join('state', obj_prop.name + '_' + obj_uuid + '.js');
			saveScript(true);
		}
	});
}