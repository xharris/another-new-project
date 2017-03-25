/*
require('codemirror/addon/edit/matchbrackets');
require('codemirror/addon/edit/closebrackets');
require('codemirror/addon/scroll/annotatescrollbar');
require('codemirror/addon/search/matchesonscrollbar');
require('codemirror/addon/search/searchcursor');
require('codemirror/addon/search/match-highlighter');

require('codemirror/addon/dialog/dialog')
require('codemirror/addon/search/search')
require('codemirror/addon/search/jump-to-line')
*/


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

	this.nwCODE = require("codemirror/lib/codemirror");
/*
	require('codemirror/addon/edit/matchbrackets');
	require('codemirror/addon/edit/closebrackets');
	require('codemirror/addon/scroll/annotatescrollbar');
	require('codemirror/addon/search/matchesonscrollbar');
	require('codemirror/addon/search/searchcursor');
	require('codemirror/addon/search/match-highlighter');

	require('codemirror/addon/dialog/dialog')
	require('codemirror/addon/search/search')
	require('codemirror/addon/search/jump-to-line')
*/
	//console.log(this.nwCODE)
	//console.log(this.nwCODE.defaults.hasOwnProperty("highlightSelectionMatches"))

	var language = nwENGINES[b_project.getData('engine')].language;
	if (language) {
		require('codemirror/mode/' + language + '/' + language);
	} else {
		language = '';
	}
	this.fontSize = b_project.getPluginSetting("code_editor", "font size");
	this.codemirror = this.nwCODE(document.getElementById(sel_id), {
		mode: language,
		lineWrapping: false,
		extraKeys: {
			'Ctrl-Space': 'autocomplete',
			'Ctrl-S': fn_saveScript,
			'Ctrl-=': function(){_this.setFontSize(_this.fontSize+1);},
			'Ctrl--': function(){_this.setFontSize(_this.fontSize-1);}
		},
		lineNumbers: true,
		theme: 'monokai',
		value: "",
		indentUnit: 4,
		highlightSelectionMatches: {showToken: /\w/, annotateScrollbar: true},
	});

	//console.log(this.codemirror)

	this.setFontSize = function(size) {
		this.fontSize = size;
		this.codemirror.display.wrapper.style.fontSize = size + "px";
		this.codemirror.refresh();
		b_project.setPluginSetting("code_editor", "font size", size);
	}
	this.setFontSize(this.fontSize)

	this.getValue = function(code) {
		if (this.codemirror)
			return this.codemirror.getValue();
	}

	this.setValue = function(code) {
		if (this.codemirror)
			this.codemirror.setValue(code);
	}

	this.openFile = function(path, callback) {
		this.file = path;
		var _this = this;
		nwFILE.readFile(path, 'utf8', function(err, data){
			if (!err)
				_this.codemirror.setValue(data);
			
			if (callback)
				callback(err);
		});
	};

	this.saveFile = function(path, callback, skipBlankCheck=false) {
		code = this.codemirror.getValue();
		var _this = this;

		if (code === "" && !skipBlankCheck) {
			console.log("blank script")
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
			var code = _this.codemirror.getValue();
			_this.codemirror.setValue(code.replaceAll(e.detail.old, e.detail.new));
		}
	});	
}


document.addEventListener('library.rename', function(e) {
	if (b_project.getPluginSetting("code_editor", "find/replace on rename")) {
		var repl_path = nwPATH.join(b_project.curr_project, 'assets', 'scripts', '**','*');

		// replace in scripts folder
		console.log('rename');
		console.log(e.detail);
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
