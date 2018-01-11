StateManager = {
	_stack = {},

	iterateStateStack = function(func, ...)
		for s, state in ipairs(StateManager._stack) do
			if state[func] then state[func](...) end
		end
	end,

	clearStack = function()
		for s, state in ipairs(StateManager._stack) do
			state:_leave()
		end
		StateManager._stack = {}
	end,

	push = function(new_state)
		new_state = StateManager.verifyState(new_state)
		table.insert(StateManager._stack, new_state)
		if new_state.load and not new_state._loaded then
			new_state:load()
			new_state._loaded = true
		end
		if new_state.enter then new_state:enter() end
	end,

	pop = function()
		StateManager._stack[#StateManager._stack]:_leave()
		table.remove(StateManager._stack)
	end,

	verifyState = function(state)
		local obj_state = state
		if type(state) == 'string' then 
			if _G[state] then obj_state = _G[state] else
				error('State \"'..state..'\" does not exist')
			end
		end
		return state
	end,

	switch = function(name)
		-- verify state name
		local new_state = StateManager.verifyState(name)

		-- add to state stack
		StateManager.clearStack()
		table.insert(StateManager._stack, new_state)
		if new_state.load and not new_state._loaded then
			new_state:load()
			new_state._loaded = true
		end
		if new_state.enter then new_state:enter() end
	end,

	current = function()
		return StateManager._stack[#StateManager._stack]
	end,

	injectCallbacks = function()
		for fn_name, fn in pairs(love) do
			if BlankE[fn_name] then
				local old_fn = BlankE[fn_name]
				BlankE[fn_name] = function(...)
					StateManager.iterateStateStack(fn_name, ...)
					return old_fn(...)
				end
			end
		end	
	end
}

State = Class{
	_loaded = false,

	init = function(self)
		self.auto_update = false
		_addGameObject('state', self)
	end,

	switch = function(name)
		StateManager.switch(name)
	end,

	current = function()
		return StateManager.current()
	end,

	_leave = function(self)
		if self.leave then self:leave() end
		BlankE.clearObjects()
	end
}

return State