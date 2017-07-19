local entity_list = {}

local ideEntity = {
	new = function()
		local ent_name = IDE.addGameType('entity')
		HELPER.run('newScript', {'entity', IDE.getCurrentProject(), ent_name})
		table.insert(entity_list, ent_name)
	end,

	getObjectList = function()
		state_list = {}
		local state_files = love.filesystem.getDirectoryItems(IDE.current_project..'/scripts/entity')
		for s, entity in ipairs(state_files) do
			local state_name = string.gsub(entity,'.lua','')
			table.insert(state_list, state_name)
		end
		return state_list
	end,

	getAssets = function()
		local ret_str = ''
		for s, entity in ipairs(entity_list) do
			ret_str = ret_str..
				entity.." = Class{__includes=Entity,classname=\'"..entity.."\'}\n"..
				"require \'scripts.entity."..entity.."\'\n"
		end
		entity_list = {}
		return ret_str:gsub('\n','\\n')..'\n'
	end,

	fileChange = function(file_name)
		if string.match(file_name, "entity") then
			IDE._reload(file_name)
		end
	end,

	edit = function(name)
		open_states[name] = true
		HELPER.run('editFile',{IDE.getCurrentProject()..'/scripts/entity/'..name..'.lua'})
	end,

	draw = function()

	end
}

return ideEntity

