local new_states = {}

local ideState = {
	new = function()
		local state_name = IDE.addGameType('state')
		HELPER.run('newScript', {'state', IDE.getFullProjectFolder(), state_name})
		table.insert(new_states, state_name)
	end,

	getAssets = function()
		local ret_str = 'local asset_path = (...):match("(.-)[^%.]+$")\n\n'
		local first_state = true
		for s, state_name in ipairs(new_states) do
			if first_state then
				first_state = state_name
			end
			ret_str = ret_str..
				state_name.." = Class{__includes=State,__tostring = function(self) return self.classsname end,classname=\'"..state_name.."}\'\n"..
				"require \'scripts.state."..state_name.."\'\n"
		end
		ret_str = ret_str .. '_FIRST_STATE = '..state_name..'\n'	
		new_states = {}
		return ret_str:gsub('\n','\\n')..'\n'
	end,

	draw = function()

	end
}

return ideState

