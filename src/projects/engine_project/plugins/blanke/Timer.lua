Timer = Class{
	init = function(self, duration)
		self._before = {}					-- when Timer.start is called
		self._during = {}					-- every x seconds while timer is running
		self._after = {}					-- when the timer is over 
		self.time = 0						-- seconds
		self.duration = ifndef(duration,0)	-- seconds

		self._running = false
		self._start_time = 0

		_addGameObject('timer', self)
		return self
	end,

	-- BEFORE, EVERY, AFTER: add functions
	before = function(self, func, delay)
		table.insert(self._before,{
			func=func,
			delay=ifndef(delay,0),
			called=false,
		})
		return self
	end,

	every = function(self, func, interval)
		table.insert(self._during,{
			func=func,
			interval=ifndef(interval,1),
			last_time_ran=0
		})
		return self
	end,

	after = function(self, func, delay)
		table.insert(self._after,{
			func=func,
			delay=ifndef(delay,0),
			called=false
		})
		return self
	end,
	-- END add functions

	update = function(self, dt)
		if self._running then
			-- call BEFORE
			for b, before in ipairs(self._before) do
				if not before.called and self.time >= before.delay then
					before.func()
					before.called = true
				end
			end

			self.time = love.timer.getTime() - self._start_time

			-- call DURING
			if self.duration == 0 or self.time <= self.duration then
				local fl_time = math.floor(self.time)
				for d, during in ipairs(self._during) do
					if fl_time ~= 0 and fl_time % during.interval == 0 and during.last_time_ran ~= fl_time then
						during.func()
						during.last_time_ran = fl_time
					end
				end
			end

			if self.duration ~= 0 and self.time >= self.duration and self._running then
				-- call AFTER
				local calls_left = #self._after
				for a, after in ipairs(self._after) do
					if not after.called and self.time >= self.duration+after.delay then
						after.func()
						after.called = true
					end
					if after.called then
						calls_left = calls_left - 1
					end
				end

				if calls_left == 0 then
					self._running = false
				end
			end
		end
		return self
	end,

	start = function(self)
		if not self._running then
			self._running = true
			self._start_time = love.timer.getTime()
		end
		return self
	end,
}

return Timer