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
	refresh_pjlist_timeout = 0,
	_initial_watch = true,

	project_folder = 'projects',
	_project_folder_changed = false,
	project_list = {},
	current_project = '',
	modules = {},

	iterateModules = function(func)
		for m, mod in pairs(IDE.modules) do
			func(m, mod)
		end
	end,

	update = function(dt)
		updateTimeout(dt, 'update_timeout')
		updateTimeout(dt, 'watch_timeout')
		updateTimeout(dt, 'refresh_pjlist_timeout')

    	if IDE.current_project ~= '' and IDE.watch_timeout == 0 then
    		IDE.watch_timeout = UI.getSetting('project_reload_timer').value
    		_watcher('/', function(file_name)
    			IDE.iterateModules(function(m, mod)
    				if mod.fileChange then
    					mod.fileChange(file_name)
    				end
    			end)

				if string.match(file_name, "empty_state") then
					if Gamestate.current() == _empty_state then
						IDE._reload(file_name)
					end
				end
			end)
		end

		if IDE.refresh_pjlist_timeout == 0 then
			IDE.refresh_pjlist_timeout = 5
			IDE.refreshProjectList()	
		end	

		if IDE._want_reload then
			IDE.reload()
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
	            imgui.EndMenu()
	        end

	        -- ADD/EDIT OBJECT
	        if IDE.isProjectOpen() and imgui.BeginMenu("Library") then
	        	IDE.iterateModules(function(m, mod)
	        		if mod.getObjectList then
	        			if imgui.BeginMenu(m) then
	        				-- new object button
	        				if mod.new and imgui.MenuItem("add "..m) then
	        					mod.new()
	        					IDE.refreshAssets()
	        				end

	        				local obj_list = mod.getObjectList()

	        				if m == 'state' and #obj_list > 0 then
    							status, initial_state = imgui.Combo("initial state", table.find(obj_list, UI.getSetting('initial_state')), obj_list, #obj_list);
    							if status then
    								UI.setSetting('initial_state',obj_list[initial_state])
    							end
	        				end

	        				if #obj_list > 0 and mod.new then
		        				imgui.Separator()
		        			end

	        				-- list current objects
		        			for o, obj in ipairs(obj_list) do
		        				local clicked = imgui.MenuItem(obj)
		        				if clicked and mod.edit then
		        					mod.edit(obj)
		        				end
		        			end
		        			imgui.EndMenu()
		        		end
	        		end
	        	end)	
	        	imgui.EndMenu()
	        end

	        -- IDE
	        if imgui.BeginMenu("IDE") then
	        	-- scene editor
	        	if IDE.isProjectOpen() and imgui.MenuItem("scene editor", nil, UI.titlebar.show_scene_editor) then
	        		UI.titlebar.show_scene_editor = not UI.titlebar.show_scene_editor
	        	end

	        	-- console
	            if imgui.MenuItem("console", nil, UI.titlebar.show_console) then
	            	UI.titlebar.show_console = not UI.titlebar.show_console
	            end

	            -- color randomization
	        	if imgui.MenuItem("randomize IDE color") then
	        		UI.randomizeIDEColor()
	        	end

	        	-- project reload timer
	        	imgui.PushItemWidth(80)
	        	local reload_timer = UI.getSetting("project_reload_timer")
	            status, new_time = imgui.DragFloat("project reload",reload_timer.value,0.5,reload_timer.min,reload_timer.max,"%.1fs")
	            if status then
	                UI.setSetting("project_reload_timer", new_time)
	            end

	            -- console height
	        	imgui.PushItemWidth(80)
	        	local console_height = UI.getSetting("console_height")
	            status, new_height = imgui.DragInt("console height",console_height.value,1,console_height.min,console_height.max)
	            if status then
	                UI.setSetting("console_height", new_height)
	            end

	            -- manual reload button
	            if IDE.isProjectOpen() and imgui.MenuItem("reload project") then
	            	IDE.reload()
	            end

	        	imgui.EndMenu()
	        end

	        -- DEV
	        if imgui.BeginMenu("Dev") then
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

		imgui.PushStyleVar('GlobalAlpha',1)
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

			if IDE.modules[file].disabled then
				package.loaded[file] = nil
				_G[file] = nil
			end
		end

		-- change imgui styling
		UI.randomizeIDEColor()
	end,

	newProject = function()
		HELPER.run('newProject',{'"'..IDE.getProjectFolder()..'"'})
		IDE.refreshProjectList()
	end,

	setProjectFolder = function(new_folder)
		if love.filesystem.isDirectory(new_folder) then
			IDE.project_folder = new_folder
			IDE.refreshProjectList()
		end		
	end,

	refreshProjectList = function()
		IDE.project_list = love.filesystem.getDirectoryItems(IDE.project_folder)
		local new_list = {}
		for f, file in ipairs(IDE.project_list) do
			if love.filesystem.isDirectory(IDE.project_folder..'/'..file) then
				table.insert(new_list,file)
			end
		end	
		IDE.project_list = new_list
	end,

	getProjectFolder = function()
		return love.filesystem.getRealDirectory(IDE.project_folder)..IDE.project_folder
	end,

	getCurrentProject = function()
		return love.filesystem.getRealDirectory(IDE.current_project)..'/'..IDE.project_folder..'/'..basename(IDE.current_project)-- IDE.current_project
	end,

	isProjectOpen = function()
		return (IDE.current_project ~= '')
	end,

	openProject = function(folder_path)
		if not opening_project then
			opening_project = true

			if package.loaded['BlankE'] then
				package.loaded['BlankE'] = nil
				_G['BlankE'] = nil
			end

			local old_path = IDE.current_project
			IDE.current_project = folder_path
			if not IDE._reload(IDE.current_project..'/includes.lua') then
				IDE.current_project = old_path
			end

			opening_project = false
		end
	end,

	_reload = function(path, dont_init_blanke)	
		if IDE.update_timeout == 0 then
			print('meep',path,dont_init_blanke)
			IDE.update_timeout = 2
--[[
			local proj = 'projects/project1/'
			local paths = {"?/?.lua","?.lua","?/init.lua"}
			for p, path in ipairs(paths) do
				package.path = package.path .. ";"..proj..path
			end
]]
			IDE.refreshAssets(true)
			IDE.iterateModules(function(m, mod)
				if mod.onReload then
					mod.onReload()
				end
			end)

			_REPLACE_REQUIRE = dirname(path):gsub('/','.')
			if _REPLACE_REQUIRE:starts('.') then _REPLACE_REQUIRE:replaceAt(1,'') end

			local result, chunk
			result, chunk = pcall(love.filesystem.load, path)
			if not result then print("chunk error: " .. chunk) return false end
			result, chunk = pcall(chunk)
			if not result then print("exec. error: " .. chunk) return false end

			BlankE._ide_mode = true
			if not dont_init_blanke then
				BlankE.init(_FIRST_STATE)
			end

			IDE._want_reload = false
			return true
		end
		return false
	end,

	reload = function(dont_init_blanke)
		IDE._want_reload = true
		if IDE.current_project ~= '' then
			IDE._reload(IDE.current_project..'/includes.lua', dont_init_blanke)
		end
	end,

	refreshAssets = function(dont_reload)
		local asset_str = 
		"local script_path = (...):match(\'(.-)[^%.]+$\')\n"..
		"local asset_path = script_path:gsub('%.','/')..\'/\'\n\n"..
		"local oldreq = require\n"..
		"local require = function(s) return oldreq(script_path .. s) end\n"..
		"assets = Class{}\n\n"

		local high_priority = {'image','audio','entity','state'}

		for m, mod in ipairs(high_priority) do
			IDE.modules[mod].getObjectList()
			asset_str = asset_str .. IDE.modules[mod].getAssets()
		end

		for m, mod in pairs(IDE.modules) do
			if mod.getAssets and not table.find(high_priority,m) then
				if mod.getObjectList then mod.getObjectList() end
				asset_str = asset_str .. mod.getAssets()
			end
		end
		asset_str = asset_str.."require = oldreq\n"
		HELPER.run('writeAssets', {IDE.getCurrentProject(), '\"'..asset_str:gsub('\n','\\n')..'\"'})
		if not dont_reload then
			IDE.reload()
		end
	end,

	validateName = function(new_name, collection)
		new_name = new_name:trim()

		-- returns false if failed to make new name
		function nameObj() 
			for e, obj in ipairs(ifndef(collection,{})) do
				if (type(obj) == 'table' and obj.classname == new_name) or (type(obj) == 'string' and obj == new_name) or _G[new_name] then
					new_name = new_name..'2'
					return false
				end
			end	
			if _G[new_name] then return false end
			return true
		end

		while not nameObj() do end

		return new_name
	end,

	-- gets the name for the new game object
	addGameType = function(obj_type)
		local obj_name = obj_type..#ifndef(game[obj_type],{})

		return IDE.validateName(obj_name, game[obj_type])
	end,

	addResource = function(file)
		if IDE.getCurrentProject() then
			local path = file:getFilename()
			local ext = extname(path)

			local img_ext = {'tif','tiff','gif','jpeg','jpg','jif','jiff','jp2','jpx','j2k','j2c','fpx','png','pcd','pdf'}
			local audio_ext = {'pcm','wav','aiff','mp3','aac','ogg','wma','flac','alac','wma'}

			for i, img in ipairs(img_ext) do
				if ext == '.'..img then
					IDE.modules.image.addImage(file)
				end
			end

			for a, audio in ipairs(audio_ext) do
				if ext == '.'..audio then
					IDE.modules.audio.addAudio(file)
				end
			end
		end
	end,
}