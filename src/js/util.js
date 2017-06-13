b_util = {
	// encrypts a string
	encrypt: function(in_str) {
		var crypto = new nwCRYPT(b_project.getData("engine"));
		return crypto.encrypt(in_str);
	},

	// decrypts a string
	decrypt: function(in_str) {
		var crypto = new nwCRYPT(b_project.getData("engine"));
		return crypto.decrypt(in_str);
	},

	// lzw compression: http://almostidle.com/tutorial/javascript-string-compression
	compress: function(in_str) {
		var dict = {};
	    var data = (in_str + "").split("");
	    var out = [];
	    var currChar;
	    var phrase = data[0];
	    var code = 256;
	    for (var i=1; i<data.length; i++) {
	        currChar=data[i];
	        if (dict['_' + phrase + currChar] != null) {
	            phrase += currChar;
	        }
	        else {
	            out.push(phrase.length > 1 ? dict['_'+phrase] : phrase.charCodeAt(0));
	            dict['_' + phrase + currChar] = code;
	            code++;
	            phrase=currChar;
	        }
	    }
	    out.push(phrase.length > 1 ? dict['_'+phrase] : phrase.charCodeAt(0));
	    for (var i=0; i<out.length; i++) {
	        out[i] = String.fromCharCode(out[i]);
	    }
	    return out.join("");
	},

	decompress: function(in_str) {
	    var dict = {};
	    var data = (in_str + "").split("");
	    var currChar = data[0];
	    var oldPhrase = currChar;
	    var out = [currChar];
	    var code = 256;
	    var phrase;
	    for (var i=1; i<data.length; i++) {
	        var currCode = data[i].charCodeAt(0);
	        if (currCode < 256) {
	            phrase = data[i];
	        }
	        else {
	           phrase = dict['_'+currCode] ? dict['_'+currCode] : (oldPhrase + currChar);
	        }
	        out.push(phrase);
	        currChar = phrase.charAt(0);
	        dict['_'+code] = oldPhrase + currChar;
	        code++;
	        oldPhrase = phrase;
	    }
	    return out.join("");
	}
}