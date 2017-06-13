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
		
		refreshModuleMenu();

		b_console.log("created "+nwPATH.basename(b_project.bip_path));

		dispatchEvent('project.new', {path: b_project.bip_path});
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

			b_ide.setTitle(nwPATH.basename(bip_path));

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

		nwFILE.watch(b_project.getResourceFolder(''), {'persistent':true, 'recursive':true}, function(action, file){
			dispatchEvent('assets.modified', {'action':action, 'file':file});
		});

        refreshModuleMenu();

		dispatchEvent('project.open', {path: b_project.bip_path});
	},

	// fill in settings/values that may be undefined
	_setupProject: function() {

		nwMKDIRP(nwPATH.join(b_project.curr_project, 'assets'));

		// load up engine modules
	    loadModules(b_project.getEngine(), function(){
	        dispatchEvent("ide.ready",{});
	    });

		// add constant library items (exports.library_const)
        if ("library_const" in nwENGINES[b_project.getData("engine")]) {
        	for (var c = 0; c < nwENGINES[b_project.getData("engine")].library_const.length; c++) {
        		var info = nwENGINES[b_project.getData("engine")].library_const[c];
        		var id = b_library.addConstant(info.name);
        		$(id).on('dblclick', info.dbl_click);
        	}
        }

        // get/set IDE and ENGINE settings
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

		// get/set PLUGIN settings
		if (!b_project.getData("settings").plugins) {
			b_project.proj_data.settings["plugins"] = {};
			for (var p = 0; p < plugin_names.length; p++) {
				if ("settings" in nwPLUGINS[plugin_names[p]]) {
					input_info = nwPLUGINS[plugin_names[p]].settings;
					b_project._populateSettings("plugins", input_info, plugin_names[p]);
				}
			}
		}
	},
    
    // get project name (not path)
    getName : function() {
        return nwPATH.basename(b_project.bip_path)
    },

	_populateSettings : function(type, input_info, plugin_name="") {
		if (type === "plugins") {
			b_project.proj_data.settings[type][plugin_name] = ifndef(b_project.proj_data.settings[type][plugin_name], {});

			for (var i = 0; i < input_info.length; i++) {
				var input = input_info[i];

				if (!(input.name in b_project.proj_data.settings[type][plugin_name])) {
					b_project.setPluginSetting(plugin_name, input.name, input.default);
				}
			}

		} else {
			for (var cat in input_info) {
				for (var i = 0; i < input_info[cat].length; i++) {
					var input = input_info[cat][i];
					if (!(input.name in b_project.proj_data.settings[type])) {
						b_project.setSetting(type, input.name, input.default);
					}
				}
			}
		}
	},

	// saves project file
	saveProject: function() {
		if (b_project.isProjectOpen()) {
            b_ui.createGridRipple();
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

	getEngine: function() {
		return nwENGINES[b_project.getData('engine')]
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

	setPluginSetting: function(plugin, key, value) {
		this.proj_data.settings.plugins[plugin][key] = value;
		dispatchEvent('plugin.setting.set', {plugin: plugin, key: key, value: value});
		b_project.autoSaveProject();
	},

	getPluginSetting: function(plugin, key) {
		return this.proj_data.settings.plugins[plugin][key];
	},

	importResource: function(type, path, callback) {
		if (this.isProjectOpen()) {
			var cbCalled = false;

			nwMKDIRP(b_project.getResourceFolder(type), function() {
				var rd = nwFILE.createReadStream(path);
				rd.on("error", function(err) {
					done(err);
				});
				var wr = nwFILE.createWriteStream(nwPATH.join(b_project.getResourceFolder(type), nwPATH.basename(path)));
					wr.on("error", function(err) {
					done(err);
				});
				wr.on("close", function(ex) {
					done(nwPATH.join(b_project.getResourceFolder(type), nwPATH.basename(path)));
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

	// TODO: replace new resources
	copyResources: function(dest_path) {
		nwFILEX.copy(nwPATH.join(this.curr_project, 'assets'), dest_path, function (err) {
			if (err) {
				//console.error(err);
			}
		});
	},

	isProjectOpen: function() {
		return this.bip_path != '';
	},

	openProjectDir : function() {
		if (b_project.isProjectOpen()) {
			eSHELL.openItem(nwPATH.dirname(this.bip_path));
		}
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
			b_project.saveProject();
		}
	}
});