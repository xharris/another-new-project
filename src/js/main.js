var IDE_NAME = "project";
var ZOOM_AMT = 1;

var LIBRARY_RENAME_HOLD_TIME = 600;
var PROJECT_SAVE_TIME = 500;

require('electron-cookies');

var nwFILE = require('fs');
var nwPATH = require('path');
var nwPROC = require('process');
var nwCHILD = require('child_process');
var nwOS = require('os');
var nwNET = require('net');

var nwENGINES = {};
var nwMODULES = {};
var nwPLUGINS = {};

var nwMAC = require("getmac");
var nwMKDIRP = require("mkdirp");
var nwLESS = require("less");
var nwFILEX = require("fs-extra");
var nwOPEN = require("open");
//var nwUA = require("universal-analytics");

var eIPC = require('electron').ipcRenderer;
var eREMOTE = require('electron').remote;
var eAPP = eREMOTE.app;
var eSHELL = eREMOTE.shell;
var eMENU = eREMOTE.Menu;
var eMENUITEM = eREMOTE.MenuItem;
var eDIALOG = eREMOTE.dialog;

var game_items = []; 
var engine_names = []; 
var plugin_names = []; 
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
        const menu = new eMENU();
        for (var m = 0; m < engine_names.length; m++) {
            menu.append(new eMENUITEM({label: engine_names[m], click(item, focusedWindow) {
                eDIALOG.showSaveDialog(
                    {
                        title: "save new project",
                        defaultPath: "new_project.bip",
                        filters: [{name: 'BlankE IDE project', extensions: ['bip']}]
                    },
                    function (path) {
                        if (path) {
                            b_project.newProject(path, item.label);
                        }
                    }
                );

            }}))
        }
        menu.popup(eREMOTE.getCurrentWindow());
    });

    $(".titlebar .actionbuttons .btn-saveproject").on("click", function() {
        b_project.saveProject();
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

    loadPlugins(function(){
        dispatchEvent("ide.plugins.ready", {});
    });

    loadEngines(function(){
        dispatchEvent("ide.engines.ready",{});
    });
        
    // btn-add : menu for adding things to the library
    $(".library .actions .btn-add").on('click', function(){
        const menu = new eMENU();
        for (var m = 0; m < game_items.length; m++) {
            menu.append(new eMENUITEM({label: game_items[m], click(item, focusedWindow) {
                b_library.add(item.label, true);
            }}))
        }
        menu.popup(eREMOTE.getCurrentWindow());        
    });
    $(".library .actions .btn-folder").on('click', function(){
        b_library.addFolder();       
    });
    $(".library .actions .btn-delete").on('change', function(){
        if (this.checked) {
            lib_showDeleteBtn();
        } else {
            lib_hideDeleteBtn();
        }
    });

    $(".titlebar .gamebuttons .btn-build").on('click', function(){
        var targets = Object.keys(nwENGINES[b_project.getData('engine')].targets);

        const menu = new eMENU();
        for (var m = 0; m < targets.length; m++) {
            menu.append(new eMENUITEM({label: targets[m], click(item, focusedWindow) {
                nwENGINES[b_project.getData('engine')].targets[item.label].build(b_library.objects)
            }}))
        }
        menu.popup(eREMOTE.getCurrentWindow());
    });
    $(".titlebar .gamebuttons .btn-run").on('click', function(){
        nwENGINES[b_project.getData('engine')].run(b_library.objects)
    });
    $(".titlebar .gamebuttons .btn-settings").on('click', function(){
        b_ui.toggleSettings();
    });
    $(".titlebar .gamebuttons .btn-console").on('click', function(){
        b_console.showConsole();
    });

    $(".object-tree").on('click', '.object > .btn-delete-obj', function(e) {
        b_library.delete($(this).data('uuid'));

    }).on('click', '.folder > .btn-delete-obj', function(e) {
        if ($(this).parent().children('.children').children().length == 0) {
            $(this).parent().remove();
        }
        b_library.saveTree();

    });

    // set user id
    nwMAC.getMac(function(err, address) {
       if (!err) {
            var hash = address.hashCode();
            // analytics.userID = hash;
            // analytics.clientID = hash;
            
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
    var dragged;

    $(".library .object-tree").on("dblclick", ".object .name", function(){
        var uuid = $(this).parent(".object").data('uuid');
        var type = $(this).parent(".object").data('type');

        var module_calls = $(".workspace")[0].classList;
        for (var c in module_calls) {
            var mod = module_calls.item(c);
            if (mod !== "workspace" && nwMODULES[mod].onClose) {
                nwMODULES[mod].onClose(last_open);
            }
        }

        last_open = uuid;

        b_ide.clearWorkspace();
        $(".workspace").addClass(type);

        b_library.enableDrag();
        if (nwMODULES[type].onDblClick) {
            nwMODULES[type].onDblClick(uuid, b_library.getByUUID(type, uuid))
        }

    }).on("click", ".object .name", function(){
        var uuid = $(this).parent(".object").data('uuid');
        var type = $(this).parent(".object").data('type');

        if (nwMODULES[type].onClick) {
            nwMODULES[type].onClick(uuid, b_library.getByUUID(type, uuid))
        }

        // call select/deselect events
        $(".object-tree .object.selected").each(function(e) {
            var uuid2 = $(this).data('uuid');
            var type2 = $(this).data('type');
            dispatchEvent("library.deselect", {type: type2, uuid: uuid2, properties: b_library.getByUUID(type2, uuid2)});
        
        });

        // toggle the selected class
        $(this).parent(".object").toggleClass("selected");
        $(".object-tree .object.selected:not([data-uuid='"+uuid+"'])").removeClass("selected");

        if ($(".object-tree .object.selected").length !== 0) {
            var uuid3 = $(".object-tree .object.selected").data('uuid');
            var type3 = $(".object-tree .object.selected").data('type');
            dispatchEvent("library.select", {type: type3, uuid: uuid3, properties: b_library.getByUUID(type3, uuid3)});
        
        }

        dispatchEvent("library.click", {type: type, uuid: uuid, properties: b_library.getByUUID(type, uuid)});
        
    }).on("mouseenter", ".object .name", function(){
        var uuid = $(this).parent(".object").data('uuid');
        var type = $(this).parent(".object").data('type');

        if (nwMODULES[type].onMouseEnter) {
            nwMODULES[type].onMouseEnter(uuid, b_library.getByUUID(type, uuid))
        }

    }).on("mouseleave", ".object .name", function(){
        var uuid = $(this).parent(".object").data('uuid');
        var type = $(this).parent(".object").data('type');

        if (nwMODULES[type].onMouseLeave) {
            nwMODULES[type].onMouseLeave(uuid, b_library.getByUUID(type, uuid))
        }

    })
    .on("mousedown", ".name", function(e) {
        var target = $(e.target);
        library_timeout = setTimeout(lib_renameTimeout, LIBRARY_RENAME_HOLD_TIME, target);

    }).on('mouseup mouseleave', ".name", function() {
        clearTimeout(library_timeout);

    }).on('keyup', '.name > .in-rename', function(e) {
        e.preventDefault();
        if (e.keyCode == 13) {
            lib_objectRename(e);
        }

    }).on('blur', '.name > .in-rename', function(e) {
        lib_objectRename(e);

    }).on('dragstart', ".object,.folder:not(.object-tree)", function(e) {
        clearTimeout(library_timeout);
        dragged = $(e.target);

    }).on('drop', '.folder > .name', function(e) {
        var dragged_uuid = $(dragged).data('uuid');
        var target_uuid = $(e.target).parent().data('uuid');

        if (dragged_uuid !== target_uuid) {
            // drag object onto folder
            if ($(dragged).is(".object") && $(e.target).parent().is(".folder")) {
                var moving_el = $(dragged).detach();
                $('.object-tree .folder[data-uuid="'+target_uuid+'"] > .children').append(moving_el);
            }

            // drag folder onto folder
            if ($(dragged).is(".folder") && $(e.target).parent().is(".folder") && !$(dragged).has(".folder[data-uuid='"+target_uuid+"']").length) {
                var moving_el = $(dragged).detach();
                $('.object-tree .folder[data-uuid="'+target_uuid+'"] > .children').append(moving_el);
            }

            b_library.saveTree();
        }
        $('.object-tree .object,.object-tree .folder').removeClass('dragover');

    }).on('dragover', '.object,.folder', function(e) {
        $(e.target).parent().addClass("dragover");

    }).on('dragleave', '.object,.folder', function(e) {
        $(e.target).parent().removeClass("dragover");

    }).on('click', '.folder > .name', function(e) {
        if (!$(this).children('.in-rename').length) {
            $(this).parent().toggleClass("expanded");
            b_library.saveTree();
        }

    }).on('mouseup', '.object,.folder', function(e) {
        $('.object,.folder').removeClass('dragover');

    })


});

function lib_showDeleteBtn() {
    $(".library .actions .btn-delete").prop("checked", true)
    $(".object-tree").addClass("can-delete");
    $(".library .object, .library .folder:not(.object-tree)").each(function(){
        $(this).prepend('<button class="btn-delete-obj" data-uuid="'+$(this).data('uuid')+'"><i class="mdi mdi-minus"></i></button>');
        $(this).addClass("can-delete");
    });
}

function lib_hideDeleteBtn() {
    $(".library .actions .btn-delete").prop("checked", false)
    $(".object-tree").removeClass("can-delete");
    $(".library .object .btn-delete-obj, .library .folder .btn-delete-obj").remove();
    $(".library .object, .library .folder:not(.object-tree)").removeClass("can-delete");
}

function lib_renameTimeout(target) {
    var name = '';
    if ($(target).parent().hasClass(".object")) {
        name = b_library.getByUUID(target.parent().data('type'), target.parent().data('uuid')).name;
    } else {
        name = $(target).html();
    }

    lib_hideDeleteBtn();

    target.attr('draggable', 'false');
    target.html('<input class="in-rename" type="text" data-uuid="" value="'+name+'">');
    target.children('.in-rename')[0].select();
}

function lib_objectRename(e) {
    var e_object = $(e.target).parent().parent();
    var new_name = $(e.target).val();
    var uuid = $(e.target).parent().parent().data('uuid');

    // make thing draggable again
    e_object.attr('draggable', 'true');

    // object rename
    if ($(e_object).hasClass('object')) {
        var name = b_library.rename(uuid, new_name);

        $(e.target).parent().html(name);
    } 
    // folder rename
    else {
        $(e.target).parent().html(new_name);
    }


    b_library.saveTree();
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

function importLess(name, file, type='modules') {
    nwFILE.readFile(file, 'utf8', function(err, data) {

        if (!err) {
            nwLESS.render(data,
                {
                    paths: [nwPATH.join(__dirname,"less"),nwPATH.join(__dirname, type, name, "less")],
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

function loadPlugins(callback) {
    // import module files
    nwFILE.readdir(nwPATH.join(__dirname, "plugins"), function(err, mods) {

        mods.forEach(function(plug_name, m) {
            if (!plugin_names.includes(plug_name)) {
                plugin_names.push(plug_name);

                // import less files
                nwFILE.readdir(nwPATH.join(__dirname, "plugins", plug_name, "less"), function(err, files) {
                    if (!err) {
                        files.forEach(function(file, l) {
                            importLess(plug_name, nwPATH.join(__dirname, "plugins", plug_name, "less", file), 'plugins');

                        });
                    }
                });
                
                nwPLUGINS[plug_name] = require(nwPATH.join(__dirname, "plugins", plug_name));
                
                if (nwPLUGINS[plug_name].loaded) {
                    nwPLUGINS[plug_name].loaded();
                }
            }
        });

    });

    if (callback) {
        callback();
    }
}

function loadModules(engine, callback) {
    // import module files
    nwFILE.readdir(nwPATH.join(__dirname, "modules"), function(err, mods) {
        if (engine) {
            mods = nwENGINES[b_project.getData('engine')].modules;
        }
        mods.forEach(function(mod_name, m) {
            $(".library > .actions > .btn-add").removeAttr("disabled");
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

function loadEngines(callback) {
    // import module files
    nwFILE.readdir(nwPATH.join(__dirname, "engines"), function(err, mods) {

        mods.forEach(function(eng_name, m) {
            if (!engine_names.includes(eng_name)) {
                engine_names.push(eng_name);
                
                nwENGINES[eng_name] = require(nwPATH.join(__dirname, "engines", eng_name));
                
                if (nwENGINES[eng_name].loaded) {
                    nwENGINES[eng_name].loaded();
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

function openExternal(path) {
    eSHELL.openItem(path);
}