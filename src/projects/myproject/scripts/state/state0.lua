-- Called once, and only once, before entering the state the first time.
function state0:init() end
function state0:leave() end 

local offset = 0

-- Called every time when entering the state.
function state0:enter(previous)
	print('entering')
end

function state0:update(dt)

end

function state0:draw()
	love.graphics.setColor(255,0,0)
	love.graphics.circle('fill', 100, 100, sinusoidal(50, 300, 0.5))

	IDE.draw()
end	