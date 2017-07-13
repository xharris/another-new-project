IDE = {
	projectsFolder = 'projects',

	newProject = function()
		IDE.checkProjectsFolder()
	end,

	-- make sure folder exists, create it if it doesn't
	checkProjectsFolder = function()
		if love.filesystem.exists(IDE.projectsFolder) then
			print('its there')
		else
			if not love.filesystem.createDirectory(IDE.projectsFolder) then
				print('coult not create project dir')
			end
		end
	end,	
}