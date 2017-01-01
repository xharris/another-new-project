--[[
	Penguin entity class
]]--

local assets = require "assets"

Penguin = Class{} 

function Penguin:init()
	self.img_outline = assets:img_peng_outline()
    self.img_fill = assets:img_peng_fill()
    
    self.spr_outline = assets:spr_peng_outline()
    self.spr_fill = assets:spr_peng_fill()
end

function Penguin:update(dt)

end

function Penguin:draw()

end

return Penguin