local ideScene = {
	new = function()
		local scene_name = IDE.addGameType('scene')
		HELPER.run('newScript', {'scene', IDE.getFullProjectFolder(), scene_name})
		table.insert(new_entities, scene_name)
	end
}

return {}