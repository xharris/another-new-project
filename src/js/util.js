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
	}
}