Signal = require 'plugins.hump.signal'
Gamestate = require 'plugins.hump.gamestate'
Class = require 'plugins.hump.class'
Timer = require 'plugins.hump.timer'
Vector = require 'plugins.hump.vector'
Camera = require 'plugins.hump.camera'
anim8 = require 'plugins.anim8'

assets = require 'assets'

<IMAGES_DECLARE>
<SPRITES_DECLARE>

<INCLUDES>

function love.load()
	<IMAGES>
	<SPRITES>

	-- register gamestates
	Gamestate.registerEvents()
	Gamestate.switch(<FIRST_STATE>)

	Signal.emit('love.load')
end

function love.update(dt)
	Signal.emit('love.update',dt)
end

function love.draw()
	Signal.emit('love.render')
end

function love.mousepressed(x, y, button, istouch)
	Signal.emit('love.mousepressed', x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
	Signal.emit('love.mousereleased', x, y, button, istouch)
end

function love.keypressed(key)
	Signal.emit('love.keypressed', key)
end

function love.keyreleased(key)
	Signal.emit('love.keyreleased', key)
end

function love.focus(f)
	Signal.emit('love.focus', f)
end

function love.quit()
	Signal.emit('love.quit')
end