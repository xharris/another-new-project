local new_states = {}
local state_list = {}
local open_states = {} -- probably don't need this anymore

_empty_state = {classname='_empty_state'}
require ('empty_state')
_FIRST_STATE = _empty_state

local updateListTimer
function updateStateList()
	state_list = {}
	local state_files = SYSTEM.scandir(IDE.getProjectPath()..'/scripts/state')
	for s, state in ipairs(state_files) do
		local state_name = string.gsub(state,'.lua','')
		table.insert(state_list, state_name)
	end
end

local ideState = {
	new = function()
		local state_name = IDE.addGameType('state')
		HELPER.copyScript(
			IDE.getTemplatePath().."/state.lua",
			IDE.getProjectPath().."/scripts/state/"..state_name..".lua",
			{
				['<NAME>'] = state_name
			}
		)
		table.insert(new_states, state_name)
	end,

	getObjectList = function()
		if not updateListTimer then
			updateStateList()
			updateListTimer = Timer()
			updateListTimer:every(updateStateList, UI.getSetting('project_reload_timer').value):start() 
		end
		return state_list
	end,

	getAssets = function()
		local ret_str = ''
		local first_state = UI.getSetting('initial_state')
		for s, state_name in ipairs(state_list) do
			ret_str = ret_str..
				state_name.." = Class{classname=\'"..state_name.."\'}\n"..
				"require \'scripts.state."..state_name.."\'\n"

			if first_state == '' then
				first_state = state_name
				UI.setSetting('initial_state', first_state)
			end
		end

		if first_state ~= '' then
			ret_str = ret_str .. '_FIRST_STATE = '..first_state..'\n'
		end
		state_list = {}
		return ret_str..'\n'
	end,

	onReload = function()
		if #state_list > 0 then
			_FIRST_STATE = UI.getSetting('initial_state')
		end
	end,

	fileChange = function(file_name)
		if string.match(file_name, "state/") then
			IDE._reload(file_name, not string.match(file_name, ifndef(_FIRST_STATE.classname, _FIRST_STATE)))

			local curr_state = BlankE.getCurrentState()
			if string.match(file_name, curr_state) then
				IDE.try(State.switch, _G[curr_state])
			end
		end
	end,

	edit = function(name)
		open_states[name] = true 
		
		if UI.getSetting("builtin_code_editor") then
			IDE.plugins['code_editor'].editCode(IDE.getProjectPath()..'/scripts/state/'..name..'.lua')
		else
			SYSTEM.edit(IDE.getProjectPath()..'/scripts/state/'..name..'.lua')
		end
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

