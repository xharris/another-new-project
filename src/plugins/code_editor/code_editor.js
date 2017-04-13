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
		"type" : "file",
		"name" : "external editor",
		"default" : "",
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
	}
]

var b_code = function(sel_id, fn_saveScript) {
	var _this = this;

	this.file = '';
	this.sel_id = sel_id;

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
	// autocomplete
	require("codemirror/addon/hint/show-hint.js");


	this.nwCODE.defineMode("mylanguage", function() {
	  return {token: function(stream, state) {
	    if (stream.match(/[@\w+]/)) return "variable";
	    stream.next();
	    return null;
	  }};
	});
	// Register an array of completion words for this mode
	/*
	this.nwCODE.registerHelper("hint", "blanke",
	                          ["@cat", "@dog", "@bird"]);
	this.nwCODE.registerHelper("hint", "blanke", function(){
		console.log(arguments)
	});*/


	this.editor = this.nwCODE(document.getElementById(sel_id), {
		"extraKeys" : {
			"Ctrl-Space": "autocomplete",
			"Ctrl-s" : fn_saveScript,
			"Ctrl-=" : function(){_this.setFontSize(_this.fontSize+1);},
			"Ctrl--" : function(){_this.setFontSize(_this.fontSize-1);}
		},
		highlightSelectionMatches: {showToken: /\w/, annotateScrollbar: true}
		/*,
		onKeyEvent: function (e, s) {
		    if (s.type == "keyup") {
		        _this.editor.showHint(e);
		    }
		},
		hintOptions: {
            globalScope: {
                "table1": [ "col_A", "col_B", "col_C" ],
                "table2": [ "other_columns1", "other_columns2" ]
            }
        }*/
	});

	// When an @ is typed, activate completion
	/*
	this.editor.on("inputRead", function(editor, change) {
	 	if (change.text[0] == ":") {
	 		console.log(_this.nwCODE.hint)
		    editor.showHint(_this.nwCODE.hint.blanke);
		}
	});*/

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

	this.setFontSize = function(size) {
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
		var _this = this;
		nwFILE.readFile(path, 'utf8', function(err, data){
			if (!err)
				_this.editor.setValue(data);
			
			if (callback)
				callback(err);
		});
	};

	this.saveFile = function(path, callback, skipBlankCheck=false) {
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
