--[[
	state0 state code
]]--

local state0 = {}

-- Called once, and only once, before entering the state the first time.
function state0:init()
	self.ent = entity0()
end

-- Called every time when entering the state.
function state0:enter(previous)

end

function state0:leave()

end 

function state0:update(dt)

end

function state0:draw()
	self.ent:draw()
end	

return state0