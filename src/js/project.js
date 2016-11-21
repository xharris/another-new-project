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

			// if not type OBJECT, set it 
			// ...

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

		b_ide.saveSetting("last_project_open", this.bip_path);
		dispatchEvent('project.open');
	},

	// saves project file
	saveProject: function() {
		if (this.isProjectOpen()) {
			nwFILE.writeFileSync(this.bip_path, JSON.stringify(this.proj_data));

			b_ide.saveSetting("last_project_open", this.bip_path);
			dispatchEvent('project.post-save');
		}
	},

	autoSaveProject: function() {
		if (this.autosave_on) {
			this.saveProject();
		}
	},

	// data that is saved to project file
	setData: function(key, value) {
		this.proj_data[key] = value;
	},

	getData: function(key) {
		return this.proj_data[key];
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
			} else {
				console.log("success!");
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