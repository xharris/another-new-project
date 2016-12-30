var game = new Phaser.Game(800, 600, Phaser.AUTO, 'phaser-game', {
	preload: _preload,
	create: _create
});

function _load_assets() {
		game.load.image('coin', 'assets/image/coin.png');
	game.load.image('wall', 'assets/image/wall.png');
	game.load.image('player', 'assets/image/player.png');
	game.load.image('enemy', 'assets/image/enemy.png');

}

function _preload() {
_load_assets();
	game.state.add('mainState', mainState);
	game.state.start('mainState');
}

function _create() {
	
}
