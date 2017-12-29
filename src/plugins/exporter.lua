local os_list = {'love','win','mac'}--,'web','android','ios'}

local love2d_binary_path = {
	win=dirname(SYSTEM.cwd)..'/love2d',
	mac=SYSTEM.cwd..'/love.app'
}
local engine_path = SYSTEM.cleanPath(IDE.getTemplatePath().."/plugins")

function buildSrcDir(folder_name)
	engine_path = SYSTEM.cleanPath(IDE.getTemplatePath().."/plugins")

	-- make export directory
	SYSTEM.mkdir(folder_name)

	-- copy all files/folders except export folder
	local src_dir = IDE.getProjectPath()
	local src_dir_list = SYSTEM.scandir(src_dir)
	for f, file in ipairs(src_dir_list) do
		if not file:match('dist') then
			SYSTEM.copy(src_dir..'/'..file, folder_name..'/src/'..file)
		end
	end

	-- copy engine
	SYSTEM.copy(engine_path, folder_name..'/src/plugins')
	return folder_name..'/src'
end

-- folder_name: put the .love in /project/export/<folder_name>/
function buildLove(folder_name)
	src_dir = buildSrcDir(folder_name)

	-- zip into .love
	SYSTEM.zip(src_dir, folder_name..'/'.._GAME_NAME..'.love')

	-- remove temporary src dir
	SYSTEM.remove(src_dir)

	return folder_name..'/'.._GAME_NAME..'.love'
end

-- os to build for
-- open_dir: open the export directory when finished
function export(target_os, open_dir)
	local output_dir = IDE.getProjectPath()..'/dist/'..target_os

	-- remove old dir if it exists
	SYSTEM.remove(output_dir)


	if target_os == 'love' then
		buildLove(output_dir)
		return false
	end

	-- build .love
	local love_path = buildLove(output_dir)
	local build_path = dirname(love_path)	-- has a trailing '/'!!!!!

	local curr_os = SYSTEM.os
	if target_os == 'win' then
		
		local binary_path = love2d_binary_path['win']
		local build_cmd = ''

		if curr_os == 'mac' then
			-- build EXE on a mac
			build_cmd = 'cat '..binary_path..'/love.exe '..build_path.._GAME_NAME..'.love > '..build_path.._GAME_NAME..'.exe'
		
		elseif curr_os == 'win' then
			-- build EXE on windows
			build_cmd = 'cmd /c \"copy /b '..SYSTEM.winPath(binary_path..'/love.exe+'..build_path.._GAME_NAME..'.love '..build_path.._GAME_NAME)..'.exe\"'

		end
		
		os.execute(build_cmd)

		-- remove .love
		SYSTEM.remove(love_path)
		SYSTEM.remove(output_dir.."/src")

		-- copy dlls
		local extra_files = {"SDL2.dll", "OpenAL32.dll", "license.txt", "love.dll", "lua51.dll", "mpg123.dll", "msvcp120.dll", "msvcr120.dll"}
		for f, file in ipairs(extra_files) do
			SYSTEM.copy(binary_path..'/'..file, build_path..file)
		end

	elseif target_os == 'mac' then
		if curr_os == 'mac' then
			-- combine love2d with .love
			local binary_path = love2d_binary_path['mac']
			local app_path = build_path.._GAME_NAME..'.app'
			SYSTEM.copy(binary_path, app_path)
			SYSTEM.rename(love_path, app_path..'/Contents/Resources/'.._GAME_NAME..'.love')

		end

	end

	SYSTEM.explore(build_path)
end

exporter = {
	project_plugin = true,

	onMenuDraw = function()
		if imgui.MenuItem("run") then
			src_path = buildSrcDir(IDE.getProjectPath()..'/dist')
			if SYSTEM.os == 'mac' then
				SYSTEM.execute(SYSTEM.cwd.."\"/love.app/Contents/MacOS/love\" \""..src_path.."\"")
			elseif SYSTEM.os == 'win' then
				SYSTEM.execute(SYSTEM.cwd.."/love2d-win32/love.exe\" \""..src_path.."\"")
			end
		end

		if imgui.BeginMenu("export") then

			for o, os in ipairs(os_list) do
				if imgui.MenuItem(os) then export(os) end
			end

			imgui.EndMenu()
		end
	end,
}

return exporter