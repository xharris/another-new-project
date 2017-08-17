local new_pj_name = 'myproject'
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
	errd = false,

	project_folder = 'projects',
	_project_folder_changed = false,
	project_list = {},
	current_project = '',
	modules = {},
	plugins = {},

	iterateModules = function(func)
		for m, mod in pairs(IDE.modules) do
			func(m, mod)
		end
	end,

	iteratePlugins = function(func)
		for p, plugin in pairs(IDE.plugins) do
			func(p, plugin)
		end
	end,

	load = function()
		UI.loadFont()
		-- load ide plugins
		for f, file in ipairs(love.filesystem.getDirectoryItems('plugins')) do
			file = file:gsub('.lua','')
			IDE.plugins[file] = require('plugins.'..file)

			if IDE.plugins[file].disabled then
				package.loaded[file] = nil
				_G[file] = nil
			end
		end

		-- get modules
		for f, file in ipairs(love.filesystem.getDirectoryItems('modules')) do
			file = file:gsub('.lua','')
			IDE.modules[file] = require('modules.'..file)

			if IDE.modules[file].disabled then
				package.loaded[file] = nil
				_G[file] = nil
			end
		end

		IDE.setProjectFolder(IDE.project_folder)

		-- change imgui styling
		UI.randomizeIDEColor()
	end,

	update = function(dt)
		updateTimeout(dt, 'update_timeout')
		updateTimeout(dt, 'watch_timeout')
		updateTimeout(dt, 'refresh_pjlist_timeout')

    	if IDE.isProjectOpen() and IDE.watch_timeout == 0 then
    		IDE.watch_timeout = UI.getSetting('project_reload_timer').value
    		
    		_watcher(IDE.getShortProjectPath(), function(file_name)
    			IDE.fileChange(file_name)
			end)
		end

		if IDE._want_reload then
			IDE.reload()
		end
	end,

	fileChange = function(file_name) 
		IDE.iterateModules(function(m, mod)
			if mod.fileChange then
				mod.fileChange(file_name)
			end
		end)

		IDE.iteratePlugins(function(p, plugin)
			if plugin.fileChange then
				plugin.fileChange(file_name)
			end
		end)

		if string.match(file_name, "empty_state") then
			if State.current() == _empty_state then
				IDE._reload(file_name)
			end
		end
	end,

	-- returns false if a module was not found that handles the renaming for this file
	rename = function(type, old_path, new_path)
		IDE.iterateModules(function(m, mod)
			if mod.onRename then
				mod.onRename(old_path, new_path)
				IDE.refreshAssets()
				return true
			end
		end)
		return false
	end,	

	draw = function()
		love.graphics.setColor(255,255,255)

	    -- Menu
	    function beginMenu(title)
	    	local g_color = {255,255,255}
	    	if BlankE then
	    		g_color = BlankE.grid_color
	    	end
    		imgui.PushStyleColor('Text', g_color[1]/255, g_color[2]/255, g_color[3]/255, 1)
	    	local menu = imgui.BeginMenu(title)
	    	imgui.PopStyleColor(1)
	    	return menu
	    end

    	imgui.PushStyleColor('WindowBg', 0,0,0,0)
    	imgui.PushStyleColor('MenuBarBg', 0,0,0,0)
	    local main_menu_bar = imgui.BeginMainMenuBar()
	    imgui.PopStyleColor(2)

	    if main_menu_bar then
	        -- FILE
	        if beginMenu("File") then
	        	if imgui.Button("New") then
	        		imgui.OpenPopup("new_project")
	        	end

	        	-- new project
				if imgui.BeginPopupModal("new_project", nil, {"AlwaysAutoResize"}) then
					new_status, new_pj_name = imgui.InputText("name", new_pj_name,300)

					if imgui.Button("Ok") then
						IDE.newProject(new_pj_name)
						imgui.CloseCurrentPopup()
					end
					imgui.SameLine()
					if imgui.Button("Cancel") then
						imgui.CloseCurrentPopup()
					end

					imgui.EndPopup()
				end

	            -- project directory
	            if UI.titlebar.secret_stuff then
		            status, new_folder = imgui.InputText("",IDE.project_folder,300)
		            if status and new_folder ~= IDE.project_folder then
		                IDE.setProjectFolder(new_folder)
		            end
		            if imgui.IsItemHovered() then
						imgui.BeginTooltip()
						imgui.Text(IDE.getProjectFolder())
						imgui.EndTooltip()
					end
					imgui.SameLine()
					if imgui.Button("Open") then
						love.system.openURL("file://"..IDE.getProjectPath())
					end
				end

	            -- available projects in dir
				if IDE.refresh_pjlist_timeout == 0 then
					IDE.refresh_pjlist_timeout = 5
					IDE.refreshProjectList()	
				end	
	            if #IDE.project_list > 0 then

	                imgui.BeginChild("project list", 220, 60, true)
	                for p, project in ipairs(IDE.project_list) do
	                    -- chose a project to open?
	                    if imgui.MenuItem(project) then
	                        IDE.openProject(IDE.project_folder..'/'..project)
	                    end

						if imgui.IsItemHovered() then
							imgui.BeginTooltip()
							imgui.Text(IDE.getProjectPath(project))
							imgui.EndTooltip()
						end
	                end
	                imgui.EndChild()
	            end
	            imgui.EndMenu()
	        end

	        -- ADD/EDIT OBJECT
	        if IDE.isProjectOpen() and beginMenu("Library") then
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
	        if beginMenu("IDE") then
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

	        	-- ide font
	        	imgui.PushItemWidth(120)
	        	local fonts = love.filesystem.getDirectoryItems('fonts')
	        	for f, font in ipairs(fonts) do
	        		fonts[f] = font:gsub(extname(font),'')
	        	end
				status, new_font = imgui.Combo("font", table.find(fonts, UI.getSetting('font')), fonts, #fonts);
				if status then
					UI.setSetting('font',fonts[new_font])
					UI.setStyling()
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

	            -- show blanke dev stuff
	            if imgui.MenuItem("secret stuff", nil, UI.titlebar.secret_stuff) then
	            	UI.titlebar.secret_stuff = not UI.titlebar.secret_stuff
	            end

	            local fullscreen = UI.getSetting("fullscreen")
	            if imgui.MenuItem("fullscreen", nil, fullscreen) then
	            	UI.setSetting("fullscreen", not fullscreen)
	            	love.window.setFullscreen(not fullscreen)
	            end

	        	imgui.EndMenu()
	        end

	        -- TOOLS (plugins)
	        if beginMenu("Tools") then
	        	IDE.iteratePlugins(function(p, plugin)

	        		if plugin.onMenuDraw and (not plugin.project_plugin or (plugin.project_plugin and IDE.isProjectOpen())) then
        				plugin.onMenuDraw()

	        		elseif plugin.menu_text and 
	        		   (not plugin.project_plugin or (plugin.project_plugin and IDE.isProjectOpen())) 
	        		   and plugin.onMenuClick
	        		then
	        			if imgui.MenuItem(plugin.menu_text) then
	        				plugin.onMenuClick()
	        			end
	        		end

	        	end)
	        	
	        	imgui.EndMenu()
	        end

	        -- DEV
	        if UI.titlebar.secret_stuff and beginMenu("Dev") then
	            if imgui.MenuItem("dev tools") then
	            	UI.titlebar.show_dev_tools = true
	            end
	            if imgui.MenuItem("style editor") then
	            	UI.titlebar.show_style_editor = true
	            end
	            imgui.EndMenu()
	        end
	        
	        -- manual reload button
	        if IDE.isProjectOpen() and UI.drawIconButton("reload", "reload game") then
				IDE.reload()
			end

			-- refresh just state
	        if IDE.isProjectOpen() and UI.drawIconButton("reload", "restart state") then
				
			end

	        imgui.EndMainMenuBar()
	    end
				
	    -- draw modules
	    for m, mod in pairs(IDE.modules) do
	    	if mod.draw then
	    		mod.draw()
	    	end
	    end

	    -- draw plugins
	    IDE.iteratePlugins(function(p, plugin)
	    	if plugin.draw then
	    		plugin.draw()
	    	end
	    end)
	    
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

	quit = function()
		IDE.refreshAssets(true)
	end,

	newProject = function()
		HELPER.run('newProject',{'"'..IDE.getProjectPath()..'"', new_pj_name})
		IDE.refreshProjectList()
	end,

	setProjectFolder = function(new_folder)
		if not love.filesystem.isDirectory(new_folder) then
			if love.filesystem.createDirectory(new_folder) then
				IDE.project_folder = new_folder
				IDE.refreshProjectList()
			end
		else
			IDE.project_folder = new_folder
			IDE.refreshProjectList()
		end
	end,

	refreshProjectList = function()
		IDE.project_list = SYSTEM.scandir(IDE.getProjectFolder())

		local new_list = {}
		for f, file in ipairs(IDE.project_list) do
			--if love.filesystem.isDirectory(IDE.getProjectFolder()..'/'..file) then
				table.insert(new_list,file)
			--end
		end	
		IDE.project_list = new_list
	end,

	-- src/myprojects
	getProjectFolder = function()
		return love.filesystem.getRealDirectory(IDE.project_folder)..'/'..IDE.project_folder
	end,

	-- C:/blackstar/src/myprojects/theproject (absolute path)
	getProjectPath = function(proj_name)
		proj_name = ifndef(proj_name,IDE.current_project)

		if proj_name ~= '' then
			if love.filesystem.getRealDirectory(IDE.project_folder..'/'..proj_name) == love.filesystem.getSaveDirectory() then
				-- in the save directory
				return love.filesystem.getRealDirectory(IDE.project_folder)..'/'..IDE.project_folder..'/'..proj_name
			end
			-- in the executable directory
			return love.filesystem.getSource()..'/'..IDE.project_folder..'/'..proj_name
		end

		return love.filesystem.getRealDirectory(IDE.project_folder)..'/'..IDE.project_folder
	end,

	-- src/myprojects/theproject (relative path)
	getShortProjectPath = function()
		return IDE.project_folder..'/'..IDE.current_project
	end,

	-- theproject
	getCurrentProject = function()
		return IDE.current_project-- IDE.current_project
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
			IDE.current_project = basename(folder_path)

			if not IDE._reload(IDE.project_folder..'/'..IDE.current_project..'/includes.lua') then
				IDE.current_project = old_path
			end

			IDE.iterateModules(function(m, module)
				if module.onOpenProject then
					module.onOpenProject()
				end
			end)

			IDE.iteratePlugins(function(p, plugin)
				if plugin.onOpenProject then
					plugin.onOpenProject()
				end
			end)

			opening_project = false
		end
	end,

	_reload = function(path, dont_init_blanke)	
		if IDE.update_timeout == 0 then
			IDE.update_timeout = 2

			IDE.errd = false
--[[
			local proj = 'projects/project1/'
			local paths = {"?/?.lua","?.lua","?/init.lua"}
			for p, path in ipairs(paths) do
				package.path = package.path .. ";"..proj..path
			end
]]
			IDE.refreshAssets(true)

	        IDE.iteratePlugins(function(p, plugin)
	        	if plugin.onReload then
	        		plugin.onReload()
	        	end
	        end)

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

			IDE.iterateModules(function(m, mod)
				if mod.postReload then
					mod.postReload()
				end
			end)

			BlankE._ide_mode = true
			if not dont_init_blanke then
				BlankE.init(_FIRST_STATE)
					
			end

			IDE._want_reload = false
			return true
		end
		return false
	end,

	onAddGameObject = function()
		IDE.iterateModules(function(m, mod)
			if mod.onAddGameObject then
				mod.onAddGameObject()
			end
		end)	
	end,

	reload = function(dont_init_blanke)
		IDE._want_reload = true
		if IDE.isProjectOpen() then
			IDE._reload(IDE.getShortProjectPath()..'/includes.lua', dont_init_blanke)
		end
	end,

	refreshAssets = function(dont_reload)
		if not IDE.isProjectOpen() then return end

		local asset_str = 
		"local asset_path = ''\n"..
		"local oldreq = require\n"..
		"if _REPLACE_REQUIRE then\n"..
		"\tasset_path = _REPLACE_REQUIRE:gsub('%.','/')\n"..
		"\trequire = function(s) return oldreq(_REPLACE_REQUIRE .. s) end\n"..
		"end\n"..
		"assets = Class{}\n"

		local high_priority = {'image','audio','scene','entity','state'}

		for m, mod in ipairs(high_priority) do
			local _module = IDE.modules[mod]
			if _module.getObjectList then
				_module.getObjectList()
			end
			if _module.getAssets then
				asset_str = asset_str .. _module.getAssets()
			end
		end

		for mod_name, mod in pairs(IDE.modules) do
			if mod.getAssets and not table.find(high_priority,mod_name) then
				if mod.getObjectList then mod.getObjectList() end
				asset_str = asset_str .. mod.getAssets()
			end
		end
		asset_str = asset_str.."if _REPLACE_REQUIRE then\n\trequire = oldreq\nend"

		SYSTEM.mkdir(IDE.getProjectPath())
		--HELPER.run('makeDirs', {'"'..IDE.getProjectPath()..'"'})
		local file = io.open(IDE.getProjectPath()..'/assets.lua','w+')
		if assert(file,"ERR: problem writing to '"..IDE.getProjectPath().."/assets.lua'") then
			file:write(asset_str)
			file:close()
		end

		if not dont_reload then
			IDE._reload(IDE.getShortProjectPath()..'/assets.lua', true)
		end
	end,

	validateName = function(new_name, collection)
		new_name = new_name:trim()
		if type(collection) ~= 'table' then
			collection = {}
		end

		-- cannot start with number
		if new_name:match("^%d") then
			new_name = "_"..new_name
		end

		-- cannot contain hyphens
		new_name = new_name:gsub("-","_")

		-- returns false if failed to make new name
		function nameObj() 
			for e, obj in ipairs(collection) do
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
		if IDE.isProjectOpen() then
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

			IDE.refreshAssets()
		end
	end,
}