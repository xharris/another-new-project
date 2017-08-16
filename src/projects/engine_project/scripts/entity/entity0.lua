local k_left 
local k_right
local k_up 

function entity0:init(x, y)
	Entity.init(self,'entity0')

	self.x = x
    self.y = y
    
    self:addAnimation{
        name="walk",
        image="penguin",
        frames={'1-2', 1},
        frame_size={32,32},
        speed=0.4
    }
    self:setSpriteIndex("walk")
    self.sprite_xoffset = self.sprite_width/2
    self.sprite_yoffset = self.sprite_height/2

    
    self:addShape("main", "rectangle", {0, 0, 32, 32})
    self:addShape("jump_box", "rectangle", {4, 30, 24, 2})
    self:setMainShape("main")
        
    self.friction = 0.05
    self.gravity_direction = 90
    self.gravity = 5
    
    self.move_speed = 125    
    self.can_jump = true
    self.jump_power = 330
    
    self.k_left = Input('left','a')
    self.k_right = Input('right','d')
    self.k_up = Input('up','w')
end 

function entity0:jump()
    if self.can_jump then
        self.vspeed = -self.jump_power
        self.can_jump = false
    end
end

function entity0:preUpdate(dt)
    self.onCollision["main"] = function(other, sep_vector)
        if other.tag == "ground" then
            -- ceiling collision
            if sep_vector.y > 0 and self.vspeed < 0 then
                self:collisionStopY()
            end
            -- horizontal collision
            if math.abs(sep_vector.x) > 0 then
                self:collisionStopX() 
            end
        end
    end
    
    self.onCollision["jump_box"] = function(other, sep_vector)
        if other.tag == "ground" and sep_vector.y < 0 then
                -- floor collision
            if not self.can_jump and self.nickname == 'player' then
                Signal.emit('jump')
            end
            self.can_jump = true 
        self:collisionStopY()
        end 
    end

    -- horizontal movement
    if self.k_right() or self.k_left() then
        if self.k_left() then
        self.hspeed = -self.move_speed    
        end
        if self.k_right() then
           self.hspeed = self.move_speed 
        end
    else
        self.hspeed = 0 
    end
    
    -- jumping
    if self.k_up() then
        self:jump()
    end	
end	
