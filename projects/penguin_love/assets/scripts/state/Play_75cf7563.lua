--[[
	Play state code
]]--

local Play = {}

-- Called once, and only once, before entering the state the first time.
function Play:init()
	self.peng = Penguin()
end

-- Called every time when entering the state.
function Play:enter(previous)

end

function Play:leave()

end 

function Play:update(dt)

end

function Play:draw()
	self.peng:draw()
end	

return Play