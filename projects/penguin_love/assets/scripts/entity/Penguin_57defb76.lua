--[[
	Penguin entity class
]]--

local assets = require "./assets"

Penguin = Class{} 

function Penguin:init()
    self.x = 100
    self.y = 100
    
	self.img_outline = assets:img_peng_outline()
    self.img_fill = assets:img_peng_fill()
    
    self.spr_outline = assets:spr_peng_outline()
    self.spr_fill = assets:spr_peng_fill()
    
    self.ani_walk = anim8.newAnimation(self.spr_outline('1-2',1), 0.1);
end

function Penguin:update(dt)
	self.spr_outline:update(dt)
    self.spr_fill:update()
end

function Penguin:draw()
	self.ani_walk:draw(self.img_fill, self.x, self.y)
    self.ani_walk:draw(self.img_outline, self.x, self.y)
end

return Penguin