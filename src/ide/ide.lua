local opening_project = false

function updateTimeout(dt, var)
	if IDE[var] > 0 then
		IDE[var] = IDE[var] - dt
	else
		IDE[var] = 0
	end
end

IDE = {
	update_timeout = 0,
	watch_timeout = 0,

	project_folder = '/projects',
	_project_folder_changed = false,
	project_list = {},
	current_project = '',
	modules = {},

	update = function(dt)
		updateTimeout(dt, 'update_timeout')
		updateTimeout(dt, 'watch_timeout')

    	if IDE.current_project ~= '' and IDE.watch_timeout == 0 then
    		IDE.watch_timeout = 3
			_watcher(IDE.current_project..'/', function(file_name)
	            for m, mod in pairs(IDE.modules) do
	            	if mod.fileChange then
	            		mod.fileChange(file_name)
	            	end
				end
			end)
		end
	end,

	draw = function()
		love.graphics.setColor(255,255,255)
	    -- Menu
	    if imgui.BeginMainMenuBar() then
	        -- FILE
	        if imgui.BeginMenu("File") then
	        	if imgui.MenuItem("New") then
	        		IDE.newProject()
	        	end
	            -- project directory
	            status, new_folder = imgui.InputText("",IDE.project_folder,300)
	            if status and new_folder ~= IDE.project_folder then
	                IDE.setProjectFolder(new_folder)
	            end
	            -- available projects in dir
	            if #IDE.project_list > 0 then
	                imgui.BeginChild("project list", 0, 60, true)
	                for p, project in ipairs(IDE.project_list) do
	                    -- chose a project to open?
	                    if imgui.MenuItem(project) then
	                        IDE.openProject(IDE.project_folder..'/'..project)
	                    end
	                end
	                imgui.EndChild()
	            end
	            if IDE.current_project ~= '' then
	                imgui.MenuItem("Save")
	            end
	            imgui.EndMenu()
	        end

	        -- ADD OBJECT
	        if IDE.current_project ~= '' and imgui.BeginMenu("Add") then
	            for m, mod in pairs(IDE.modules) do
	                local clicked = imgui.MenuItem(m)
	                if clicked and mod.new then
	                    mod.new()
	                    IDE.refreshAssets()
	                end
	            end
	            imgui.EndMenu()
	        end

	        -- EDIT OBJECT
	        if IDE.current_project ~= '' and imgui.BeginMenu("Edit") then
	        	for m, mod in pairs(IDE.modules) do
	        		if mod.getObjectList then
	        			if imgui.BeginMenu(m) then
		        			for o, obj in ipairs(mod.getObjectList()) do
		        				local clicked = imgui.MenuItem(obj)
		        				if clicked and mod.edit then
		        					mod.edit(obj)
		        				end
		        			end
		        			imgui.EndMenu()
		        		end
	        		end
	        	end	
	        	imgui.EndMenu()
	        end

	        -- IDE
	        if imgui.BeginMenu("IDE") then
	        	if imgui.MenuItem("randomize IDE color") then
	        		UI.randomizeIDEColor()
	        	end
	        	imgui.EndMenu()
	        end

	        -- DEV
	        if imgui.BeginMenu("Dev") then
	            if imgui.MenuItem("show console", nil, UI.titlebar.show_console) then
	            	UI.titlebar.show_console = not UI.titlebar.show_console
	            end

	            if imgui.MenuItem("dev tools") then
	            	UI.titlebar.show_dev_tools = true
	            end
	            if imgui.MenuItem("style editor") then
	            	UI.titlebar.show_style_editor = true
	            end
	            imgui.EndMenu()
	        end
	        imgui.EndMainMenuBar()
	    end

	    -- draw modules
	    for m, mod in pairs(IDE.modules) do
	    	if mod.draw then
	    		mod.draw()
	    	end
	    end
	    
	    --checkUI("titlebar.new_project", IDE.newProject)
	    if UI.titlebar.new_project then UI.titlebar.new_project = IDE.newProject() end
	    if UI.titlebar.show_dev_tools then UI.titlebar.show_dev_tools = imgui.ShowTestWindow(true) end
	    
	    if UI.titlebar.show_style_editor then 
	    	state, UI.titlebar.show_style_editor = imgui.Begin("Style Editor", UI.titlebar.show_style_editor, UI.flags)
	    	imgui.ShowStyleEditor()
	    	imgui.End()
	    end
	    
		CONSOLE.draw()

    	if not BlankE or (BlankE and not BlankE._ide_mode) then
        	love.graphics.clear(unpack(UI.color.background))
        end
        imgui.Render()
	end,

	load = function()
		-- get modules
		for f, file in ipairs(love.filesystem.getDirectoryItems('modules')) do
			file = file:gsub('.lua','')
			IDE.modules[file] = require('modules.'..file)
		end

		-- change imgui styling
		UI.randomizeIDEColor()
	end,

	newProject = function()
		HELPER.run('newProject',{'"'..IDE.getFullProjectFolder()..'"'})
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
		return love.filesystem.getRealDirectory(IDE.project_folder)..IDE.project_folder
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
		if IDE.update_timeout == 0 then
			IDE.update_timeout = 2
			print('reloading project')

			local result, chunk
			result, chunk = pcall(love.filesystem.load, path)
			if not result then print("chunk error: " .. chunk) return false end
			result, chunk = pcall(chunk)
			if not result then print("exec. error: " .. chunk) return false end

			BlankE._ide_mode = true
			BlankE.init(state0)

			return true
		end
		return false
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