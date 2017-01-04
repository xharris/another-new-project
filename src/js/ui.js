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
			if (type === "ide") {
				// get setting info from settings.json
				nwFILE.readFile(nwPATH.join(__dirname, "settings.json"), 'utf8', function(err, data) {
		    		if (!err) {
		    			input_info = JSON.parse(data);
		    			b_ui._populateInputs(type, input_info);
			    	}
		    	});
			} else if (type === "engine") {
				var eng_module = nwENGINES[b_project.getData('engine')];
				if ("settings" in eng_module) {
					input_info = eng_module.settings;
		    		b_ui._populateInputs(type, input_info);
				} else {
					// no settings data so just remove this button
					$(".ui-dialog-container > .ui-settings > .categories > .category[data-type='engine']").remove();
				}
			} else if (type === "plugins") {
				var info = {};
				for (var p = 0; p < plugin_names.length; p++) {
					if ("settings" in nwPLUGINS[plugin_names[p]]) {
						info[plugin_names[p]] = nwPLUGINS[plugin_names[p]].settings;
					}
				}

				b_ui._populateInputs(type, info);
			} else {
				$(".ui-settings > .inputs-container").attr("data-type","");
			}

			$(".ui-dialog-container > .ui-settings > .inputs-container").on('change', 'input,select', function(){	
				var setting_type = $(".ui-settings > .inputs-container").attr("data-type");
				var type = $(this).data("type");
				var name = $(this).data("name");
				var value = $(this).val();
				var subcat = $(this).data("subcategory");

				if (type === "bool")
					value = $(this).is(':checked');
				if (type === "number") 
					value = parseInt(value);

				if (setting_type === "plugins")
					b_project.setPluginSetting(subcat, name, value);
				else 
					b_project.setSetting(setting_type, name, value);
			});
		});

		$(".ui-dialog-container > .ui-settings .category[data-type='ide']").click();
	},

	_populateInputs : function(type, input_info) {
		var user_set = b_project.getData('settings')[type]; 

		// populate input section with inputs
		var html_inputs = '';
		for (var subcat in input_info) {
			html_inputs += "<div class='subcategory'>"+subcat.replace("_"," ")+"</div>";
			for (var i = 0; i < input_info[subcat].length; i++) {
				var input = input_info[subcat][i];

				if (type === "plugins") {
					user_set = b_project.getData('settings')[type]; 
					user_set = user_set[subcat];
				}

				if (!(input.name in user_set)) {
					user_set[input.name] = input.default;
				}

				var common_attr = ' data-subcategory="'+subcat+'" data-name="'+input.name+'" data-type="'+input.type+'" ';

				console.log(input.name + ' ' + user_set[input.name])

				if (input.type === "bool") {
					html_inputs += 
						'<div class="ui-checkbox">'+
							'<label>'+input.name+'</label>'+
                			'<input class="settings-input" type="checkbox" '+common_attr+' '+(user_set[input.name] === true ? 'checked' : '')+'>'+
                			'<i class="mdi mdi-check"></i>'+
            			'</div>';
				}
				if (input.type === "number") {
					html_inputs += 
						'<div class="ui-input-group">'+
							'<label>'+input.name+'</label>'+
							'<input class="ui-input" '+common_attr+' type="number" min="'+input.min+'" max="'+input.max+'" value="'+user_set[input.name]+'">'+
						'</div>';
				}
				if (input.type === "select") {
					var options = '';
					for (var o = 0; o < input.options.length; o++) {
						options += "<option value='"+input.options[o]+"' "+(input.options[o] === user_set[input.name] ? 'selected' : '')+">"+input.options[o]+"</option>";
					}
					html_inputs +=
						'<div class="ui-input-group">'+
							'<label>'+input.name+'</label>'+
							'<select class="ui-select" '+common_attr+'>'+
								options+
							'</select>'+
						'</div>';
				}
				if (input.type === "file") {
					html_inputs +=
						'<div class="ui-file">'+
							'<label>'+input.name+'</label>'+
							'<button class="ui-button-rect" onclick="'+
								escapeHtml('chooseFile(\'\',function(path){$(\'input[data-name=\"'+input.name+'\"\').val(path[0]).trigger(\'change\');})')+
							'">Choose file</button>'+
							'<input disabled '+common_attr+' type="text" value="'+user_set[input.name]+'">'+
						'</div>'
				}
				if (input.type === "text") {
					html_inputs +=
						'<div class="ui-text">'+
							'<label>'+input.name+'</label>'+
							'<input '+common_attr+' type="text" value="'+user_set[input.name]+'">'+
						'</div>'
				}
				if (input.type === "button") {
					if (input.shape == "rectangle") {
						html_inputs +=
							'<br>'+
							'<button class="ui-button-rect" onclick="'+input.function+'">'+input.name+'</button>'+
							'<br>';
					}
				}
			}
		}
		$(".ui-dialog-container > .ui-settings > .inputs-container").html("");
		$(".ui-dialog-container > .ui-settings > .inputs-container").html(html_inputs);

	}
}


