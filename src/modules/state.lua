local new_states = {}
local state_list = {}
local open_states = {}

local ideState = {
	new = function()
		local state_name = IDE.addGameType('state')
		HELPER.run('newScript', {'state', IDE.getFullProjectFolder(), state_name})
		table.insert(new_states, state_name)
	end,

	getObjectList = function()
		state_list = {}
		local state_files = love.filesystem.getDirectoryItems(IDE.current_project..'/scripts/state')
		for s, state in ipairs(state_files) do
			local state_name = string.gsub(state,'.lua','')
			table.insert(state_list, state_name)
		end
		return state_list
	end,

	getAssets = function()
		local ret_str = 'local asset_path = (...):match("(.-)[^%.]+$")\n\n'
		local first_state = true
		for s, state_name in ipairs(new_states) do
			ret_str = ret_str..
				state_name.." = Class{classname=\'"..state_name.."\'}\n"..
				"require \'scripts.state."..state_name.."\'\n"

			if first_state then
				first_state = state_name
				ret_str = ret_str .. '_FIRST_STATE = '..first_state..'\n'
			end
		end
		new_states = {}
		return ret_str:gsub('\n','\\n')..'\n'
	end,

	fileChange = function(file_name)
		if string.match(file_name, "state") then
			IDE._reload(file_name)
			if string.match(file_name, Gamestate.current().classname) then
				Gamestate.switch(_G[Gamestate.current().classname])
			end
		end
	end,

	edit = function(name)
		open_states[name] = true
		HELPER.run('editFile',{IDE.getFullProjectFolder()..'/scripts/state/'..name..'.lua'})
	end,

	draw = function()
	--[[
		for state, val in pairs(open_states) do
			if open_states[state] then
				imgui.SetNextWindowSize(300,300,"FirstUseEver")
				status, open_states[state] = imgui.Begin(state, true)



				imgui.End()
			end
		end
	]]--
	end
}

return ideState

