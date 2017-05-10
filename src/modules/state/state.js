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

	setCodePath();

	b_ui.openCodeEditor({
		uuid: uuid,
		type: 'state',
		properties: properties,
		editor: { 
			file_path: getCodePath(), 
			template_path: (nwENGINES[b_project.getData('engine')].state_template ? 
										nwENGINES[b_project.getData('engine')].state_template :
										nwPATH.join(__dirname, "state_template.js")
							),
			template_replacements: [
				['UUID', obj_uuid],
				['NAME', obj_prop.name]
			]
		}
	});
}

