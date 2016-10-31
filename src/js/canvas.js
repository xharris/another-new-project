b_canvas = {
	is_init: false,
	pGame: 0,
	module: '', // module that initiated canvas

	// supply a selector if a canvas was manually created (id MUST be main-canvas)
	init: function(module) {
		if (this.pGame) {
			b_canvas.destroy();
		}

		if (!$("#main-canvas").length) {
			$(".workspace").append("<div id='main-canvas'></div>");
		}
		b_canvas.module = module;

		this.pGame = new Phaser.Game(
			window.screen.availWidth,
			window.screen.availHeight,
			Phaser.CANVAS,
			'main-canvas',{
				preload:this.pPreload,
				create: this.pCreate,
				update: this.pUpdate,
				render: this.pRender
			}
		);

		$("#main-canvas").addClass(module);

		is_init = true
	},

	destroy: function() {
		if (this.pGame) {
			this.pGame.destroy();
			this.pGame = 0;
			b_canvas.module = '';

			$("#main-canvas").attr('class', '');

			dispatchEvent("canvas.destroy");
		}
	},

	pPreload: function() {
		if (b_canvas.module) {
			if (nwMODULES[b_canvas.module].canvas.preload) {
				nwMODULES[b_canvas.module].canvas.preload();
			}
		} else {
			dispatchEvent("canvas.preload",{});
		}
	},

	pCreate: function() {
		this.stage.backgroundColor = '#ffffff';
		if (b_canvas.module) {
			if (nwMODULES[b_canvas.module].canvas.create) {
				nwMODULES[b_canvas.module].canvas.create();
			}
		} else {
			dispatchEvent("canvas.create",{});
		}
	},

	pUpdate: function() {
		if (b_canvas.module) {
			if (nwMODULES[b_canvas.module].canvas.update) {
				nwMODULES[b_canvas.module].canvas.update();
			}
		} else {
			dispatchEvent("canvas.update",{});
		}
	},

	pRender: function() {
		if (b_canvas.module) {
			if (nwMODULES[b_canvas.module].canvas.render) {
				nwMODULES[b_canvas.module].canvas.redner();
			}
		} else {
			dispatchEvent("canvas.render",{});
		}
	}
}