local new_states = {}
local state_list = {}
local open_states = {} -- probably don't need this anymore

--[[
_empty_state = {classname='_empty_state'}
require ('empty_state')
_FIRST_STATE = _empty_state
]]

local updateListTimer
function updateStateList()
	if not updateListTimer then
		updateListTimer = Timer()
		updateListTimer.persistent = true
		updateListTimer:every(updateStateList, UI.getSetting('project_reload_timer').value):start() 
	end

	state_list = {}
	local state_files = SYSTEM.scandir(IDE.getProjectPath()..'/scripts/state')
	for s, state in ipairs(state_files) do
		local state_name = string.gsub(state,'.lua','')
		table.insert(state_list, state_name)
	end
	checkFirstState()
end

function checkFirstState()
	local first_state = UI.getSetting('initial_state')
	for s, state_name in ipairs(state_list) do
		if first_state == '' or first_state == nil then
			first_state = state_name
			UI.setSetting('initial_state', first_state)
		end
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

	onOpenProject = function()
		UI.setSetting("initial_state", '')
		updateStateList()
	end,

	getObjectList = function()
		if not updateListTimer then updateStateList() end
		return state_list
	end,

	getAssets = function()
		local ret_str = ''
		checkFirstState()
		local first_state = UI.getSetting('initial_state')
		for s, state_name in ipairs(state_list) do
			ret_str = ret_str.."require \'scripts.state."..state_name.."\'\n"
		end
		return ret_str..'\n'
	end,

	onReload = function()

	end,

	fileChange = function(file_name)
		if string.match(file_name, "state/") then
			local first_state = UI.getSetting('initial_state')
			IDE._reload(file_name, not string.match(file_name, ifndef(first_state.classname, first_state)))

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

