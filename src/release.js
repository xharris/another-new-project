var packager = require('electron-packager')
packager({
	dir : ".",
	asar : {
		unpackDir : "**/{engines}"
	},
	electronVersion : "1.7.2"
},
function done(err, appPaths){});