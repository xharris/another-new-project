var game = new Phaser.Game(800, 600, Phaser.AUTO, 'phaser-game', {
	preload: _preload,
	create: _create
});

function _preload() {
	game.load.image('image0', 'assets/image/player_walk.png');
	game.load.spritesheet('spritesheet0', 'assets/image/player_walk.png', 17, 33, -1, 0, 0);


	game.state.add('state0', state0);
	game.state.start('state0');
}

function _create() {
	
}
