--[[
	entity0 entity class
]]--
local assets = require "assets"

entity0 = Class{} 

function entity0:init()
	self.img = assets:image0()
	self.spr = assets:spritesheet0()
	self.ani_walk = anim8.newAnimation(self.spr('1-2',1), 0.1)
	-- self.variable = value
	-- Signal.register('update', self.update)
	-- Signal.register('draw', self.draw)
end

function entity0:update(dt)
	self.spr:update(dt)
end

function entity0:draw()
	love.graphics.print("Hello World", 400, 300)
	self.ani_walk:draw(self.img, 400, 300);
end

return entity0