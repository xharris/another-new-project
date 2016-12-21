var b_project = {
	bip_path: '',
	curr_project: '', // path to current project folder
	proj_data: {},
	autosave_on: true,

	// asks user where project should be saved and creates folder and project file
	newProject: function(bip_path, engine) {
		$(".library .object-tree > .children").empty();
		var ext = nwPATH.extname(bip_path);
		var folder_path = bip_path.replace(ext, '');
		var filename = nwPATH.basename(bip_path,ext);

		this.curr_project = folder_path;
		this.bip_path = nwPATH.join(folder_path, filename + ext);
		this.proj_data = {};

		b_library.reset();
		b_project.setData('engine', engine);

		// make dir if it doesn't exist
		nwMKDIRP(folder_path, function() {
			b_project.saveProject();
		});

		if (b_project.bip_path !== '') {
			b_ide.setHTMLattr("project-open", 1);
		} else {
			b_ide.setHTMLattr("project-open", 0);
		}

		dispatchEvent('project.new');
	},

	// asks user for location of project file and opens it
	openProject: function(bip_path) {
		this.bip_path = bip_path;
		this.curr_project = nwPATH.dirname(bip_path);

		try {
			b_project.proj_data = JSON.parse(nwFILE.readFileSync(bip_path, 'utf8'));
			b_ide.clearWorkspace();

		} catch (e) {
			b_project.proj_data = {};
			b_project.bip_path = '';
			b_project.curr_project = '';
			console.log("ERR: Can't open " + nwPATH.basename(bip_path));
		}

		if (b_project.bip_path !== '') {
			b_ide.setHTMLattr("project-open", 1);
		} else {
			b_ide.setHTMLattr("project-open", 0);
		}

		// get/set ide and engine settings
		b_project.proj_data.settings = ifndef(b_project.proj_data.settings, {});

		if (!("ide" in b_project.proj_data.settings)) {
			console.log("add em!")
			b_project.proj_data.settings["ide"] = {};
			nwFILE.readFile(nwPATH.join(__dirname, "settings.json"), 'utf8', function(err, data) {
	    		if (!err) {
	    			input_info = JSON.parse(data);
	    			b_project._populateSettings("ide", input_info);
		    	}
	    	});
		}
		if (!("engine" in b_project.proj_data.settings)) {
			b_project.proj_data.settings["engine"] = {};
			if ("settings" in nwENGINES[b_project.getData("engine")]) {
				input_info = nwENGINES[b_project.getData("engine")].settings;
				b_project._populateSettings("engine", input_info);
			}
		}


		b_ide.saveSetting("last_project_open", this.bip_path);
		dispatchEvent('project.open');
	},

	_populateSettings : function(type, input_info) {
		for (var subcat in input_info) {
			for (var i = 0; i < input_info[subcat].length; i++) {
				var input = input_info[subcat][i];
				if (!(input.name in b_project.proj_data.settings[type])) {
					b_project.setSetting(type, input.name, input.default);
				}
			}
		}
	},

	// saves project file
	saveProject: function() {
		if (b_project.isProjectOpen()) {
			nwFILE.writeFileSync(b_project.bip_path, JSON.stringify(b_project.proj_data));

			b_ide.saveSetting("last_project_open", b_project.bip_path);
			dispatchEvent('project.post-save');
			dispatchEvent('something.saved', {what: 'project'});
		}
	},

	autoSaveProject: function() {
		if (this.autosave_on) {
			save_timeout = setTimeout(b_project.saveProject, PROJECT_SAVE_TIME);
		}
	},

	// data that is saved to project file
	setData: function(key, value) {
		this.proj_data[key] = value;
		b_project.autoSaveProject();
	},

	getData: function(key) {
		return this.proj_data[key];
	},

	setSetting: function(type, key, value) {
		this.proj_data.settings[type][key] = value;
		b_project.autoSaveProject();
	},

	getSetting: function(type, key) {
		return this.proj_data.settings[type][key];
	},

	importResource: function(type, path, callback) {
		if (this.isProjectOpen()) {
			var cbCalled = false;

			nwMKDIRP(nwPATH.join(this.curr_project, 'assets', type), function() {
				var rd = nwFILE.createReadStream(path);
				rd.on("error", function(err) {
					done(err);
				});
				var wr = nwFILE.createWriteStream(nwPATH.join(b_project.curr_project, 'assets', type, nwPATH.basename(path)));
					wr.on("error", function(err) {
					done(err);
				});
				wr.on("close", function(ex) {
					done(nwPATH.join(b_project.curr_project, 'assets', type, nwPATH.basename(path)));
				});
				rd.pipe(wr);

				function done(err) {
					if (!cbCalled) {
					  callback(err);
					  cbCalled = true;
					}
					b_project.autoSaveProject();
				}
			});

		}
	},

	getResourceFolder: function(type) {
		return nwPATH.join(b_project.curr_project, 'assets', type);
	},

	copyResources: function(dest_path) {
		nwFILEX.copy(nwPATH.join(this.curr_project, 'assets'), dest_path, function (err) {
			if (err) {
				console.error(err);
			}
		});
	},

	isProjectOpen: function() {
		return this.bip_path != '';
	}
};

document.addEventListener("ide.settings.loaded", function(e) {
	b_ide.setHTMLattr("project-open", 0);
	if (b_ide.settings.last_project_open) {
		// TODO: if project file doesn't exist
		// set last_project_open to 0
		b_project.openProject(b_ide.settings.last_project_open);
	}
});