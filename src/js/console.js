b_console = {
	showConsole : function() {
		if ($(".console > .log, .console > .error").length) {		
			$(".console").addClass("active");

			$(window).click(function() {
				$('.console').removeClass("active");
			});
			$('.console, .btn-console').click(function(event){
			    event.stopPropagation();
			});
		}
	},

	log : function(input) {
		b_console._add(input, 'log');
	},

	error : function(error) {
		b_console._add(error, 'error');
	},

	success: function(message) {
		b_console._add(message, 'success');
	},

	_add : function(message, type) {
		var id = type+"-"+guid();
		b_console.showConsole();
		$('.console').append(
			'<div class="'+type+'" id="'+id+'">'+
				'<button class="btn-close"><i class="mdi mdi-close"></i></button>'+
				'<p class="message">'+message+'</p>'+
			'</div>'
		);

		b_console.postAppend(id);
	},

	postAppend : function(id) {
		$('.console').animate({
		    scrollTop: $("#"+id).offset().top
		}, 1000);
		$(".console").on('click', '.log > .btn-close, .error > .btn-close', function(){
			$(this).parent('.log, .error').remove();
			if (!$(".console > .log, .console > .error").length) {
				$(".console").removeClass("active");
			}
		});
	}
}

