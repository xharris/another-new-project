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
    }
}