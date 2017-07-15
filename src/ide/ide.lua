local opening_project = false

local lastModified

IDE = {
	project_folder = 'projects',
	project_list = {},
	current_project = '',
	modules = {},

	load = function()
		lastModified = os.time()

		-- get modules
		for f, file in ipairs(love.filesystem.getDirectoryItems('modules')) do
			file = file:gsub('.lua','')
			IDE.modules[file] = require('modules.'..file)
		end
	end,

	newProject = function()
		IDE.checkProjectFolder()
	end,

	setProjectFolder = function(new_folder)
		if love.filesystem.isDirectory(new_folder) then
			IDE.project_folder = new_folder
			IDE.project_list = love.filesystem.getDirectoryItems(IDE.project_folder)
			local new_list = {}
			for f, file in ipairs(IDE.project_list) do
				if love.filesystem.isDirectory(IDE.project_folder..'/'..file) then
					table.insert(new_list,file)
				end
			end	
			IDE.project_list = new_list
		end		
	end,

	getFullProjectFolder = function()
		return love.filesystem.getRealDirectory(IDE.current_project)..'/'..IDE.current_project
	end,	

	-- make sure folder exists, create it if it doesn't
	checkProjectFolder = function()
		HELPER.run('newProject',{IDE.project_folder})
	end,	

	openProject = function(folder_path)
		if not opening_project then
			opening_project = true

			if IDE._reload(folder_path..'/includes.lua') then
			    IDE.current_project = folder_path
			end

			opening_project = false
		end
	end,

	_reload = function(path)	
		print('reloading project')

		local result, chunk
		result, chunk = pcall(love.filesystem.load, path)
		if not result then print("chunk error: " .. chunk) return false end
		result, chunk = pcall(chunk)
		if not result then print("exec. error: " .. chunk) return false end
		lastModified = os.time()

		BlankE.init(state0)

		return true
	end,

	reload = function()
		if IDE.current_project ~= '' then
			IDE._reload(IDE.current_project..'/includes.lua')
		end
	end,

	refreshAssets = function()
		local asset_str = ''
		for m, mod in pairs(IDE.modules) do
			if mod.getAssets then
				asset_str = asset_str .. mod.getAssets()
			end
		end
		HELPER.run('writeAssets', {IDE.getFullProjectFolder(), '"'..asset_str..'"'})
		IDE.reload()
	end,

	addGameType = function(obj_type)
		local obj_name = obj_type..#ifndef(game[obj_type],{})
		-- returns false if failed to make new name
		function nameObj() 
			for e, obj in ipairs(ifndef(game[obj_type],{})) do
				if obj.classname == obj_name or _G[obj_name] then
					obj_name = obj_name..'2'
					return false
				end
			end	
			if _G[obj_name] then return false end
			return true
		end

		while not nameObj() do end

		return obj_name
	end
}