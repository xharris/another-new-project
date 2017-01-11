--[[
	Player entity class
]]--

Player = Class{} 

function Player:init()
    self.x = 150
    self.y = 100
    self.angle = 0
    
    self.debug = false
    
	self.penguin = Penguin(self.x, self.y)
    self.body = HC.circle(self.x, self.y, 12)
    self.feet = HC.rectangle(self.x + 10, self.y, 10, 8)
    
    self.dx = 2
    self.jump_power = 5
    self.GRAVITY = 8.5
    
    self.dy = 0
    self.gravity = 0
    self.can_jump = false
    
    HC.register(self.body)
        
    Signal.register('love.keypressed', function(key) self:keypressed(key) end)
	--Signal.register('love.draw', function() self:draw() end)
end

function Player:keypressed(key)

end

function Player:update(dt)
    local body_collisions = HC.collisions(self.body)
    local feet_collisions = HC.collisions(self.feet)
    
    -- left/right movement
    if love.keyboard.isDown("left") then
        self.body:move(-self.dx, 0)
    end
    if love.keyboard.isDown("right") then
        self.body:move(self.dx, 0)
    end
    
    -- jumping
    if love.keyboard.isDown("up") and self.can_jump then
        self.dy = -self.jump_power
        self.can_jump = false
    end
       
   	-- gravity    
    self.dy = self.dy + (self.gravity * dt)
    
    self.feet:moveTo(self.x, self.y + 34 + self.dy)
    
    -- colliding with ground
    for other, seperating_vector in pairs(body_collisions) do
        if other.type == "ground" then
    		self.body:move(seperating_vector.x, seperating_vector.y)
        end
        
        self_left, self_top, self_right, self_bottom = self.body:bbox()
        other_left, other_top, other_right, other_bottom = other:bbox()
        if other.type == "ground" then
            if other_top >= self_bottom then
                self.dy = 0
                self.gravity = 0
            elseif other_bottom <= self_top then
               	self.dy = 0 
            end
        else
           self.gravity = self.GRAVITY 
        end
    end	
    
    for other, seperating_vector in pairs(feet_collisions) do
        if other.type == "ground" and math.abs(self.dy) < 1 then
           self.can_jump = true 
        end
    end
    
    self.body:move(0, self.dy)
	self.x, self.y = self.body:center()
    
    
    self.y = self.y - 20
end

function Player:draw()
    if self.debug then
        -- draw penguin hitbox
        love.graphics.setColor(255,0,0)
        love.graphics.print(tostring(self.gravity) .. " " .. tostring(self.dy) .. " " .. tostring(self.can_jump), 20, 20)
        self.body:draw('line')
        self.feet:draw('line')
        love.graphics.setColor(255,255,255)
    end
    
    if love.keyboard.isDown("left") then
        self.penguin.xscale = -1
    end
    if love.keyboard.isDown("right") then
    	self.penguin.xscale = 1
    end
    
    self.penguin.x = love.graphics.getWidth()/2--self.x
    self.penguin.y = love.graphics.getHeight()/2--self.y
    self.penguin.angle = self.angle
end

return Player