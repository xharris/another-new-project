var IDE_NAME = "project";
var ZOOM_AMT = 1;
var DEV_MODE = true; // use dev_data instead of data for saving

var LIBRARY_RENAME_HOLD_TIME = 600;

require('electron-cookies');

var nwFILE = require('fs');
var nwPATH = require('path');
var nwPROC = require('process');
var nwCHILD = require('child_process');
var nwOS = require('os');
var nwNET = require('net');

var nwMODULES = {};
var nwMAC = require("getmac");
var nwMKDIRP = require("mkdirp");
var nwLESS = require("less");
//var nwUA = require("universal-analytics");

var eIPC = require('electron').ipcRenderer;
var eREMOTE = require('electron').remote;
var eAPP = eREMOTE.app;
var eSHELL = eREMOTE.shell;
var eMENU = eREMOTE.Menu;
var eMENUITEM = eREMOTE.MenuItem;
var eDIALOG = eREMOTE.dialog;

var game_items = [];   
var last_open;   

$(function(){
    /* disable eval
    window.eval = global.eval = function() {
      throw new Error("Sorry, BlankE does not support window.eval() for security reasons.");
    };
    */
    b_ide.setAppDataDir(eAPP.getPath('userData'));
    b_ide.loadSettings();

    $("body").addClass(nwOS.type());

    // title bar buttons
    $(".titlebar .actionbuttons .btn-newproject").on("click", function() {
        eDIALOG.showSaveDialog(
            {
                title: "save new project",
                defaultPath: "new_project.bip",
                filters: [{name: 'BlankE IDE project', extensions: ['bip']}]
            },
            function (path) {
                if (path) {
                    b_project.newProject(path);
                }
            }
        );
    });
    $(".titlebar .actionbuttons .btn-openproject").on("click", function() {
        eDIALOG.showOpenDialog(
            {
                title: "open project",
                properties: ["openFile"],
                filters: [{name: 'BlankE IDE project', extensions: ['bip']}]
            },
            function (path) {
                if (path) {
                    console.log(path)
                    b_project.openProject(path[0]);
                }
            }
        );
    });

    $(".titlebar .titlebuttons .btn-close").on("click", function() {
        eIPC.send('close');
    });
    $(".titlebar .titlebuttons .btn-maximize").on("click", function() {
        eIPC.send('maximize');
    });
    $(".titlebar .titlebuttons .btn-minimize").on("click", function() {
        eIPC.send('minimize');
    });

    loadModules(function(){
        dispatchEvent("ide.ready",{});
    });
        
    // btn-add : menu for adding things to the library
    $(".btn-add").on('click', function(){
        const menu = new eMENU();
        for (var m = 0; m < game_items.length; m++) {
            menu.append(new eMENUITEM({label: game_items[m], click(item, focusedWindow) {
                b_library.add(item.label, true);
            }}))
        }
        menu.popup(eREMOTE.getCurrentWindow());        
    });

    // set user id
    nwMAC.getMac(function(err, address) {
       if (!err && !DEV_MODE) {
            var hash = address.hashCode();
        //   analytics.userID = hash;
        //   analytics.clientID = hash;
            
            console.log("userID: " + hash);
       }
    });

    //analytics.event('UI', 'initialize', 'main_window', '');

    // set events for window close
    eIPC.on('window-close', function(event) {
        // b_ide.saveData();
        eIPC.send('confirm-window-close');
    });

    var drop_mainwin = $("body")[0];
	drop_mainwin.ondragover = () => {
        // console.log(e.dataTransfer.files);
		if ($(".filedrop-overlay").hasClass("inactive")) {
			//$(".filedrop-overlay").removeClass("inactive");
		}
		return false;
	};
	drop_mainwin.ondragleave = drop_mainwin.ondragend = () => {
		//$(".filedrop-overlay").addClass("inactive");
		return false;
	};
	drop_mainwin.ondrop = (e) => {
		e.preventDefault();

		for (var f of e.dataTransfer.files) {
			var in_path = f.path;

            handleDropFile(in_path);

		}
		$(".filedrop-overlay").addClass("inactive");
		return false;
	};

    var args = eREMOTE.getGlobal("shareVars").args;

    if (args.length >= 3) {
        var in_file = args[2];

        handleDropFile(in_file);
    }

    var library_timeout = 0;

    $(".library .object-tree").on("dblclick",".object",function(){
        var uuid = $(this).data('uuid');
        var type = $(this).data('type');

        var module_calls = $(".workspace")[0].classList;
        for (var c in module_calls) {
            var mod = module_calls.item(c);
            if (mod !== "workspace" && nwMODULES[mod].onClose) {
                nwMODULES[mod].onClose(last_open);
            }
        }

        last_open = uuid;

        $(".workspace").empty();
        $(".workspace")[0].className = "workspace";
        $(".workspace").addClass(type);

        if (nwMODULES[type].onDblClick) {
            nwMODULES[type].onDblClick(uuid, b_library.getByUUID(type, uuid))
        }

    }).on("click", ".object", function(){
        var uuid = $(this).data('uuid');
        var type = $(this).data('type');

        if (nwMODULES[type].onClick) {
            nwMODULES[type].onClick(uuid, b_library.getByUUID(type, uuid))
        }

        dispatchEvent("library.click", {type: type, uuid: uuid, properties: b_library.getByUUID(type, uuid)});
        
    }).on("mouseenter", ".object", function(){
        var uuid = $(this).data('uuid');
        var type = $(this).data('type');

        if (nwMODULES[type].onMouseEnter) {
            nwMODULES[type].onMouseEnter(uuid, b_library.getByUUID(type, uuid))
        }

    }).on("mouseleave", ".object", function(){
        var uuid = $(this).data('uuid');
        var type = $(this).data('type');

        if (nwMODULES[type].onMouseLeave) {
            nwMODULES[type].onMouseLeave(uuid, b_library.getByUUID(type, uuid))
        }

    })
    .on("mousedown", ".object", function(e) {
        var target = $(e.target);

        library_timeout = setTimeout(lib_renameTimeout, LIBRARY_RENAME_HOLD_TIME, target);
    }).on('mouseup mouseleave dragstart', ".object", function() {
        clearTimeout(library_timeout);
    }).on('keyup', '.object .in-rename', function(e) {
        e.preventDefault();
        if (e.keyCode == 13) {
            lib_objectRename(e);
        }
    }).on('blur', '.object .in-rename', function(e) {
        lib_objectRename(e);
    });

});

