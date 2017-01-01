exports.copyScript = function(src, dest, replacements, cb_done) {
	nwFILE.readFile(src, 'utf8', function(err, data) {
		if (!err) {
			for (var r in replacements) {
				data = data.replace(replacements[r][0],replacements[r][1]);
			}
			nwFILE.writeFile(dest, data, function(err) {
				if (cb_done)
					cb_done(err); 
			});
		}
	});
}