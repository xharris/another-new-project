b_library = {
	objects: {},

	add: function(type) {
	    if (!Object.keys(this.objects).includes(type)) {
	    	this.objects[type] = {};
	    }

	    var uuid = guid();

	    this.objects[type][uuid] = {};
        if (nwMODULES[type].libraryAdd) {
	        this.objects[type][uuid] = nwMODULES[type].libraryAdd(uuid, type+Object.keys(this.objects[type]).length);
	    }

	    $(".library .object-tree").append(
	    	"<div class='object " + type + "' data-uuid='" + uuid + "'>"+
	    		this.objects[type][uuid].name+
	    	"</div>"
	    );
	}
}