local curr_scene_index = 1
local curr_placer_index = 1
local curr_object_index = 1

local placeable = {'entity','image','hitbox'}

local ideScene = {
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
				imgui.Begin(string.format("scene editor (%d,%d)###scene editor", BlankE._mouse_x, BlankE._mouse_y), true)

				-- scene selection
				status, new_scene_index = imgui.Combo("scene", curr_scene_index, scene_names, #scene_names);
				if status then
					curr_scene_index = new_scene_index
				end
				curr_scene = scene_list[curr_scene_index]

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

				imgui.End()
			end
		end
	end
}

return ideScene