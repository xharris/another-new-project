local _views = {}
View = Class{
	init = function (self)
		table.insert(_views, self)

		self._dt = 0

		self.camera = Camera(0, 0)
		self.follow_entity = nil
		self._last_follow_x = 0
		self._last_follow_y = 0
		self.follow_x = 0
		self.follow_y = 0
		self.smoothness = 1 

		self.speed_x = -1
		self.speed_y = -1

		Signal.register('love.update', function(dt)
			self._dt = dt
			self:update()
		end)
	end,

	-- immediately go to entity position
	goTo = function(self, entity) 
		self.follow_x = entity.x
		self.follow_y = entity.y

		self:update()
	end,	

	follow = function(self, entity)
		self.followEntity = entity

		self:update()
	end,

	_checkFollowSpeed = function(self)
		if self.speed_x == 0 then self.follow_x = self._last_follow_x end
		if self.speed_y == 0 then self.follow_y = self._last_follow_y end
	end,

	move_towards_point = function(self, x, y, fromUpdate)
		local direction = math.deg(math.atan2(y - self.follow_y, x - self.follow_x))

		if self.speed_x > 0 then
			self.follow_x = self.follow_x + (self.speed_x * math.cos(math.rad(direction))) * self._dt
		elseif self.speed_x < 0 then
			self.follow_x = x
		end

		if self.speed_y > 0 then
			self.follow_y = self.follow_y + (self.speed_y * math.sin(math.rad(direction))) * self._dt
		elseif self.speed_y < 0 then
			self.follow_y = y
		end

		-- if called from 'update', fromUpdate = dt
		if not fromUpdate then
			self:update()
		end
	end,

	update = function(self)
		if self.followEntity then
			local follow_x = self.followEntity.x
			local follow_y = self.followEntity.y

			follow_x = lerp(self.follow_x, self.followEntity.x, self.smoothness, self._dt) 
			follow_y = lerp(self.follow_y, self.followEntity.y, self.smoothness, self._dt)
			self:move_towards_point(follow_x, follow_y, true)
		end

		if self.smoothness == 0 then
			self:_checkFollowSpeed()	
		end

		-- save previous follow position
		self._last_follow_x = self.follow_x
		self._last_follow_y = self.follow_y

		self.camera:lookAt(self.follow_x, self.follow_y)
	end,

	attach = function(self)
		self.camera:attach()
	end,

	detach = function(self)
		self.camera:detach()
	end,
}

return View