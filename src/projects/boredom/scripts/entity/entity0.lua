BlankE.addClassType("entity0", "Entity")

function entity0:init()
	self.show_debug = true
	self.walk_speed = 180
	self.gravity = 30
	self.can_jump = true
    self.jump_power = 700

	-- ANIMATION
	self:addAnimation{
		name = 'stand',
		image = 'player_stand'
	}
	self:addAnimation{
		name = 'walk',
		image = 'player_walk',
		offset = {0, 0},
		frames = {'1-2', 1},
		frame_size = {34/2,33},
		speed = .05
	}
	self.sprite_index = 'walk'

	-- HITBOX	self.sprite_index = 'stand'
	self:addShape("main", "rectangle", {0,0,21,32})
	self:addShape("jump_box", "rectangle", {4, 30, 12, 2})
	self:setMainShape("main")

	-- INPUT
	self.k_left = Input('left', 'a')
	self.k_right = Input('right', 'd')
	self.k_jump = Input('up', 'w')
end

function entity0:update(dt)
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
            self.can_jump = true 
        	self:collisionStopY()
        end 
    end

	self.sprite_xoffset = -self.sprite_width/2
	self.sprite_yoffset = -self.sprite_height/2

	-- left/right movement
	if self.k_left() and not self.k_right() then
		self.hspeed = -self.walk_speed
		self.sprite_index = 'walk'
		self.sprite_xscale = -1
	end
	if self.k_right() and not self.k_left() then
		self.hspeed = self.walk_speed
		self.sprite_index = 'walk'
		self.sprite_xscale = 1
	end
	if not self.k_left() and not self.k_right() then
		self.hspeed = 0
		self.sprite_index = 'stand'
	end

	-- jumping
	if self.k_jump() then
		self:jump()
	end
end	  

function entity0:jump()
	if self.can_jump then
        self.vspeed = -self.jump_power
        self.can_jump = false
    end	
end