//var nwCODE = require("codemirror");
//require("codemirror/theme/monokai.css");

// sel_id : ID of the element that will hold the code editor
// options : options to pass to CodeMirror
//
// returns CodeMirror instance
exports.init = function(sel_id, fn_saveScript) {
	return new b_code(sel_id, fn_saveScript);
}

exports.settings = [
    {
		"type" : "bool",
		"name" : "use built-in editor",
		"default" : false,
	},
	{
		"type" : "bool",
		"name" : "save on close",
		"default" : false
	},
	{
		"type" : "bool",
		"name" : "find/replace on rename",
		"default" : true
	},
	{
		"type" : "number",
		"name" : "font size",
		"default" : 14,
		"min" : 1,
		"max" : 60
	},
	{
		"type" : "number",
		"name" : "tab size",
		"default" : 4,
		"min" : 0,
		"tooltip" : "The width of a tab character. (requires restart)"
	},
	{
		"type" : "number",
		"name" : "indent unit",
		"default" : 2,
		"min" : 0,
		"tooltip" : "How many spaces a block (whatever that means in the edited language) should be indented. (requires restart)"
	}
]

var b_code = function(sel_id, fn_saveScript) {
	var _this = this;

	this.file = '';
	this.sel_id = sel_id;
	this.fn_save = fn_saveScript;

	if (b_project.getPluginSetting("code_editor", "use built-in editor")) {
		// initialize ace
		this.nwCODE = require("codemirror");
		
		// match highlights
		require("codemirror/addon/scroll/annotatescrollbar.js");
		require("codemirror/addon/search/matchesonscrollbar.js");
		require("codemirror/addon/search/match-highlighter.js");
		// match brackets
		require("codemirror/addon/edit/matchbrackets.js");
		// search
		require("codemirror/addon/search/search.js");
		require("codemirror/addon/search/searchcursor.js");
		require("codemirror/addon/search/jump-to-line.js");
		require("codemirror/addon/dialog/dialog.js");

		this.editor = this.nwCODE(document.getElementById(sel_id), {
			"extraKeys" : {
				"Ctrl-Space": "autocomplete",
				"Ctrl-S" : _this.fn_save,
				"Ctrl-=" : function(){_this.setFontSize(_this.fontSize+1);},
				"Ctrl--" : function(){_this.setFontSize(_this.fontSize-1);}
			},
			highlightSelectionMatches: {annotateScrollbar: true},
			tabSize: b_project.getPluginSetting("code_editor", "tab size"),
			indentUnit: b_project.getPluginSetting("code_editor", "indent unit"),
			pollInterval: 1000
		});

		$(sel_id).addClass("no-global-font")

		// set editor settings
		this.fontSize = b_project.getPluginSetting("code_editor", "font size");

		this.editor.setOption("theme", "monokai");
		this.editor.setOption("lineNumbers", true);
		this.editor.setOption("matchBrackets", true);

		var language = nwENGINES[b_project.getData('engine')].language;
		if (language) {
			require("codemirror/mode/"+language+"/"+language+".js");
			this.editor.setOption("mode", language);
		}
	}
	
	this.setFontSize = function(size) {
		if (!this.editor) return;
		this.fontSize = size;
		document.getElementById(this.sel_id).style.fontSize = size + "px";
		this.editor.refresh();
		b_project.setPluginSetting("code_editor", "font size", size);
	}
	this.setFontSize(this.fontSize)

	this.getValue = function(code) {
		if (this.editor)
			return this.editor.getValue();
	}

	this.setValue = function(code) {
		if (this.editor)
			this.editor.setValue(code);
	}

	this.openFile = function(path, callback) {
		this.file = path;

		if (!b_project.getPluginSetting("code_editor", "use built-in editor")) {
			eSHELL.openItem(path);
		} else {
			var _this = this;
			nwFILE.readFile(path, 'utf8', function(err, data){
				if (!err)
					_this.editor.setValue(data);
				
				if (callback)
					callback(err);
			});
		}
	};

	this.saveFile = function(path, callback, skipBlankCheck=false) {
		if (!this.editor) return;
		code = this.editor.getValue();
		var _this = this;

		if (code === "" && !skipBlankCheck) {
			blanke.showModal("Last modified script was suspiciously empty (no text in it). Still save it?",{
		        "yes": function() {_this.saveFile(path, callback, true)},
		        "no": undefined
		    }); 
		} else {
			nwMKDIRP(nwPATH.dirname(path), function(){
				nwFILE.writeFile(path, code, function(err) {
					if (err) 
						b_console.error('ERR: Cannot save ' +path);

					if (callback)
						callback(err);
				});
			});
		}
	};

	document.addEventListener('library.rename', function(e) {
		if (b_project.getPluginSetting("code_editor", "find/replace on rename")) {
			// replace in currently open editor if one is open
			var code = _this.editor.getValue();
			_this.editor.setValue(code.replaceAll(e.detail.old, e.detail.new));
		}
	});	

	document.addEventListener('blanke.form.change', function(e) {
		if (e.detail.name === "font size") 
			_this.setFontSize(e.detail.value);
	});
}


document.addEventListener('library.rename', function(e) {
	if (b_project.getPluginSetting("code_editor", "find/replace on rename")) {
		var repl_path = nwPATH.join(b_project.curr_project, 'assets', 'scripts', '**','*');

		// replace in scripts folder
		nwREPLACE({
			files: repl_path,
			from: e.detail.old,
			to: e.detail.new
		}).then(changedFiles => {
			b_console.log("Replaced "+e.detail.old+
				"<i class='background-color:'>-></i>"+
				e.detail.new+" in files: " + changedFiles.join(', '));
		}).catch(error => {
			console.log('code_editor: could not rename');//b_console.error("error!")
		})
	}
});	
