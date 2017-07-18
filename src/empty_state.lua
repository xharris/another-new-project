-- Called once, and only once, before entering the state the first time.
function _empty_state:init() end
function _empty_state:leave() end 

local offset = 0

-- Called every time when entering the state.
function _empty_state:enter(previous)
	print('entering')
end

function _empty_state:update(dt)

end

function _empty_state:draw()
	love.graphics.setColor(0,255,0)
	love.graphics.circle('fill', 100, 100, sinusoidal(50, 300, 0.5))

	IDE.draw()
end	
