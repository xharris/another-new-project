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

		b_project._setupProject();

		// make dir if it doesn't exist
		nwMKDIRP(folder_path, function() {
			b_project.saveProject();
		});

		if (b_project.bip_path !== '') {
			b_ide.setHTMLattr("project-open", 1);
		} else {
			b_ide.setHTMLattr("project-open", 0);
		}

		b_console.log("created "+nwPATH.basename(b_project.bip_path));

		dispatchEvent('project.new');
	},

	// asks user for location of project file and opens it
	openProject: function(bip_path) {
		this.bip_path = bip_path;
		this.curr_project = nwPATH.dirname(bip_path);

		b_project.proj_data.settings = ifndef(b_project.proj_data.settings, {});

		b_library.reset();
		b_ide.clearWorkspace();

		try {
			b_project.proj_data = JSON.parse(nwFILE.readFileSync(bip_path, 'utf8'));

			b_project._setupProject();

			b_project.autosave_on = b_project.proj_data.settings.ide["Autosave changes"];
			b_console.log("opened "+nwPATH.basename(bip_path));

		} catch (e) {
			b_console.error("ERR: Can't open " + nwPATH.basename(bip_path));

			b_project.proj_data = {};
			b_project.bip_path = '';
			b_project.curr_project = '';
		}

		if (b_project.bip_path !== '') {
			b_ide.setHTMLattr("project-open", 1);
		} else {
			b_ide.setHTMLattr("project-open", 0);
		}

		b_ide.saveSetting("last_project_open", this.bip_path);
		dispatchEvent('project.open');
	},

	// fill in settings/values that may be undefined
	_setupProject: function() {
		// load up engine modules
	    loadModules(b_project.getData("engine"), function(){
	        dispatchEvent("ide.ready",{});
	    });

		// add constant library items
        if ("library_const" in nwENGINES[b_project.getData("engine")]) {
        	for (var c = 0; c < nwENGINES[b_project.getData("engine")].library_const.length; c++) {
        		var info = nwENGINES[b_project.getData("engine")].library_const[c];
        		var id = b_library.addConstant(info.name);
        		
        		$(id).on('dblclick', info.dbl_click);
        	}
        }

        // get/set ide and engine settings
        b_project.proj_data.settings = ifndef(b_project.proj_data.settings, {});

		if (!b_project.getData("settings").ide) {
			b_project.proj_data.settings["ide"] = {};
			nwFILE.readFile(nwPATH.join(__dirname, "settings.json"), 'utf8', function(err, data) {
	    		if (!err) {
	    			input_info = JSON.parse(data);
	    			b_project._populateSettings("ide", input_info);
		    	}
	    	});
		}
		if (!b_project.getData("settings").engine) {
			b_project.proj_data.settings["engine"] = {};
			if ("settings" in nwENGINES[b_project.getData("engine")]) {
				input_info = nwENGINES[b_project.getData("engine")].settings;
				b_project._populateSettings("engine", input_info);
			}
		}
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
		dispatchEvent('project.setting.set', {type: type, key: key, value: value});
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

document.addEventListener("project.setting.set", function(e) {
	if (e.detail.type === "ide" && e.detail.key === "Autosave changes") {
		b_project.autosave_on = e.detail.value;

		if (e.detail.value == false) {
			console.log('here it is')
			b_project.saveProject();
		}
	}
});