var obj_uuid,
	obj_prop;

var editor_obj;

function setCodePath() {
	obj_prop.code_path = nwPATH.join('entity', obj_prop.name + '_' + obj_uuid + '.' + nwENGINES[b_project.getData('engine')].file_ext);
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

	if (b_project.getPluginSetting("code_editor", "use built-in editor")) {
		var win_sel = blanke.createWindow({
	        x: 210, 
	        y: 50,
	        width: 550,
	        height: 350,
	        class: 'entity.code',
	        title: properties.name,
	        html: "<div id='code'></div>",
	        onClose: function(){
	        	editor_obj.triggerClose();
	        }
		});
	}
	
	editor_obj = nwPLUGINS['code_editor'].init({
		id: 'code', 
		file_path: getCodePath(), 
		template_path: (nwENGINES[b_project.getData('engine')].entity_template ? 
									nwENGINES[b_project.getData('engine')].entity_template :
									nwPATH.join(__dirname, "entity_template.js")
						),
		template_replacements: [
			['UUID', obj_uuid],
			['NAME', obj_prop.name]
		]
	});
}
