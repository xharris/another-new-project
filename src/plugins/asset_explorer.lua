local explorer_open = false

asset_explorer = {
	menu_text = 'asset explorer',
	project_plugin = true,

	onMenuClick = function()
		explorer_open = true
	end,

	draw = function()
		if explorer_open then
			imgui.SetNextWindowSize(300,300,"FirstUseEver")
			status, explorer_open = imgui.Begin("asset explorer", true)
	
			local path_assets = IDE.getProjectPath()..'/assets'
			local categories = SYSTEM.scandir(path_assets)

			-- categories
			for c, cat in ipairs(categories) do
				local path_category = path_assets..'/'..cat

				if imgui.TreeNode(cat) then
					local objects = SYSTEM.scandir(path_category)

					-- objects
					for o, obj in ipairs(objects) do
						local path_object = path_assets..'/'..obj

						imgui.Text(obj)
						imgui.SameLine(300)
						if imgui.Button("rename") then
							-- show rename box

							-- call module rename method
							
						end
						imgui.SameLine()
						if imgui.Button("delete") then

						end
					end

					imgui.TreePop()
				end
			end

			imgui.End()
		end
	end,
}

return asset_explorer