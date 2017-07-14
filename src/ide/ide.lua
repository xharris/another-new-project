IDE = {
	projectsFolder = 'projects',

	newProject = function()
		IDE.checkProjectsFolder()
	end,

	-- make sure folder exists, create it if it doesn't
	checkProjectsFolder = function()
		HELPER.run('newProject',{IDE.projectsFolder})
	end,	
}