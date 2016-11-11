b_library = {
	objects: {},
	tree: {}, // used for saveTree to get library tree structure

	reset: function() {
		b_library.objects = {};
		b_library.tree = {};
	},

	add: function(type, fromMenu=false) {
	    if (!(type in this.objects)) {
	    	this.objects[type] = {};
	    }

	    var uuid = guid();
	    var name = type+Object.keys(this.objects[type]).length;

	    // call module method
        if (nwMODULES[type].libraryAdd && fromMenu) {
	        this.objects[type][uuid] = nwMODULES[type].libraryAdd(uuid, name);
	    }
	    if (this.objects[type][uuid] == 0 && fromMenu) {
	    	b_library.delete(uuid);
	    	return;
	    }

	    if (this.objects[type][uuid] == undefined) {
	    	this.objects[type][uuid] = {};
	    }
	    // give name if it wasn't assigned
	    if (!('name' in this.objects[type][uuid])) {
	    	this.objects[type][uuid].name = name;
	    }

	    $(".library .object-tree > .children").append(
	    	"<div class='object' data-type='" + type + "' data-uuid='" + uuid + "' draggable='true'>"+
	    		"<div class='name'>"+this.objects[type][uuid].name+"</div>"+
	    	"</div>"
	    );

	    b_project.setData('library', b_library.objects);
	    b_library.saveTree();

	    return this.getByUUID(type, uuid);
	},

	delete: function(uuid) {
		try {
			delete this.objects[b_library.getTypeByUUID(uuid)][uuid];
		} catch (e) {}
		$(".library .object-tree .object[data-uuid='"+uuid+"']").remove();

	    b_project.setData('library', b_library.objects);

	    b_library.saveTree();

		dispatchEvent('library.delete', {uuid: uuid});
	},

	getByUUID: function(type, uuid) {
		return this.objects[type][uuid];
	},

	getTypeByUUID: function(uuid) {
		var cat_keys = Object.keys(b_library.objects);
		for (var c = 0; c < cat_keys.length; c++) {
			var keys = Object.keys(b_library.objects[cat_keys[c]]);
			for (var o = 0; o < keys.length; o++) {
				if (keys[o] === uuid) {
					return cat_keys[c];
				}
			}
		}
	},

	// reset library object associated with this object (DEPRECATED?)
	resetHTML: function(uuid) {
		var type = b_library.getTypeByUUID(uuid);
		$(".library .object-tree .object[data-uuid='"+uuid+"']").replaceWith(
			"<div class='object' data-type='" + type + "' data-uuid='" + uuid + "' draggable='true'>"+
	    		"<div class='name'>"+this.objects[type][uuid].name+"</div>"+
	    	"</div>"
		);
	},

	rename: function(uuid, new_name) {
		var html_obj = $(".library .object-tree .object[data-uuid='"+uuid+"']");
		var type = html_obj.data('type');
		var obj = b_library.getByUUID(type, uuid);

		// check new name for validity
		if (new_name === '') {
			new_name = obj.name;
		}
		new_name = new_name.split(' ').join('_');
		// ADD: name cannot start with number or special char
		// ...

		// set 'new name'
		obj.name = new_name;

	    b_project.setData('library', b_library.objects);
		
		b_project.autoSaveProject();

		return new_name;
	},

	addFolder: function(sel_location='.library .object-tree > .children') {
		b_library.loadFolder(sel_location, guid());
		b_library.saveTree();
	},

	loadFolder: function(sel_location, uuid, name='folder') {
		console.log(sel_location)
		$(sel_location).append(
			"<div class='folder' data-uuid='"+uuid+"' draggable='true'>"+
				"<div class='name'>"+name+"</div>"+
				"<div class='children'></div>"+
			"</div>"
		);
	},

	saveTree: function() {
		b_library.tree = {};
		this._saveTree(".object-tree", b_library.tree);
		b_project.setData('tree', b_library.tree);

		b_project.autoSaveProject();

		return b_library.tree;
	},

	_saveTree: function(sel, container) {
		// folder
		if ($(sel).hasClass('folder')) {
			var uuid = $(sel).data('uuid');
			var name = $(sel+' > .name').html();
			var child_container = sel + ' > .children';

			container[uuid] = {
				name: name,
				expanded: $(sel).is('.expanded'),
				children: {}
			};

			$(child_container).children().each(function(){
				b_library._saveTree('.object-tree [data-uuid="'+$(this).data('uuid')+'"]', container[uuid].children);
			})
		} 
		// object
		else if ($(sel).hasClass('object')) {
			console.log('saving ' + $(sel).data('type'))
			container[$(sel).data('uuid')] = $(sel).data('type');
		}
		
	},

	loadTree: function(data) {
		$(".object-tree[data-uuid='0'] > .children").empty();
		b_library._loadTree(data['0'].children);
	},

	_loadTree: function(container,sel='.object-tree[data-uuid="0"] > .children') {
		for (var obj in container) {
			// folder
			if (container[obj].children)  {
				b_library.loadFolder(sel, obj, container[obj].name)
				if (container[obj].expanded)
					$(".object-tree .folder[data-uuid='"+obj+"']").addClass('expanded');
				b_library._loadTree(container[obj].children, '.object-tree .folder[data-uuid="'+obj+'"] > .children');
			}
			// object
			else {
				$(sel).append(
			    	"<div class='object' data-type='" + container[obj] + "' data-uuid='" + obj + "' draggable='true'>"+
			    		"<div class='name'>"+b_library.getByUUID(container[obj], obj).name+"</div>"+
			    	"</div>"
			    );
			}
		}
	}
}

document.addEventListener('project.open', function(e) {
	b_library.objects = ifndef(b_project.getData('library'), {});
	b_library.tree = ifndef(b_project.getData('tree'), {});

	b_library.loadTree(b_library.tree);
});	

