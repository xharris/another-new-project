require 'includes'

function love.load()
	-- register gamestates
	Gamestate.registerEvents()
	Gamestate.switch(<FIRST_STATE>)

	Signal.emit('love.load')
end

function love.update(dt)
	Signal.emit('love.update',dt)
end

function love.draw()
	Signal.emit('love.draw')
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