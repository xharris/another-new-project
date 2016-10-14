var IDE_NAME = "project";
var ZOOM_AMT = 1;
var DEV_MODE = true; // use dev_data instead of data for saving

require('electron-cookies');

var nwFILE = require('fs');
var nwPATH = require('path');
var nwPROC = require('process');
var nwCHILD = require('child_process');
var nwOS = require('os');
var nwNET = require('net');

var nwMODULES = {};
var nwMAC = require("getmac");
//var nwUA = require("universal-analytics");

var eIPC = require('electron').ipcRenderer;
var eREMOTE = require('electron').remote;
var eAPP = eREMOTE.require('electron').app;
var eSHELL = eREMOTE.require('electron').shell;
var eMENU = eREMOTE.require('electron').Menu;
var eMENUITEM = eREMOTE.require('electron').MenuItem;

var game_items = [];      

$(function(){
    /* disable eval
    window.eval = global.eval = function() {
      throw new Error("Sorry, BlankE does not support window.eval() for security reasons.");
    };
    */

    $("body").addClass(nwOS.type());

    /* title bar buttons
    $(".title-bar #btn-close").on("click", function() {
        eIPC.send('close');
    });
    $(".title-bar #btn-maximize").on("click", function() {
        eIPC.send('maximize');
    });
    $(".title-bar #btn-minimize").on("click", function() {
        eIPC.send('minimize');
    });
    */

    loadModules(function(){
        dispatchEvent("ide-ready",{});
    });
        
    // btn-add : menu for adding things to the library
    $(".btn-add").on('click', function(){
        const menu = new eMENU();
        for (var m = 0; m < game_items.length; m++) {
            menu.append(new eMENUITEM({label: game_items[m], click(item, focusedWindow) {
                b_library.add(item.label);
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

    /*
    var drop_mainwin = document.getElementById("body");
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
    */

    var args = eREMOTE.getGlobal("shareVars").args;

    if (args.length >= 3) {
        var in_file = args[2];

        handleDropFile(in_file);
    }

    $(".library .object-tree").on("dblclick",".object",function(){
        var uuid = $(this).data('uuid');
        var type = $(this).data('type');

        if (nwMODULES[type].onDblClick) {
            nwMODULES[type].onDblClick(uuid, b_library.getByUUID(type, uuid))
        }
    });

});

function handleDropFile(in_path) {
    nwFILE.lstat(in_path, function(err, stats) {
        if (!err) {
            if (stats.isDirectory()) {
                var folder_name = nwPATH.basename(in_path);

            }
            else if (stats.isSymbolicLink()) {

            }
            else if (stats.isFile()) {
                /*
                b_ide.addToast({
                    message: labels['file'] + " " + in_path,
                    can_dismiss: false,
                    timeout: 2000
                });

                b_project.reset();
                b_project.setFolder(nwPATH.dirname(in_path));
                b_editor.setFile(normalizePath(in_path));
                */
            }
        }
    });
}

function dispatchEvent(ev_name, ev_properties) {
    var new_event = new CustomEvent(ev_name, ev_properties);
    document.dispatchEvent(new_event);
}

function loadModules(callback) {
    // import module files
    nwFILE.readdir("js/modules", function(err, files) {
        for (var f = 0; f < files.length; f++) {
            var mod_name = nwPATH.basename(files[f], nwPATH.extname(files[f]));

            if (!game_items.includes(mod_name)) {
                game_items.push(mod_name);

                nwMODULES[mod_name] = require("./js/modules/" + mod_name);
                if (nwMODULES[mod_name].loaded) {
                    nwMODULES[mod_name].loaded();
                }
            }
        }
        if (callback) {
            callback();
        }
    });
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

// creates a file and it's necessary directories
function createFile() {

}
