var packager = require('electron-packager')
var nwOS = require('os')

var icons = {
    "Windows_NT" : "../logo.ico",
    "Darwin" : "../logo.icns"
}
var icon = icons[nwOS.type()];

packager({
	dir : ".",
	out : "../releases/",
	icon : icon,
	overwrite : true,
	asar : {
		unpackDir : "engines" //"**/{engines}"
	},
	electronVersion : "1.7.2",
	appCategoryType : "public.app-category.developer-tools"
},
function done(err, appPaths){});