function lib_renameTimeout(target) {
    var name = b_library.getByUUID(target.data('type'), target.data('uuid')).name;

    target.attr('draggable', 'false');
    target.html('<input class="in-rename" type="text" data-uuid="" value="'+name+'">');
    target.children('.in-rename')[0].select()
}

function lib_objectRename(e) {
    var e_object = $(e.target).parent();

    // rename object
    var name = b_library.rename(e_object.data('uuid'), $(e.target).val());

    // make thing draggable again
    e_object.attr('draggable', 'true');
    e_object.html(name);
}

function handleDropFile(in_path) {
    nwFILE.lstat(in_path, function(err, stats) {
        if (!err) {
            dispatchEvent("filedrop", {path:in_path, stats:stats});

            if (stats.isDirectory()) {
                var folder_name = nwPATH.basename(in_path);

            }
            else if (stats.isSymbolicLink()) {

            }
            else if (stats.isFile()) {

            }
        }
    });
}

function dispatchEvent(ev_name, ev_properties) {
    var new_event = new CustomEvent(ev_name, {'detail': ev_properties});
    document.dispatchEvent(new_event);
}

function importLess(module, file) {
    nwFILE.readFile(file, 'utf8', function(err, data) {

        if (!err) {
            nwLESS.render(data,
                {
                    paths: [nwPATH.join(__dirname,"less"),nwPATH.join(__dirname, "modules", module, "less")],
                },
                function (e, output) {
                    var head  = document.getElementsByTagName('head')[0];
                    var link  = document.createElement('style');
                    link.id   = file.hashCode();
                    link.rel  = 'stylesheet';
                    link.type = 'text/css';
                    link.media = 'all';
                    $(link).html(output.css);
                    head.appendChild(link);
                });
        }
    });
}

