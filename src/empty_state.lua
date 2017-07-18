-- Called once, and only once, before entering the state the first time.
function _empty_state:init() end
function _empty_state:leave() end 

-- Called every time when entering the state.
function _empty_state:enter(previous)

end

function _empty_state:update(dt)

end

function _empty_state:draw()
	love.graphics.setColor(0,255,0,255)
	love.graphics.circle("line", 100, 100, 50)
end	
