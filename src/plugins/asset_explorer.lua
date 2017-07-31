local explorer_open = false
local assets = {}
local path_assets = ''
local obj_to_rename = ''
local new_name = ''

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
						local path_object = path_assets..'/'..cat..'/'..obj

            			imgui.AlignFirstTextHeightToWidgets()
						imgui.Text(obj)
						imgui.SameLine(300)

						if UI.drawIconButton("pencil", "rename") then
							-- show rename box
							obj_to_rename = obj
							new_name = obj
							imgui.OpenPopup("Rename")
						end

						if obj_to_rename == obj and imgui.BeginPopupModal("Rename", nil, {"AlwaysAutoResize"}) then
	           				rename_status, new_name = imgui.InputText("", new_name,300)

	           				if imgui.Button("Rename") then
								--new_name = IDE.validateName(new_name, objects)
								-- actually rename file
								local new_path = path_assets..'/'..cat..'/'..new_name
								SYSTEM.rename(path_object, new_path)
								IDE.refreshAssets()

								imgui.CloseCurrentPopup()
							end
							imgui.SameLine()
							if imgui.Button("Cancel") then
								imgui.CloseCurrentPopup()
							end
							-- call module rename method?

							imgui.EndPopup()
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