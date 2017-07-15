local ideEntity = {
	new = function()
		HELPER.run('newScript', {'entity', IDE.getFullProjectFolder(), IDE.addGameType('entity')})
	end,

	draw = function()

	end
}

return ideEntity

