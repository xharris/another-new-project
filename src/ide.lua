IDE = {
	projectsFolder = 'projects',

	newProject = function()
		IDE.checkProjectsFolder()
	end,

	-- make sure folder exists, create it if it doesn't
	checkProjectsFolder = function()
		print('hey there')
		print_r(lfs.attributes(IDE.projectsFolder))
		if lfs.attributes(IDE.projectsFolder).mode == "directory" then
			print('its there')
		else
			if not lfs.mkdir(IDE.projectsFolder) then
				print('coult not create project dir')
			end
		end
	end,	
}