function callModuleFn(type, fn_name) {
    if (nwMODULES[type][fn_name]) {
        nwMODULES[type][fn_name]();
    }
}

function loadModules(callback) {
    // import module files
    nwFILE.readdir(nwPATH.join(__dirname, "modules"), function(err, mods) {

        mods.forEach(function(mod_name, m) {
            // import less files
            nwFILE.readdir(nwPATH.join(__dirname, "modules", mod_name, "less"), function(err, files) {
                if (!err) {
                    files.forEach(function(file, l) {

                        importLess(mod_name, nwPATH.join(__dirname, "modules", mod_name, "less", file));

                    });
                }
            });

            if (!game_items.includes(mod_name)) {
                game_items.push(mod_name);
                
                nwMODULES[mod_name] = require(nwPATH.join(__dirname, "modules", mod_name));
                if (nwMODULES[mod_name].loaded) {
                    nwMODULES[mod_name].loaded();
                }
            }
        });

    });

    if (callback) {
        callback();
    }
}

function normalizePath(path) {
    return path.replace(/(\/|\\)/g, '/');
}

function escapeHtml(text) {
  return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
}


function chooseFile(path, callback) {
    eIPC.send('open-file-dialog');
    eIPC.on('selected-directory', function (event, path) {
        callback(path);
    })
}

function guid() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
  }
  return s4() + s4();
}

String.prototype.hashCode = function(){
	var hash = 0;
	if (this.length == 0) return hash;
	for (i = 0; i < this.length; i++) {
		char = this.charCodeAt(i);
		hash = ((hash<<5)-hash)+char;
		hash = hash & hash; // Convert to 32bit integer
	}
	return Math.abs(hash).toString();
}

function copyObj(obj) {
    return JSON.parse(JSON.stringify(obj));
}

function shortenPath(path, length) {
    var path_parts = path.split(/[/]|[\\]/g);
    if (path_parts.length > length) {
        return nwPATH.normalize(path_parts.splice(path_parts.length - length, length).join(nwPATH.sep));
    } else {
        return path;
    }
}

function fillSelect(selector, values, selected_value, capitalize=true) {
    var html = '';
    for (var i = 0; i < values.length; i++) {
        var selected = '';
        if (values[i] === selected_value) {
            selected = ' selected ';
        }
        var new_val = values[i];
        if (capitalize) {
            var new_val = values[i].charAt(0).toUpperCase() + values[i].slice(1);
        }
        html += "<option value='" + values[i] + "'" + selected + ">" + new_val + "</option>";
    }
    $(selector).html(html);
}

Array.prototype.includesMulti = function(arr){
    var is_there = false;
    this.map(function(val) {
        is_there = (arr.includes(val));
    });
    return is_there;
}

function obj_assign(obj, prop, value) {
    if (typeof prop === "string")
        prop = prop.split(".");

    if (prop.length > 1) {
        var e = prop.shift();
        obj_assign(obj[e] =
                 Object.prototype.toString.call(obj[e]) === "[object Object]"
                 ? obj[e]
                 : {},
               prop,
               value);
    } else
        obj[prop[0]] = value;
}

function parseXML(str) {
    parser = new DOMParser();
    xmlDoc = parser.parseFromString(str, "text/xml");
    return xmlDoc;
}

function ifndef(value, default_value) {
    return (typeof value === 'undefined') ? default_value : value;
}