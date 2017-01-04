--[[
	Play state code
]]--

local Play = {}

-- Called once, and only once, before entering the state the first time.
function Play:init()
    
end

-- Called every time when entering the state.
function Play:enter(previous)
    love.graphics.setBackgroundColor(224, 247, 250)
	self.new_player = Player()
end

function Play:leave()

end 

function Play:update(dt)
	self.new_player:update(dt)
end

function Play:draw()
end	

return Play