var obj_uuid,
	obj_prop;

var editor_obj;

function setCodePath() {
	obj_prop.code_path = nwPATH.join('state', obj_prop.name + '_' + obj_uuid + '.' + nwENGINES[b_project.getData('engine')].file_ext);
}

function getCodePath() {
	return nwPATH.join(b_project.getResourceFolder('scripts'), obj_prop.code_path);
}

exports.libraryAdd = function(uuid, name) {
	return {
		code_path: '',
	}
}

exports.onDblClick = function(uuid, properties) {
	obj_uuid = uuid;
	obj_prop = properties;

	$(".workspace.state").append(
		"<div id='code'></div>"
	);

	editor_obj = nwPLUGINS["code_editor"].init('code', saveScript);

	loadScript(uuid);
}

exports.onClose = function(uuid) {
	saveScript();

	b_project.autoSaveProject();
}



function loadScript(uuid) {
	nwMKDIRP(nwPATH.dirname(nwPATH.dirname(getCodePath())) , function() {
		if (obj_prop.code_path === '') {
			setCodePath();

			var template_path = (nwENGINES[b_project.getData('engine')].state_template ? 
						nwENGINES[b_project.getData('engine')].state_template :
						nwPATH.join(__dirname, "state_template.js")
					)

			// get code from template
			nwFILE.readFile(template_path, 'utf8', function(err, data) {
				var code = data;
				var replacements = [
					['UUID', obj_uuid],
					['NAME', obj_prop.name]
				];

				for (var r in replacements) {
					code = code.replace(new RegExp('<'+replacements[r][0]+'>', 'g'), replacements[r][1]);
				}

				editor_obj.setValue(code);
				editor_obj.saveFile(getCodePath());
			});
		} else {
			editor_obj.openFile(getCodePath());
		}
	});
}

function saveScript(retry=false) {
	editor_obj.saveFile(getCodePath(), function(err) {
		dispatchEvent('something.saved', {what: 'state.script'});
	});
}