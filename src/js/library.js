var SAVE_TREE_TIME = 1000;
var save_tree_timeout = 0;


b_library = {
	objects: {},
	tree: {}, // used for saveTree to get library tree structure

	setBackColor: function(color) {
		// change variable in less
		document.documentElement.style.setProperty('--eng-color', color);
	},

	getBackColor: function() {
		return $("html").css("--eng-color");
	},

	randomizeBackColor: function() {
		// (300)       red,      deep purple, indigo,   blue,     cyan,     green,    yellow,   orange,   brown,    grey,      blue grey
		var colors = ['#e57373','#9575cd',    '#7986cb','#64b5f6','#4dd0e1','#81c784','#fff176','#ffb74d','#a1887f','#bdbdbd','#90a4ae'];
		
		// check if engine comes with colors
		var engine = b_project.getEngine();
		if (engine.colors) {
			colors = engine.colors;
		}

		var new_color = colors[Math.floor(Math.random()*colors.length)];
		b_library.setBackColor(new_color);
	},

	reset: function() {
		b_library.objects = {};
		b_library.tree = {};
		$(".library > .object-tree > .children").empty();
		$(".library > .constant-items").empty();
	},

	// constant item: an item that is in every project and cannot be deleted by the user
	addConstant: function(name) {
		var uuid = guid();
		$(".library > .constant-items").append(
			"<div class='item' data-uuid='"+uuid+"'>"+
				"<p class='name'>"+name+"</p>"+
			"</div>"
		);

		return ".library > .constant-items > .item[data-uuid='"+uuid+"'";
	},

	removeConstant: function(uuid) {
		$(".library > .constant-items > .item[data-uuid='"+uuid+"']").remove();
	},

	add: function(type, fromMenu=false, sel=".library .object-tree > .children") {
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
	    this.objects[type][uuid].uuid = uuid;

	    $(sel).append(
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
		try {
			return this.objects[type][uuid];
		} catch (e) {
			console.error("ERR: b_library.getByUUID('"+type+"', '"+uuid+"')");
		}
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
		var sel = ".library .object-tree .object[data-uuid='"+uuid+"']";

		var type = $(sel).data('type');
		var obj = b_library.getByUUID(type, uuid);

		var old_name = obj.name;

		// check new name for validity
		if (new_name === '') {
			new_name = obj.name;
		}
		new_name = new_name.split(' ').join('_');
		// ADD: name cannot start with number or special char
		// ...

		$(sel + " > .name").html(new_name);

		// set 'new name'
		obj.name = new_name;

		if (old_name != new_name)
			dispatchEvent('library.rename', {uuid: uuid, type: type, old: old_name, new: new_name});

	    b_project.setData('library', b_library.objects);
		b_project.autoSaveProject();

		return new_name;
	},

	addFolder: function(sel_location='.library .object-tree > .children', name=undefined) {
		var sel = b_library.loadFolder(sel_location, guid(), name);

        clearTimeout(save_tree_timeout);
        save_tree_timeout = setTimeout(b_library.saveTree, SAVE_TREE_TIME);

		return sel;
	},

	loadFolder: function(sel_location, uuid, name='folder') {
		$(sel_location).append(
			"<div class='folder' data-uuid='"+uuid+"' draggable='true'>"+
				"<div class='name'>"+name+"</div>"+
				"<div class='children'></div>"+
			"</div>"
		);
		return ".library .folder[data-uuid='"+uuid+"']";
	},

	saveTree: function() {
		b_library.tree = {};
		b_library._saveTree(".object-tree", b_library.tree);
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

			// save data 
			// ...

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
			container[$(sel).data('uuid')] = $(sel).data('type');
		}
	},

	loadTree: function(data) {
		$(".object-tree[data-uuid='0'] > .children").empty();

		if (data && data['0']) {
			b_library._loadTree(data['0'].children);
		}
	},

	_loadTree: function(container,sel='.object-tree[data-uuid="0"] > .children') {
		for (var obj in container) {
			// folder
			if (container[obj].children)  {
				b_library.loadFolder(sel, obj, container[obj].name)
				
				// add on data attributes
				// ...

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
	},

	disableDrag: function() {
		$(".object-tree .object, .object-tree .folder").attr("draggable", false);
	},

	enableDrag: function() {
		$(".object-tree .object, .object-tree .folder").attr("draggable", true);
	}
}

document.addEventListener('project.open', function(e) {
	b_library.objects = ifndef(b_project.getData('library'), {});
	b_library.tree = ifndef(b_project.getData('tree'), {});

	if (b_library.tree)
		b_library.loadTree(b_library.tree);

	b_library.randomizeBackColor();
});	

$(function(){
	$(".library").resizable({
		handles: "e",
		resize: function(event, ui){
			$("body[project-open='1'] .titlebar").css("left", ui.size.width + (parseInt($(event.target).css("padding"), 10)*2));
			$(".ui-dialog-container").css("margin-left", ui.size.width + 10);
		},
		start: function(event, ui){
			$(".library").css("transition-duration", "0s");
			$(".titlebar").css("transition-duration", "0s");
		},
		stop: function(event, ui){
			$(".library").css("transition-duration", "0.2s");
			$(".titlebar").css("transition-duration", "0.2s");
		}
	});
});