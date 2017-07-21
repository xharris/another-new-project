local curr_scene_index = 1
local curr_placer_index = 1
local curr_object_index = 1

local selected_entity = ''

local placeable = {'entity','image','hitbox'}

function writeSceneFiles()
	_iterateGameGroup('scene', function(scene, s)
		local scene_name = scene.name
		local scene_path = IDE.current_project..'/assets/scene/'..scene_name..'.json'
		local scene_data = scene:export()
		
		HELPER.run('writeJSON',{scene_path,scene_data})

		ret_str = ret_str..
			"function assets:"..scene_name..'()\n'..
			"\t return \"assets/scene/"..scene_name..".json\"\n"..
			"end\n\n"
	end)
end

local ideScene = {
	getAssets = function()
		local ret_str = ''
		if BlankE then
			writeSceneFiles()
		end
		return ret_str..'\n'
	end,

	postBlankeInit = function()
		writeSceneFiles()
	end,

	draw = function()
		if UI.titlebar.show_scene_editor and game and #(ifndef(game.scene,{})) > 0 then
			local scene_list = {}
			local curr_scene = nil
			local curr_category = ''
			local curr_object = nil

			-- remove inactive states
			local scene_names = {}
			_iterateGameGroup('scene', function(scene)
				if scene._is_active then
					table.insert(scene_list, scene)
					table.insert(scene_names, scene.name)
				end
			end)

			-- only show editor if at least one scene is ACTIVE
			if #scene_names > 0 then
				imgui.SetNextWindowSize(300,300,"FirstUseEver")
				imgui.Begin(string.format("scene editor (%d,%d) %d,%d###scene editor", BlankE._mouse_x, BlankE._mouse_y, mouse_x, mouse_y), true)

				-- enable/disable dragging camera
				if scene_list[curr_scene_index] ~= nil then
					local _scene = scene_list[curr_scene_index]
					local status, new_val = imgui.Checkbox("disable camera dragging", _scene._fake_view.disabled)
					if status then
						_scene._fake_view.disabled = new_val
					end 
				end

				-- scene selection
				status, new_scene_index = imgui.Combo("scene", curr_scene_index, scene_names, #scene_names);
				if status then
					curr_scene_index = new_scene_index
				end
				curr_scene = scene_list[curr_scene_index]

				if imgui.CollapsingHeader("Place") then
					-- category selection
					local category_names = {}
					local img_list = {}
					local objects = {}
					for c, cat in ipairs(placeable) do
						objects[cat] = {}
						--[[
						if game[cat] and #game[cat] > 0 then
							objects[cat] = game[cat]
							table.insert(category_names, cat)
						end
						]]--

						if IDE.modules[cat] then
							objects[cat] = IDE.modules[cat].getObjectList()
							if #objects[cat] > 0 then
								table.insert(category_names, cat)
							end
						end

					end
					imgui.Text(" > ")
					imgui.SameLine()
					status, new_placer_index = imgui.Combo("category", curr_placer_index, category_names, #category_names);
					if status then
						curr_placer_index = new_placer_index
					end
					curr_category = placeable[curr_placer_index]

					-- object selection
					local object_list = objects[curr_category]
					if #object_list > 0 then
						imgui.Text("  >  ")
						imgui.SameLine()
						status, new_object_index = imgui.Combo("object", curr_object_index, object_list, #object_list);
						if status then
							curr_object_index = new_object_index
						end
						curr_object = object_list[curr_object_index]
					end

					-- ENTITY
					if curr_category == 'entity' then
						curr_scene:setPlacer('entity', curr_object)
					end

					-- IMAGE
					if curr_category == 'image' then
						--
					end
				end

				if imgui.CollapsingHeader("List") then
					for o, obj in ipairs(placeable) do
						if obj == 'entity' then
							local obj_list = curr_scene:getList('entity')
							for layer, entities in pairs(obj_list) do
								if imgui.TreeNode(layer) then
									for e, ent in ipairs(entities) do
										local clicked = false
										local flags = {'OpenOnArrow'}

										if selected_entity == ent.uuid then
											table.insert(flags, 'Selected')
											curr_scene:focusEntity(ent)
										end

										if imgui.TreeNodeEx(string.format('%s (%d,%d)', ent.classname, ent.x, ent.y)..'###'..ent.uuid, flags) then
            								imgui.BeginChild(ent.uuid, 0, 150, false);

	        								if imgui.SmallButton("delete") then
	        									ent:destroy()
	        								end

											for var, value in pairs(ent) do
												if not var:starts('_') then
													if type(value) == 'number' then
		        										imgui.PushItemWidth(80)
														status, new_int = imgui.DragInt(var,ent[var])
														if status then ent[var] = new_int end
													end
													if type(value) == 'string' then
		        										imgui.PushItemWidth(80)
														status, new_str = imgui.InputText(var,ent[var],300)
														if status then ent[var] = new_str end
													end
												end
											end
											imgui.EndChild()
											imgui.TreePop()
										end

										if imgui.IsItemHovered() then
											ent.show_debug = true
										elseif selected_entity ~= ent.uuid then
											ent.show_debug = false
										end

										-- camera focus/highlight on entity selection
										if imgui.IsItemClicked() then
											if selected_entity == ent.uuid then
												selected_entity = nil
												curr_scene:focusEntity()
											else
												selected_entity = ent.uuid
											end
										end
									end
								end
							end
						end
					end
				end

				imgui.End()
			end
		end
	end
}

return ideScene