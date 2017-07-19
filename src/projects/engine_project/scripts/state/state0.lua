-- Called once, and only once, before entering the state the first time.
function state0:init() end
function state0:leave() end 

-- Called every time when entering the state.
function state0:enter(previous)

end

function state0:update(dt)

end

function state0:draw()
	love.graphics.setColor(255,0,0,255)
	love.graphics.print("hey there", 100,100)
end	