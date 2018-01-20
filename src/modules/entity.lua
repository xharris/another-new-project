local entity_list = {}

local updateListTimer
function updateEntityList()
	if not updateListTimer then
		updateListTimer = Timer()
		updateListTimer:every(updateEntityList, UI.getSetting('project_reload_timer').value):start() 
	end

	entity_list = {}
	local entity_files = SYSTEM.scandir(IDE.getProjectPath()..'/scripts/entity')
	for s, entity in ipairs(entity_files) do
		local entity_name = string.gsub(entity,'.lua','')
		table.insert(entity_list, entity_name)
	end
end

local ideEntity = {
	new = function()
		local ent_name = IDE.addGameType('entity')
		HELPER.copyScript(
			IDE.getTemplatePath().."/entity.lua",
			IDE.getProjectPath().."/scripts/entity/"..ent_name..".lua",
			{
				['<NAME>'] = ent_name
			}
		)
		table.insert(entity_list, ent_name)
	end,

	onOpenProject = function()
		updateEntityList()
	end,

	getObjectList = function()
		if not updateListTimer then updateEntityList() end
		return entity_list
	end,

	getAssets = function()
		local ret_str = ''
		for s, entity in ipairs(entity_list) do
			ret_str = ret_str.."require \'scripts.entity."..entity.."\'\n"
		end
		--entity_list = {}
		return ret_str..'\n'
	end,

	fileChange = function(file_name)
		if string.match(file_name, "entity/") then
			IDE._reload(file_name, false)
			
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

