function entity0:init()
	Entity.init(self,'entity0')
	
	-- self.variable = value
	-- Signal.register('love.update', function(dt) self:update(dt) end)
	-- Signal.register('love.draw', function() self:draw() end)
end

function entity0:postUpdate(dt)

end	

function entity0:postDraw()
	love.graphics.setColor(0,0,255,255)
	love.graphics.rectangle('line',self.x,self.y,32,32)
	love.graphics.resetColor()
end