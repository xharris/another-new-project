local os_list = {'love','win','mac','android','ios'}

-- folder_name: put the .love in /project/export/<folder_name>/
function buildLove(folder_name)
	-- make export directory
	SYSTEM.mkdir(folder_name)

	-- copy all files/folders except export foler
	local src_dir = IDE.getProjectPath()
	local src_dir_list = SYSTEM.scandir(src_dir)
	for f, file in ipairs(src_dir_list) do
		if not file:match('dist') then
			SYSTEM.copy(src_dir..'/'..file, folder_name..'/src/'..file)
		end
	end

	-- zip into .love
	HELPER.run('zipDir',{folder_name..'/src', folder_name..'/'.._GAME_NAME..'.love'})

	-- remove temporary src dir
	SYSTEM.remove(folder_name..'/src')

	return folder_name..'/'.._GAME_NAME..'.love'
end

-- os to build for
-- open_dir: open the export directory when finished
function export(target_os, open_dir)
	local output_dir = IDE.getProjectPath()..'/dist/'..target_os

	-- remove old dir if it exists
	SYSTEM.remove(output_dir)

	-- build .love
	local love_path = buildLove(output_dir)
	local build_path = dirname(love_path)	-- has a trailing '/'!!!!!

	if target_os == 'win' then
		local curr_os = SYSTEM.os
		if curr_os == 'mac' then
			-- build EXE on a mac
			local binary_path = SYSTEM.cwd..'/love2d-win32'
			local build_cmd ='cat '..binary_path..'/love.exe '..build_path.._GAME_NAME..'.love > '..build_path.._GAME_NAME..'.exe'
			os.execute(build_cmd)

			-- remove .love
			SYSTEM.remove(love_path)

			-- copy dlls
			local extra_files = {"SDL2.dll", "OpenAL32.dll", "license.txt", "love.dll", "lua51.dll", "mpg123.dll", "msvcp120.dll", "msvcr120.dll"}
			for f, file in ipairs(extra_files) do
				SYSTEM.copy(binary_path..'/'..file, build_path..file)
			end
		end
	end

	SYSTEM.explore(build_path)
end

exporter = {
	project_plugin = true,

	onMenuDraw = function()
		if imgui.MenuItem("run") then
			buildLove()
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