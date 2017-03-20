var b_ide = {
	appdata_path: '',
	setting_file: '',
	settings: {},

	setAppDataDir: function(path) {
		b_ide.appdata_path = path;
		b_ide.setting_file = nwPATH.join(path, "settings.json");
	},

	saveSetting: function(key, value) {
		try {
        	b_ide.settings[key] = value;

        	nwFILE.writeFileSync(b_ide.setting_file, JSON.stringify(b_ide.settings));
	    }
	    catch(e) {
	    }
	},

	loadSettings: function() {
    	nwFILE.readFile(b_ide.setting_file, 'utf8', function(err, data) {
    		if (!err) {
	    		b_ide.settings = JSON.parse(data);
	    		dispatchEvent("ide.settings.loaded");
	    	}
    	});

	},

	setHTMLattr: function(key, value) {
		$("body").attr(key, value);
	},

	clearWorkspace: function() {
        $(".workspace").empty();
        $(".workspace")[0].className = "workspace";
	},

	setTitle: function(title) {
		$('head > title').html('BlankE :: ' + title)
	},

	setProgress: function(amount) {
		$(".titlebar > .progress-bar").css("width", amount + "%");
	}
}