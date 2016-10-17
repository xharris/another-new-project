b_library = {
	objects: {},
	tree: {}, // used for saveTree to get library tree structure

	add: function(type, fromMenu=false) {
	    if (!(type in this.objects)) {
	    	this.objects[type] = {};
	    }

	    var uuid = guid();
	    var name = type+Object.keys(this.objects[type]).length;

        if (nwMODULES[type].libraryAdd && fromMenu) {
	        this.objects[type][uuid] = nwMODULES[type].libraryAdd(uuid, name);
	    }

	    // give name if it wasn't assigned
	    if (this.objects[type][uuid] == undefined) {
	    	this.objects[type][uuid] = {};
	    }
	    if (!(name in this.objects[type][uuid])) {
	    	this.objects[type][uuid].name = name;
	    }

	    $(".library .object-tree").append(
	    	"<div class='object' data-type='" + type + "' data-uuid='" + uuid + "' draggable='true'>"+
	    		this.objects[type][uuid].name+
	    	"</div>"
	    );

	    b_project.setData('library', b_library.objects);
	    b_library.saveTree();

	    return this.getByUUID(type, uuid);
	},

	delete: function(type, uuid) {
		try {
			delete this.objects[type][uuid];
		} catch (e) {}
		$(".library .object-tree .object[data-uuid='"+uuid+"']").remove();

	    b_project.setData('library', b_library.objects);

		dispatchEvent('library.delete', {uuid: uuid});
	},

	getByUUID: function(type, uuid) {
		return this.objects[type][uuid];
	},

	saveTree: function() {

		this._saveTree($(".object-tree"), b_library.tree);

		console.log(b_library.tree);

		b_project.setData('tree', b_library.tree);
	},

	_saveTree: function(sel, container) {
		if ($(sel).hasClass('folder')) {
			var chil = $(sel).children();

			container[$(sel).data('name')] = {};

			for (var c = 0; c < chil.length; c++) {
				b_library._saveTree(chil[c], container[$(sel).data('name')]);
			}
		} else if ($(sel).hasClass('object')) {
			container[$(sel).data('uuid')] = $(sel).data('type');
		}

		
	},

	loadTree: function(data) {
		$(".object-tree").empty();
		b_library._loadTree($(".object-tree"), data['root']);
	},

	_loadTree: function(sel, container) {
		for (var obj in container) {
			// folder
			if (typeof container[obj] !== "string")  {
				$(sel).append("<div class='folder' data-name='" + obj + "'></div>");
				b_library._loadTree($(".object-tree [data-name='" + obj + "']"), container[obj]);
			}
			// object
			else {
				$(sel).append(
			    	"<div class='object' data-type='" + container[obj] + "' data-uuid='" + obj + "' draggable='true'>"+
			    		b_library.getByUUID(container[obj], obj).name+
			    	"</div>"
			    );
			}
		}
	}
}

document.addEventListener('project.open', function(e) {
	if (b_project.proj_data.library) {
		b_library.objects = ifndef(b_project.getData('library'), b_library.objects);
		b_library.tree = ifndef(b_project.getData('tree'), b_library.tree);

		b_library.loadTree(b_library.tree);
	}
});	

