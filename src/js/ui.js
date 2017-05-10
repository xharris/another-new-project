var _last_mx = 0;
var _last_my = 0;

var b_ui = {
	/*
		values = {
			category : {
				sub-category : {
					type : {...}
					type : {...}
				}
			}
		}

		types :
			<all> : default, name
			number : min, max
			select : options[]
			bool : ...

	*/
	settingsOpen: false,

	toggleSettings : function() {
		if (b_ui.settingsOpen) {
			$(".ui-dialog-container > .ui-settings").remove();
			b_ui.settingsOpen = false;
			return;
		}
		b_ui.settingsOpen = true;

		$(".ui-dialog-container").append(
			"<div class='ui-settings'>"+
				"<div class='categories'>"+
					"<button class='category' data-type='ide'>ide</button>"+
					"<button class='category' data-type='plugins'>plugins</button>"+
					"<button class='category' data-type='engine'>"+b_project.proj_data.engine+"</button>"+
					"<button class='btn-close' onclick='b_ui.toggleSettings()'>CLOSE</button>"+
				"</div>"+
				"<div class='inputs-container'></div>"+
			"</div>"
		);

		// selecting a setting category
		$(".ui-dialog-container").on('click', '.ui-settings > .categories > .category', function(){
			var type = $(this).data('type');

			$(".ui-settings > .inputs-container").attr("data-type",type);

			var input_info;

			// loading settings for IDE
			if (type === "ide") {
				// get setting info from settings.json
				nwFILE.readFile(nwPATH.join(__dirname, "settings.json"), 'utf8', function(err, data) {
		    		if (!err) {
		    			input_info = JSON.parse(data);
		    			b_ui._populateInputs(type, input_info);
			    	}
		    	});
			} 

			// loading settings for ENGINE
			else if (type === "engine") {
				var eng_module = nwENGINES[b_project.getData('engine')];
				if ("settings" in eng_module) {
					input_info = eng_module.settings;
		    		b_ui._populateInputs(type, input_info);
				} else {
					// no settings data so just remove this button
					$(".ui-dialog-container > .ui-settings > .categories > .category[data-type='engine']").remove();
				}
			} 

			// loading settings for PLUGINS
			else if (type === "plugins") {
				var info = {};
				for (var p = 0; p < plugin_names.length; p++) {
					if (nwPLUGINS[plugin_names[p]].settings) {
						info[plugin_names[p]] = nwPLUGINS[plugin_names[p]].settings;
					}
				}

				b_ui._populateInputs(type, info);
			} else {
				$(".ui-settings > .inputs-container").attr("data-type","");
			}
		});

		$(".ui-dialog-container > .ui-settings .category[data-type='ide']").click();
	},

	_settingChange : function(type, name, value, subcategory, group) {
		var setting_type = $(".ui-settings > .inputs-container").attr("data-type");

		if (setting_type === "plugins")
			b_project.setPluginSetting(subcategory, name, value);
		else 
			b_project.setSetting(setting_type, name, value);
	},

	_populateInputs : function(type, input_info) {
		var user_set = b_project.getData('settings')[type];

		blanke.createForm(
			".ui-dialog-container > .ui-settings > .inputs-container",
			input_info,
			user_set,
			b_ui._settingChange,
			(type == "plugins")
		);
	},

	svgData: {
		"folder-outline": 'M20,18H4V8H20M20,6H12L10,4H4C2.89,4 2,4.89 2,6V18A2,2 0 0,0 4,20H20A2,2 0 0,0 22,18V8C22,6.89 21.1,6 20,6Z',
		"content-save": 'M15,9H5V5H15M12,19A3,3 0 0,1 9,16A3,3 0 0,1 12,13A3,3 0 0,1 15,16A3,3 0 0,1 12,19M17,3H5C3.89,3 3,3.9 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V7L17,3Z',
		"file-outline": 'M13,9H18.5L13,3.5V9M6,2H14L20,8V20A2,2 0 0,1 18,22H6C4.89,22 4,21.1 4,20V4C4,2.89 4.89,2 6,2M11,4H6V20H11L18,20V11H11V4Z',
		"code-tags": 'M14.6,16.6L19.2,12L14.6,7.4L16,6L22,12L16,18L14.6,16.6M9.4,16.6L4.8,12L9.4,7.4L8,6L2,12L8,18L9.4,16.6Z',
		"play": 'M8,5.14V19.14L19,12.14L8,5.14Z',
		"package-variant-closed": 'M21,16.5C21,16.88 20.79,17.21 20.47,17.38L12.57,21.82C12.41,21.94 12.21,22 12,22C11.79,22 11.59,21.94 11.43,21.82L3.53,17.38C3.21,17.21 3,16.88 3,16.5V7.5C3,7.12 3.21,6.79 3.53,6.62L11.43,2.18C11.59,2.06 11.79,2 12,2C12.21,2 12.41,2.06 12.57,2.18L20.47,6.62C20.79,6.79 21,7.12 21,7.5V16.5M12,4.15L10.11,5.22L16,8.61L17.96,7.5L12,4.15M6.04,7.5L12,10.85L13.96,9.75L8.08,6.35L6.04,7.5M5,15.91L11,19.29V12.58L5,9.21V15.91M19,15.91V9.21L13,12.58V19.29L19,15.91Z',
		"settings": 'M12,15.5A3.5,3.5 0 0,1 8.5,12A3.5,3.5 0 0,1 12,8.5A3.5,3.5 0 0,1 15.5,12A3.5,3.5 0 0,1 12,15.5M19.43,12.97C19.47,12.65 19.5,12.33 19.5,12C19.5,11.67 19.47,11.34 19.43,11L21.54,9.37C21.73,9.22 21.78,8.95 21.66,8.73L19.66,5.27C19.54,5.05 19.27,4.96 19.05,5.05L16.56,6.05C16.04,5.66 15.5,5.32 14.87,5.07L14.5,2.42C14.46,2.18 14.25,2 14,2H10C9.75,2 9.54,2.18 9.5,2.42L9.13,5.07C8.5,5.32 7.96,5.66 7.44,6.05L4.95,5.05C4.73,4.96 4.46,5.05 4.34,5.27L2.34,8.73C2.21,8.95 2.27,9.22 2.46,9.37L4.57,11C4.53,11.34 4.5,11.67 4.5,12C4.5,12.33 4.53,12.65 4.57,12.97L2.46,14.63C2.27,14.78 2.21,15.05 2.34,15.27L4.34,18.73C4.46,18.95 4.73,19.03 4.95,18.95L7.44,17.94C7.96,18.34 8.5,18.68 9.13,18.93L9.5,21.58C9.54,21.82 9.75,22 10,22H14C14.25,22 14.46,21.82 14.5,21.58L14.87,18.93C15.5,18.67 16.04,18.34 16.56,17.94L19.05,18.95C19.27,19.03 19.54,18.95 19.66,18.73L21.66,15.27C21.78,15.05 21.73,14.78 21.54,14.63L19.43,12.97Z',
		"console": 'M20,19V7H4V19H20M20,3A2,2 0 0,1 22,5V19A2,2 0 0,1 20,21H4A2,2 0 0,1 2,19V5C2,3.89 2.9,3 4,3H20M13,17V15H18V17H13M9.58,13L5.57,9H8.4L11.7,12.3C12.09,12.69 12.09,13.33 11.7,13.72L8.42,17H5.59L9.58,13Z',
		"window-minimize": 'M20,14H4V10H20',
		"window-maximize": 'M4,4H20V20H4V4M6,8V18H18V8H6Z',
		"close": 'M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z',
		"plus": 'M19,13H13V19H11V13H5V11H11V5H13V11H19V13Z',
		"folder-plus": 'M10,4L12,6H20A2,2 0 0,1 22,8V18A2,2 0 0,1 20,20H4C2.89,20 2,19.1 2,18V6C2,4.89 2.89,4 4,4H10M15,9V12H12V14H15V17H17V14H20V12H17V9H15Z',
		"minus": 'M19,13H5V11H19V13Z',

	},

	replaceSVGicons: function() {
		$("i.mdi-svg").each(function(e, el){
			var mdi_class = $(el).data("icon")
			if (b_ui.svgData[mdi_class]) {
				$(el).replaceWith(
					'<svg class="mdi-svg" viewBox="0 0 24 24"><path fill="#000000" d="'+
					b_ui.svgData[mdi_class]+
					'" /></svg>'
				);
			}
		})
	},
	createGridRipple: function(x=_last_mx, y=_last_my) {
		$("body").append("<div class='grid-ripple' style='top:"+y+"px;left:"+x+"px;'></div>");
		$("body .grid-ripple").on("animationend webkitAnimationEnd oAnimationEnd MSAnimationEnd", function(e){
		    $(this).off(e);
		    $(this).remove();
		});
	}
}

document.addEventListener('project.open', function(e) {
	b_ui.replaceSVGicons();
});

$(function(){
	$(window).on("mouseup", function(e){
		_last_mx = e.clientX;
		_last_my = e.clientY;
	});
});
