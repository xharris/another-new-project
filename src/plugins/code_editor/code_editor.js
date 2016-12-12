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
exports.init = function(sel_id, options) {
	var codemirror = nwCODE(document.getElementById(sel_id), options);

	return codemirror;
}