b_library = {
	objects: {},

	add: function(type) {
	    if (!Object.keys(this.objects).includes(type)) {
	    	this.objects[type] = {};
	    }

	    var uuid = guid();
	    var name = type+Object.keys(this.objects[type]).length;

	    this.objects[type][uuid] = {};
        if (nwMODULES[type].libraryAdd) {
	        this.objects[type][uuid] = nwMODULES[type].libraryAdd(uuid, name);
	    }

	    // give name if it wasn't assigned
	    if (!this.objects[type][uuid].name) {
	    	this.objects[type][uuid].name = name;
	    }

	    $(".library .object-tree").append(
	    	"<div class='object' data-type='" + type + "' data-uuid='" + uuid + "'>"+
	    		this.objects[type][uuid].name+
	    	"</div>"
	    );
	},

	getByUUID: function(type, uuid) {
		return this.objects[type][uuid];
	}
}