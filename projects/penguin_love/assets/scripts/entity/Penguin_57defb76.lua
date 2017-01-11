--[[
	Penguin entity class
]]--

local assets = require "./assets"

function hex2rgb(hex)
    hex = hex:gsub("#","")
    return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}
end

Penguin = Class{} 

local peng_colors = {"#e57373","#9575cd","#64b5f6","#81c784","#fff176","#ffb74d","#a1887f","#e0e0e0"}

function Penguin:init(x, y)
    self.x = x
    self.y = y
    self.xscale = 1
    self.angle = 0
    self.animation = "stand"
    
    math.randomseed(os.time())
    self.color = hex2rgb(peng_colors[math.random(1,#peng_colors)])
    
	self.img_outline = assets:img_peng_outline()
    self.img_fill = assets:img_peng_fill()
    
    self.spr_outline = assets:spr_peng_outline()
    self.spr_fill = assets:spr_peng_fill()
    
    self.ani_stand = anim8.newAnimation(self.spr_outline(1, 1), 1);
    self.ani_walk = anim8.newAnimation(self.spr_outline('1-2', 1), 0.05);
    
    Signal.register('love.update', function(dt) self:update(dt) end)
    Signal.register('love.draw', function() self:draw() end)
end

function Penguin:update(dt)
    self.ani_walk:update(dt)
end

function Penguin:draw()
    love.graphics.setColor(self.color)
	if self.animation == "stand" then
    	self.ani_stand:draw(self.img_fill, self.x, self.y, math.rad(self.angle), self.xscale, 1, 16)
    elseif self.animation == "walk" then
		self.ani_walk:draw(self.img_fill, self.x, self.y, math.rad(self.angle), self.xscale, 1, 16)
    end
    
    love.graphics.setColor(255,255,255)
    if self.animation == "stand" then
    	self.ani_stand:draw(self.img_outline, self.x, self.y, math.rad(self.angle), self.xscale, 1, 16)
    elseif self.animation == "walk" then
    	self.ani_walk:draw(self.img_outline, self.x, self.y, math.rad(self.angle), self.xscale, 1, 16)
    end
end


return Penguin