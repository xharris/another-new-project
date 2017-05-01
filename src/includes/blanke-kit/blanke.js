function guid() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
    .toString(16)
    .substring(1);
}
return s4() + s4();
}

function htmlEncode(s) {
    var el = document.createElement("div");
    el.innerText = el.textContent = s;
    s = el.innerHTML;
    return s;
}

String.prototype.replaceAll = function(find, replace) {
    return str.replace(new RegExp(find, 'g'), replace);
};

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

String.prototype.addSlashes = function() 
{ 
   //no need to do (str+'') anymore because 'this' can only be a string
   return this.replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0');
} 

function dispatchEvent(ev_name, ev_properties) {
    var new_event = new CustomEvent(ev_name, {'detail': ev_properties});
    document.dispatchEvent(new_event);
}

var blanke = {
    // possible choices: yes, no (MORE TO COME LATER)
    showModal: function(html_body, choices) {
        html_actions = "";
        choice_keys = Object.keys(choices);

        // fill in action buttons
        for (var c = 0; c < choice_keys.length; c++) {
            var choice_key = choice_keys[c].toLowerCase();
            var choice_fn = choices[choice_key];

            html_actions += "<button class='ui-button-sphere' data-action='"+choice_key+"'>";
            if (choice_key == "yes") {
                html_actions += "<i class='mdi mdi-check'></i>"
            }
            if (choice_key == "no") {
                html_actions += "<i class='mdi mdi-close'></i>"
            }
            html_actions += "</button>";
        }

        // add dialog to page
        var uuid = guid();
        $("body").append(
            "<div class='ui-modal' data-uuid='"+uuid+"'>"+
                "<div class='modal-body'>"+html_body+"</div>"+
                "<div class='modal-actions'>"+html_actions+"</div>"+
            "</div>"
        );
        $("body > .ui-modal[data-uuid='"+uuid+"'] > .modal-actions > button").on('click', function(){
            $(this).parent().parent().remove();
        }); 

        // bind button events with their choice functions
        for (var c = 0; c < choice_keys.length; c++) {
            var choice_key = choice_keys[c].toLowerCase();
            var choice_fn = choices[choice_key];

            $("body > .ui-modal[data-uuid='"+uuid+"'] > .modal-actions > button[data-action='" + choice_key + "']").on('click', choice_fn);
        }
    },

    // selector_parent: selector for where to put the form inputs
    // input_info: inputs template (type, default, ...)
    // user_val: the curret values of the inputs. can be blank object {}
    // fn_onChange: called when an input value changes. args: type, name, value, subcategory
    createForm: function(selector_parent, input_info, user_val, fn_onChange, grouped=false) {
        // populate input section with inputs
        var html_inputs = '';
        for (var subcat in input_info) {
            html_inputs += "<div class='subcategory'><p class='title'>"+subcat.replace("_"," ")+"</p>";

            // get smaller group (for plugins atm)
            if (grouped) {
                user_val = user_val[subcat];
            }

            for (var i = 0; i < input_info[subcat].length; i++) {
                var input = input_info[subcat][i];

                if (!(input.name in user_val)) {
                    user_val[input.name] = input.default;
                }

                var common_attr = ' data-subcategory="'+subcat+'" data-name="'+input.name+'" data-type="'+input.type+'" title="'+ifndef(input.tooltip, "")+'"';
                
                // remove [hidden_name]
                var display_name = input.name.replace(/\[([^\]]+)\]/g,'');

                if (input.type === "bool") {
                    html_inputs += 
                        '<div class="ui-checkbox-label">'+
                            '<label>'+display_name+'</label>'+
                            '<input class="settings-input" type="checkbox" '+common_attr+' '+(user_val[input.name] == "true" || user_val[input.name] == true ? 'checked' : '')+'>'+
                            '<i class="mdi mdi-check"></i>'+
                        '</div>';
                }
                if (input.type === "number") {
                    html_inputs += 
                        '<div class="ui-input-group">'+
                            '<label>'+display_name+'</label>'+
                            '<input class="ui-input" '+common_attr+' type="number" min="'+input.min+'" max="'+input.max+'" step="'+input.step+'" value="'+user_val[input.name]+'">'+
                        '</div>';
                }
                if (input.type === "select") {
                    var options = '';
                    for (var o = 0; o < input.options.length; o++) {
                        options += "<option value='"+input.options[o]+"' "+(input.options[o] === user_val[input.name] ? 'selected' : '')+">"+input.options[o]+"</option>";
                    }
                    html_inputs +=
                        '<div class="ui-input-group">'+
                            '<label>'+display_name+'</label>'+
                            '<select class="ui-select" '+common_attr+'>'+
                                options+
                            '</select>'+
                        '</div>';
                }
                if (input.type === "file") {
                    html_inputs +=
                        '<div class="ui-file">'+
                            '<label>'+display_name+'</label>'+
                            '<button class="ui-button-rect" onclick="'+
                                escapeHtml('chooseFile(\'\',function(path){$(\'input[data-name=\"'+input.name+'\"\').val(path[0]).trigger(\'change\');})')+
                            '">Choose file</button>'+
                            '<input disabled '+common_attr+' type="text" value="'+user_val[input.name]+'">'+
                        '</div>'
                }
                if (input.type === "text" || input.type === "password") {
                    var value = user_val[input.name];

                    // decrypt password
                    if (input.type === "password")
                        value = b_util.decrypt(value)

                    html_inputs +=
                        '<div class="ui-text">'+
                            '<label>'+display_name+'</label>'+
                            '<input '+common_attr+' type="'+input.type+'" value="'+value+'">'+
                        '</div>'
                }
                if (input.type === "button") {
                    if (input.shape == "rectangle") {
                        html_inputs +=
                            '<br>'+
                            '<button class="ui-button-rect" onclick="'+input.function+'">'+display_name+'</button>'+
                            '<br>';
                    }
                }
            } // for-loop

            html_inputs += "</div>";
        }

        $(selector_parent).html("");
        $(selector_parent).html(html_inputs);

        // bind input change events
        $(selector_parent).off('change', 'input,select');
        $(selector_parent).on('change', 'input,select', function(){
            var type = $(this).data("type"); // bool, number, password
            var name = $(this).data("name"); // x, y, width, jump_power, etc...
            var value = $(this).val(); // 3, 1.4, true, ****
            var subcat = $(this).data("subcategory");
            var group = $(this).data("group");

            if (type === "bool")
                value = $(this).is(':checked') ? true : false;
            if (type === "number") 
                value = parseFloat(value);
            // encrypt password
            if (type === "password")
                value = b_util.encrypt(value);

            dispatchEvent("blanke.form.change", {type: type, name: name, value: value, subcategory: subcat, group: group});
            if (fn_onChange) 
                fn_onChange(type, name, value, subcat, group);
        });
    },

    extractDefaults: function(settings) {
        var ret_parameters = {};

        // fill in parameters with default values of audio_settings
        var categories = Object.keys(settings);
        for (var c = 0; c < categories.length; c++) {
            var setting;
            ret_parameters[categories[c]] = {};
            for (var s = 0; s < settings[categories[c]].length; s++) {
                setting = settings[categories[c]][s];
                if (typeof setting.default != "object")
                    ret_parameters[setting.name] = setting.default;
            }
        }

        return ret_parameters;
    }
}