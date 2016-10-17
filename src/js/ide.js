var b_ide = {
	appdata_path: '',
	setting_file: '',
	settings: {},

	setAppDataDir: function(path) {
		this.appdata_path = path;
		this.setting_file = nwPATH.join(path, "settings.json");
	},

	saveSetting: function(key, value) {
		var data = {};
		try {
        	data = JSON.parse(nwFILE.readFileSync(this.settings_file, 'utf8'));
        	data[key] = value;
        	this.settings = data;
        	nwFILE.writeFileSync(this.settings_file, JSON.stringify(data));
	    }
	    catch(e) {
	    }
	},

	loadSettings: function() {
		var data = {};

		try {
        	data = JSON.parse(nwFILE.readFileSync(this.settings_file, 'utf8'));
        	this.settings = data;
	    }
	    catch(e) {
	    }

	    if (data.last_project_open) {
	    	b_project.openProject(data.last_project_open);
	    }
	}

}