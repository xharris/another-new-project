var game = new Phaser.Game(<WIDTH>, <HEIGHT>, Phaser.<RENDERER>, 'phaser-game', {
	preload: _preload,
	create: _create
});

function _load_assets() {
	<PRELOAD>
}

function _preload() {
_load_assets();
<STATE_INIT>
}

function _create() {
	<CREATE>
}
