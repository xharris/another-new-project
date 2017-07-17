local new_entities = {}

local ideEntity = {
	new = function()
		local ent_name = IDE.addGameType('entity')
		HELPER.run('newScript', {'entity', IDE.getFullProjectFolder(), ent_name})
		table.insert(new_entities, ent_name)
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
		local ret_str = 'local asset_path = (...):match("(.-)[^%.]+$")\n\n'
		for s, state_name in ipairs(new_entities) do
			ret_str = ret_str..
				state_name.." = Class{__includes=Entity,classname=\'"..state_name.."\'}\n"..
				"require \'scripts.entity."..state_name.."\'\n"
		end
		new_entities = {}
		return ret_str:gsub('\n','\\n')..'\n'
	end,

	fileChange = function(file_name)
		if string.match(file_name, "entity") then
			IDE._reload(file_name)
		end
	end,

	edit = function(name)
		open_states[name] = true
		HELPER.run('editFile',{IDE.getFullProjectFolder()..'/scripts/entity/'..name..'.lua'})
	end,

	draw = function()

	end
}

return ideEntity

