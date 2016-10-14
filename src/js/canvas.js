b_canvas = {
	is_init: false,
	pGame: 0,

	init: function() {
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

		is_init = true
	},

	pPreload: function() {

		dispatchEvent("canvas.preload",{});
	},

	pCreate: function() {
		this.stage.backgroundColor = '#ffffff';
		dispatchEvent("canvas.create",{});
	},

	pUpdate: function() {

		dispatchEvent("canvas.update",{});
	},

	pRender: function() {

		dispatchEvent("canvas.render",{});
	}
}