local entity_list = {}

local ideEntity = {
	new = function()
		local ent_name = IDE.addGameType('entity')
		HELPER.copyScript(
			SYSTEM.cwd.."/src/template/entity.lua",
			IDE.getProjectPath().."/scripts/entity/"..ent_name..".lua",
			{
				['<NAME>'] = ent_name
			}
		)
		table.insert(entity_list, ent_name)
	end,

	getObjectList = function()
		entity_list = {}
		local entity_files = love.filesystem.getDirectoryItems(IDE.getShortProjectPath()..'/scripts/entity')
		for s, entity in ipairs(entity_files) do
			local entity_name = string.gsub(entity,'.lua','')
			table.insert(entity_list, entity_name)
		end
		return entity_list
	end,

	getAssets = function()
		local ret_str = ''
		for s, entity in ipairs(entity_list) do
			ret_str = ret_str..
				entity.." = Class{__includes=Entity,classname=\'"..entity.."\'}\n"..
				"require \'scripts.entity."..entity.."\'\n"
		end
		entity_list = {}
		return ret_str..'\n'
	end,

	fileChange = function(file_name)
		if string.match(file_name, "entity/") then
			IDE._reload(file_name, true)
		end
	end,

	onRename = function(old_path, new_path)
		if not new_path:ends(".lua") then
			new_path = new_path..'.lua'
		end
		SYSTEM.rename(old_path, new_path)
	end,

	edit = function(name)
		SYSTEM.edit(IDE.getProjectPath()..'/scripts/entity/'..name..'.lua')
	end,

	draw = function()
		
	end
}

return ideEntity

