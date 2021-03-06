local explorer_open = false
local assets = {}
local path_assets = ''
local obj_to_rename = ''
local new_name = ''

local big_folder_list = {'assets','scripts'}

local refreshAssets = function()
	assets = {}
	path_assets = IDE.getProjectPath()..'/'

	for b, big_folder in ipairs(big_folder_list) do
		assets[big_folder] = {}
		local categories = SYSTEM.scandir(path_assets..'/'..big_folder)

		for c, cat in ipairs(categories) do
			local path_category = path_assets..'/'..big_folder..'/'..cat
			assets[big_folder][cat] = {}

			local objects = SYSTEM.scandir(path_category)

			-- objects
			for o, obj in ipairs(objects) do
				table.insert(assets[big_folder][cat], obj)
			end
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
	
			-- big folders (assets, scripts)
			for big_folder, cats in pairs(assets) do
				if imgui.TreeNode(big_folder) then

					-- categories
					for cat, objects in pairs(cats) do
						if imgui.TreeNode(cat) then

							-- objects
							for o, obj in ipairs(objects) do
								local root_path = path_assets..big_folder..'/'..cat
								local path_object = root_path..'/'..obj

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
										-- actually rename file
										local new_path = root_path..'/'..new_name
										if not IDE.rename(cat, path_object, new_path) then
											-- default rename 
											SYSTEM.rename(path_object, new_path)
											IDE.refreshAssets()
										end
										imgui.CloseCurrentPopup()
									end
									imgui.SameLine()
									if imgui.Button("Cancel") then
										imgui.CloseCurrentPopup()
									end

									imgui.EndPopup()
								end

								imgui.SameLine()
								if UI.drawIconButton("trash", "delete") then
									obj_to_delete = obj
									imgui.OpenPopup("Delete")
								end

								if obj_to_delete == obj and imgui.BeginPopupModal("Delete", nil, {"AlwaysAutoResize"}) then
									imgui.PushTextWrapPos(game_width/1.5)
									imgui.Text("Are you sure you want to delete:\n"..path_object)

									if imgui.Button("Yes") then
										SYSTEM.remove(path_object)
										IDE.refreshAssets()
										imgui.CloseCurrentPopup()
									end
									imgui.SameLine()
									if imgui.Button("No") then
										imgui.CloseCurrentPopup()
									end

									imgui.EndPopup()
								end
							end

							imgui.TreePop()
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