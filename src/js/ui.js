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
			int : min, max
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
					"<button class='category' data-type='ide'>IDE</button>"+
					"<button class='category' data-type='engine'>"+b_project.proj_data.engine+"</button>"+
					"<button class='btn-close' onclick='b_ui.toggleSettings()'>CLOSE</button>"+
				"</div>"+
				"<div class='inputs-container'></div>"+
			"</div>"
		);
		
		// selecting a setting category
		$(".ui-dialog-container").on('click', '.ui-settings > .categories > .category', function(){
			var type = $(this).data('type');
			var inputs = b_project.proj_data[type];

			var input_info;
			if (type === "ide") {
				// get setting info from settings.json
				nwFILE.readFile(nwPATH.join(__dirname, "settings.json"), 'utf8', function(err, data) {
		    		if (!err) {
		    			input_info = JSON.parse(data);
		    			b_ui._populateInputs(type, input_info, inputs);
			    	}
		    	});
			} else if (type === "engine") {
				var eng_module = nwENGINES[b_project.getData('engine')];
				if ("settings" in eng_module) {
					input_info = eng_module.settings;
		    		b_ui._populateInputs(type, input_info, inputs);
				} else {
					// no settings data so just remove this button
					$(".ui-dialog-container > .ui-settings > .categories > .category[data-type='engine']").remove();
				}
			}

		});
	},

	_populateInputs : function(type, input_info, input_values) {
		var user_set = b_project.getData('settings')[type];

		// populate input section with inputs
		var html_inputs = '';
		for (var subcat in input_info) {
			html_inputs += "<div class='subcategory'>"+subcat+"</div>";
			for (var i = 0; i < input_info[subcat].length; i++) {
				var input = input_info[subcat][i];


				if (input.type === "bool") {
					html_inputs += 
						'<div class="ui-checkbox">'+
							'<label>'+input.name+'</label>'+
                			'<input class="settings-input" data-name="'+input.name+'" type="checkbox" '+(user_set[input.name] ? 'checked' : '')+'>'+
                			'<i class="mdi mdi-check"></i>'+
            			'</div>';
				}
			}
		}
		$(".ui-dialog-container > .ui-settings > .inputs-container").html("");
		$(".ui-dialog-container > .ui-settings > .inputs-container").html(html_inputs);
	}
}


