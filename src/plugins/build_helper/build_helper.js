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

exports.nonASAR = function(path) {
	return path.replace(/app.asar(.unpacked)?/,'app.asar.unpacked');
}

exports.polyMake = function(_points) {
	// https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain#JavaScript
	function cross(a, b, o) {
		return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
	}

	/**
	 * @param points An array of [X, Y] coordinates
	 */
	function convexHull(points) {
	   points.sort(function(a, b) {
	      return a[0] == b[0] ? a[1] - b[1] : a[0] - b[0];
	   });

	   var lower = [];
	   for (var i = 0; i < points.length; i++) {
	      while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], points[i]) <= 0) {
	         lower.pop();
	      }
	      lower.push(points[i]);
	   }

	   var upper = [];
	   for (var i = points.length - 1; i >= 0; i--) {
	      while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], points[i]) <= 0) {
	         upper.pop();
	      }
	      upper.push(points[i]);
	   }

	   upper.pop();
	   lower.pop();
	   return lower.concat(upper);
	}

	return convexHull(_points);
}