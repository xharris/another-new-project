--[[
	Player entity class
]]--

Player = Class{} 

function Player:init()
    self.x = 150
    self.y = 100
    
	self.penguin = Penguin(self.x, self.y)
    self.body = HC.circle(self.x, self.y, 12)
    self.feet = HC.rectangle(self.x + 10, self.y, 10, 8)
    
    self.rect = {
    	HC.rectangle(100, 100, 20, 100),
        HC.rectangle(100, 200, 120, 20),
        HC.rectangle(200, 160, 20, 40)
    }
    
    
    self.dx = 2
    self.dy = 0
    self.gravity = 0
    self.GRAVITY = 5
    self.can_jump = false
    
    HC.register(self.body)
    
    for ir, r in pairs(self.rect) do 
    	 r.type = "ground"
       	 HC.register(r)
    end
    
    Signal.register('love.keypressed', function(key) self:keypressed(key) end)
	Signal.register('love.draw', function() self:draw() end)
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
        self.dy = -4
        self.can_jump = false
    end
       
   	-- gravity    
    self.dy = self.dy + (self.gravity * dt)
    
    self.feet:moveTo(self.x, self.y + 34 + self.dy)
    
    for other, seperating_vector in pairs(body_collisions) do
        if other.type == "ground" then
    		self.body:move(seperating_vector.x, seperating_vector.y)
        end
        
        self_left, self_top, self_right, self_bottom = self.body:bbox()
        other_left, other_top, other_right, other_bottom = other:bbox()
        if other.type == "ground" and other_top >= self_bottom then
            self.dy = 0
            self.gravity = 0
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
    -- draw penguin hitbox
    love.graphics.setColor(255,0,0)
    love.graphics.print(tostring(self.gravity) .. " " .. tostring(self.dy) .. " " .. tostring(self.can_jump), 20, 20)
    self.body:draw('line')
    self.feet:draw('line')
    
    for ir, r in pairs(self.rect) do 
       	 r:draw("fill")
    end
    love.graphics.setColor(255,255,255)
    
    if love.keyboard.isDown("left") then
        self.penguin.xscale = -1
    end
    if love.keyboard.isDown("right") then
    	self.penguin.xscale = 1
    end
    
    self.penguin.x = self.x
    self.penguin.y = self.y
end

return Player