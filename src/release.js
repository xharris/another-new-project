var packager = require('electron-packager')
packager({
	dir : ".",
	out : "../releases/",
	icon : "../logo.icns",
	overwrite : true,
	asar : {
		unpackDir : "engines" //"**/{engines}"
	},
	electronVersion : "1.7.2",
	appCategoryType : "public.app-category.developer-tools"
},
function done(err, appPaths){});