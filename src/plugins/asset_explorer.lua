local explorer_open = false
local assets = {}
local path_assets = ''

local refreshAssets = function()
	assets = {}
	path_assets = IDE.getProjectPath()..'/assets'
	local categories = SYSTEM.scandir(path_assets)

	for c, cat in ipairs(categories) do
		local path_category = path_assets..'/'..cat
		assets[cat] = {}

		local objects = SYSTEM.scandir(path_category)

		-- objects
		for o, obj in ipairs(objects) do
			table.insert(assets[cat], obj)
		end
	end
end

asset_explorer = {
	menu_text = 'asset explorer',
	project_plugin = true,

	onMenuClick = function()
		refreshAssets()
		explorer_open = true
	end,

	onProjectOpen = function()
		refreshAssets()
	end,

	fileChange = function(file)
		refreshAssets()
	end,

	draw = function()
		if explorer_open then
			imgui.SetNextWindowSize(300,300,"FirstUseEver")
			status, explorer_open = imgui.Begin("asset explorer", true)
	
			-- categories
			for cat, objects in pairs(assets) do
				if imgui.TreeNode(cat) then

					-- objects
					for o, obj in ipairs(objects) do
						local path_object = path_assets..'/'..obj

            			imgui.AlignFirstTextHeightToWidgets()
						imgui.Text(obj)
						imgui.SameLine(300)
						if UI.drawIconButton("pencil", "rename") then
							-- show rename box

							-- call module rename method
							
						end
						imgui.SameLine()
						if UI.drawIconButton("trash", "delete") then

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