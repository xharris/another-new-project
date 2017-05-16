var nwZIP = require("archiver")
var nwDOWN = require('download');

exports.copyScript = function(src, dest, replacements, cb_done) {
	nwFILE.readFile(src, 'utf8', function(err, data) {
		if (!err) {
			for (var r = 0; r < replacements.length; r++) {
				data = data.replaceAll(replacements[r][0],replacements[r][1]);
			}
			nwFILE.writeFile(dest, data, function(err) {
				if (cb_done)
					cb_done(err); 
			});
		} else {
			b_console.error(err);
		}
	});
}

exports.zip = function(src, dest, call_done, call_err) {
	nwMKDIRP(nwPATH.dirname(dest), function() {
		var output = nwFILE.createWriteStream(dest);
		var archive = nwZIP('zip', {
			store: true
		})

		// callbacks
		if (call_done) {
			output.on('close', call_done);
		}
		if (call_err) {
			archive.on('error', call_err);
		}

		// do the zipping
		archive.pipe(output);
		archive.directory(nwPATH.join(src,''), '');
		archive.finalize();
	});
}

// http://stackoverflow.com/questions/11944932/how-to-download-a-file-with-node-js-without-using-third-party-libraries
exports.download = function(url, dest, callback) {
	nwDOWN(url).then(function(data){
		nwFILE.writeFile(dest, data, callback);
	});
}