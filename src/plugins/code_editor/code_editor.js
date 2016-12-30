require('codemirror/addon/edit/matchbrackets');
require('codemirror/addon/edit/closebrackets');

require('codemirror/mode/xml/xml');
require('codemirror/mode/javascript/javascript');
require('codemirror/mode/css/css');
require('codemirror/mode/htmlmixed/htmlmixed');

var nwCODE = require("codemirror/lib/codemirror");

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
	}
]

var b_code = function(sel_id, fn_saveScript) {
	this.file = '';

	this.codemirror = nwCODE(document.getElementById(sel_id), {
		mode: 'javascript',
		lineWrapping: false,
		extraKeys: {
			'Ctrl-Space': 'autocomplete',
			'Ctrl-S': fn_saveScript
		},
		lineNumbers: true,
		theme: 'monokai',
		value: "",
		indentUnit: 4
	});

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
			else {
				nwFILE.writeFile(path, '', function(err){
					_this.openFile(path);
				})
			}

			if (callback)
				callback(err);
		});
	};

	this.saveFile = function(path, callback) {
		code = this.codemirror.getValue();

		nwFILE.writeFile(path, code, function(err) {
			if (err) 
				b_console.error('ERR: Cannot save ' +path);

			if (callback)
				callback(err);
		});
	};
}