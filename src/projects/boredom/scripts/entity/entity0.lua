BlankE.addClassType("entity0", "Entity")

function entity0:init()
	-- ANIMATION
	self:addAnimation{
		name = 'stand',
		image = 'player_stand'
	}
	self:addAnimation{
		name = 'walk',
		image = 'player_walk',
		offset = {0, 1},
		frames = {'1-2', 1},
		frame_size = {34/2,33}
	}

	-- HITBOX	self.sprite_index = 'stand'

	self:addShape(
		"main",
		"rectangle",
		{0,0,21,32}
	)

	-- INPUT
	self.k_left = Input('left', 'a')
	self.k_right = Input('right', 'd')
	self.k_jump = Input('up', 'w')
end

function entity0:update(dt)
	self.onCollision['main'] = function(other, sep_vector)
		--if other.tag
	end

	self.sprite_xoffset = -self.sprite_width/2
	self.sprite_yoffset = -self.sprite_height/2

	-- left/right movement
	if self.k_left() and not self.k_right() then
		self.hspeed = -125
		self.sprite_index = 'walk'
		self.sprite_xscale = -1
	end
	if self.k_right() and not self.k_left() then
		self.hspeed = 125
		self.sprite_index = 'walk'
		self.sprite_xscale = 1
	end
	if not self.k_left() and not self.k_right() then
		self.hspeed = 0
		self.sprite_index = 'stand'
	end


end	  