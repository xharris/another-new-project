--[[
	<NAME> entity class
]]--

<NAME> = Class{}

function <NAME>:init()
	-- self.variable = value
	-- Signal.register('love.update', function(dt) self:update(dt) end)
	-- Signal.register('love.draw', function() self:draw() end)
end

function <NAME>:preUpdate(dt)

end

function <NAME>:postUpdate(dt)

end	

function <NAME>:preDraw()

end

function <NAME>:postDraw()

end

<NAME>:include(_Entity) 
return <NAME>