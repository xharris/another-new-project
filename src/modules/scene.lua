local ideScene = {
	new = function()
		local scene_name = IDE.addGameType('scene')
		HELPER.run('newScript', {'scene', IDE.getCurrentProject(), scene_name})
		table.insert(new_entities, scene_name)
	end
}

return {}