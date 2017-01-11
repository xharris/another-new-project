var game = new Phaser.Game(800, 600, Phaser.AUTO, 'phaser-game', {
	preload: _preload,
	create: _create
});

function _load_assets() {
	
}

function _preload() {
_load_assets();
	game.state.add('state0', state0);
	game.state.start('state0');
}

function _create() {
	
}
