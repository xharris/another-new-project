local window_margin = 10
local titlebar_height = 20

local curr_scene_index = 1
local curr_placer_index = 1
local curr_object_index = 1
local last_object = nil
-- entity placing
local selected_entity = ''
local show_obj_debug = false
-- image placing
local _img_dragging = false
local _img_drag_init_mouse = {0,0}
local _img_snap = {32,32}
local drag_x=0
local drag_y=0
local drag_width=0
local drag_height=0
local delete_similar = true
-- hitbox placing
local selected_hitbox = nil

local placeable = {'entity','image','hitbox'}
local listable = {'entity','view','effect'}

local category_names = {}
local objects = {}
function refreshObjectList(only_cat) -- haha cats
	category_names = {}
	for c, cat in ipairs(placeable) do
		objects[cat] = {}

		if IDE.modules[cat] and IDE.modules[cat].getObjectList then
			objects[cat] = IDE.modules[cat].getObjectList()
		end

		if cat == 'entity' then
			objects[cat] = BlankE.getClassList('Entity')
		end
		
		if cat == 'hitbox' or #objects[cat] > 0 then
			table.insert(category_names, cat)
		end
	end
end

function writeSceneFiles()
	local ret_str = ''
	local scene_files = SYSTEM.scandir(IDE.getProjectPath()..'/assets/scene')

	for s, scene_file in ipairs(scene_files) do
		local scene_name = basename(scene_file)
		scene_name = scene_name:gsub(extname(scene_name),'')
		ret_str = ret_str..
			"function assets:"..scene_name..'()\n'..
			"\t return asset_path..\"assets/scene/"..scene_name..".json\"\n"..
			"end\n\n"
	end

	if BlankE and not IDE.errd and UI.getSetting("auto_save") then
		_iterateGameGroup('scene', function(scene, s)
			local scene_name = scene.name
			local scene_path = IDE.getProjectPath()..'/assets/scene/'..scene_name..'.json'
			local scene_data = scene:export(path)

			SYSTEM.mkdir(dirname(scene_path))
			local file = io.open(scene_path,"w+")
			file:write(scene_data)
			file:close()
		end)
	end
	return ret_str
end

function inspectObj(obj, title, flags)
	if imgui.TreeNodeEx(ifndef(title,obj.nickname)..'###'..obj.uuid, flags) then
		imgui.BeginChild(obj.uuid, 0, 180, false);

		for var, value in pairs(obj) do
			if not var:starts('_') then
				if type(value) == 'number' then
					imgui.PushItemWidth(100)
					status, new_int = imgui.DragFloat(var,obj[var])
					if status then obj[var] = new_int end
				end
				if type(value) == 'string' then
					imgui.PushItemWidth(100)
					status, new_str = imgui.InputText(var,obj[var],300)
					if status then obj[var] = new_str end
				end
				if type(value) == 'boolean' then
					local status, new_val = imgui.Checkbox(var, obj[var])
					if status then obj[var] = new_val end
				end
				if type(value) == 'table' then
					if #value == 2 then

					end
				end
			end
		end
		imgui.EndChild()
		imgui.TreePop()
	end
end

local ideScene = {
	getAssets = function()
		local ret_str = ''
		ret_str = ret_str .. writeSceneFiles()
		return ret_str..'\n'
	end,

	postReload = function()
		refreshObjectList()
	end,

	onAddGameObject = function(obj_type)
		local types = {
			Entity='entity',
			Hitbox='hitbox'
		}
		if types[obj_type] then
			refreshObjectList(types[obj_type])
		else
			refreshObjectList()
		end
	end,

	onRename = function(old_path, new_path)
		if string.match(old_path, "entity/") then
			old_name = basename(old_path):split(".")[1]
			new_name = basename(new_path):split(".")[1]
			Scene._renames[old_name] = new_name
		end
	end,

	draw = function()
		if UI.titlebar.show_scene_editor and game and #(ifndef(game.scene,{})) > 0 then
			local scene_list = {}
			local curr_scene = nil
			local curr_category = ''
			local curr_object = nil
			local scene_editor_width = 340

			-- remove inactive states
			local scene_names = {}
			_iterateGameGroup('scene', function(scene)
				if scene._is_active > 0 then
					table.insert(scene_list, scene)
					table.insert(scene_names, scene.name)
				end
			end)

			-- only show editor if at least one scene is ACTIVE
			if #scene_names > 0 then
				local _scene = scene_list[curr_scene_index] -- check if nil when using this var
				curr_scene = scene_list[curr_scene_index]

				imgui.SetNextWindowPos(game_width-scene_editor_width-window_margin, window_margin, {"Once"})
				imgui.SetNextWindowSize(scene_editor_width,game_height-UI.getSetting("console_height").value-(titlebar_height+window_margin), {"Once"})
				local cam_zoom = ifndef(Scene._zoom_amt,1)*100
				scene_status, UI.titlebar.show_scene_editor = imgui.Begin(string.format("scene editor (%d,%d) %d,%d %d%%###scene editor", BlankE._snap_mouse_x, BlankE._snap_mouse_y, BlankE._mouse_x, BlankE._mouse_y, cam_zoom), true)

				-- enable/disable dragging camera
				if _scene then
					local cam_status, new_cam = imgui.Checkbox("enable view dragging", View.global_drag_enable)
					if cam_status then
						View.global_drag_enable = new_cam
					end 

					local grid_status, new_grid = imgui.Checkbox("show grid", BlankE.show_grid)
					if grid_status then
						BlankE.show_grid = new_grid
					end

					local debug_status, new_obj_debug = imgui.Checkbox("show object debugs", curr_scene:getSetting("show_obj_debug", show_obj_debug))
					if debug_status then
						curr_scene:setSetting("show_obj_debug", new_obj_debug)
						show_obj_debug = new_obj_debug
					end
					_scene.show_debug = curr_scene:getSetting("show_obj_debug", show_obj_debug)
				end

				-- scene selection
				status, new_scene_index = imgui.Combo("scene", curr_scene_index, scene_names, #scene_names);
				if status then
					curr_scene_index = new_scene_index
				end

				local ide_snapx = UI.getSetting("scene_snap_x")
				local ide_snapy = UI.getSetting("scene_snap_y")

				local scene_snapx = curr_scene:getSetting('snap_x', ide_snapx.value)
				local scene_snapy = curr_scene:getSetting('snap_y', ide_snapy.value)
				curr_scene._snap = {scene_snapx, scene_snapy}

				if imgui.CollapsingHeader("Place") then

					if imgui.TreeNode('settings') then
						-- grid snapping setting
			        	imgui.Text("snap")
			            imgui.SameLine()
						imgui.PushItemWidth(80)
			            status_snapx, new_snapx = imgui.DragInt("###scene_snapx",scene_snapx,1,ide_snapx.min,ide_snapx.max,"x: %.0f")
			            if status_snapx then
			            	curr_scene._snap[1] = new_snapx
			                curr_scene:setSetting("snap_x", new_snapx)
			                _img_snap[1] = new_snapx
			            end
			            imgui.SameLine()
			            status_snapy, new_snapy = imgui.DragInt("###scene_snapy",scene_snapy,1,ide_snapy.min,ide_snapy.max,"y: %.0f")
			            if status_snapy then
			            	curr_scene._snap[2] = new_snapx
			                curr_scene:setSetting("snap_y", new_snapy)
			                _img_snap[2] = new_snapy
			            end
			            imgui.PopItemWidth()
			            imgui.TreePop()
			        end

					imgui.Separator()

					-- layer selection
					if UI.drawIconButton("arrow-up", "move layer up (farther)") then
						curr_scene:moveLayerUp()
					end
					imgui.SameLine();
					if UI.drawIconButton("arrow-down", "move layer down (closer)") then
						curr_scene:moveLayerDown()
					end
					imgui.SameLine();

					local curr_layer = curr_scene:getPlaceLayer()
					local layer_list = curr_scene:getList('layer')
					local curr_layer_index = 1
					for l, layer in ipairs(layer_list) do
						if layer == curr_layer then
							curr_layer_index = l
						end
					end

					layer_status, new_layer = imgui.Combo("", curr_layer_index, layer_list, #layer_list); imgui.SameLine();
					if layer_status then
						curr_scene:setPlaceLayer(layer_list[new_layer])
					end

					if UI.drawIconButton("plus", "add layer") then
						curr_scene:addLayer()
					end
					imgui.SameLine();
					if UI.drawIconButton("minus", "remove layer") then
						curr_scene:removeLayer()
					end

					imgui.Separator()

					-- category selection
					imgui.Text(" > ")
					imgui.SameLine()
					status, new_placer_index = imgui.Combo("category", curr_placer_index, category_names, #category_names);
					if status then
						curr_placer_index = new_placer_index
						curr_scene:setPlacer()
					end
					curr_category = placeable[curr_placer_index]

					-- object selection
					local object_list = ifndef(objects[curr_category],{})
					if curr_category ~= 'hitbox' and #object_list > 0 then
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

					-- IMAGE
					elseif curr_category == 'image' then
						local img_path = IDE.getShortProjectPath().."/assets/image/"..getImgPathByName(curr_object)
						local img, img_width, img_height = UI.loadImage(img_path) 
						
						function setImgPlacer()
							curr_scene:setPlacer('image', {
								img_name=curr_object,
								x=drag_x,
								y=drag_y,
								width=drag_width,
								height=drag_height
							})
						end	

						-- initial selection size
						if last_object ~= curr_object then
							last_object = curr_object
							drag_x = 0; drag_y = 0
							drag_width = img_width; drag_height = img_height
							setImgPlacer()
						end
						
						_img_snap = {curr_scene:getSetting(curr_object.."_x", scene_snapx), curr_scene:getSetting(curr_object.."_y", scene_snapy)}
						if imgui.TreeNode('tile settings') then

							imgui.BeginGroup()
							imgui.Text("tile size")
							imgui.SameLine()
							imgui.PushItemWidth(80)

							-- tile size (even though I named the vars snap)
							status_img_snapx, new_img_snapx = imgui.DragInt("###img_tilew",_img_snap[1],1,1,img_width,"w: %.0f")
				            if status_img_snapx then
				            	curr_scene:setSetting(curr_object.."_x", new_img_snapx)
				            	_img_snap[1] = new_img_snapx
				            end
				            imgui.SameLine()
				            status_img_snapy, new_img_snapy = imgui.DragInt("###img_tileh",_img_snap[2],1,1,img_height,"h: %.0f")
				            if status_img_snapy then
				            	curr_scene:setSetting(curr_object.."_y", new_img_snapy)
				            	_img_snap[2] = new_img_snapy
				            end

				            imgui.PopItemWidth()
				            imgui.EndGroup()

							if imgui.IsItemHovered() then
				            	imgui.BeginTooltip()
				            	local img, img_width, img_height = UI.loadImage(img_path) 
								imgui.Image(img, _img_snap[1], _img_snap[2], 0, 0, (_img_snap[1])/img_width, (_img_snap[2])/img_height, 255, 255, 255, 255, UI.getColor('love2d'))
								imgui.EndTooltip()
				            end

				            -- only delete similar tiles
				            if imgui.Checkbox("only delete similar tiles", delete_similar) then
				            	delete_similar = not delete_similar
				            end
				            curr_scene._delete_similar = delete_similar

				            imgui.TreePop()
				        end
				            
						if imgui.Button("All") then
							drag_x = 0; drag_y = 0
							drag_width = img_width; drag_height = img_height
							setImgPlacer()
						end
						imgui.SameLine()
						if imgui.Button("Clear") then
							drag_x = 0; drag_y = 0
							drag_width = 0; drag_height = 0
							setImgPlacer()
						end

						if drag_x == 0 and drag_y == 0 and drag_width == 0 and drag_height == 0 then
							imgui.TextColored(244/255,67/255,54/255,255/255, "no tiles selected")
						else
							imgui.Text(string.format('x:%d y:%d, w:%d h:%d', drag_x, drag_y, drag_width, drag_height))
						end

						UI.drawImageButton(img_path, 0, 0, 1, 1, 0, 255, 255, 255, 255)

						function _getMouseDragPos()
							local mousepos_x, mousepos_y = imgui.GetMousePos()
							local screenpos_x, screenpos_y = imgui.GetCursorScreenPos()
							local _mouse_x = mousepos_x-screenpos_x
							local _mouse_y = mousepos_y-screenpos_y+img_height+3

							return _mouse_x, _mouse_y
						end

						if imgui.IsMouseDown(0) and imgui.IsItemHovered() then
							-- mouse pressed
							if not _img_dragging then
								_img_dragging = true
								_img_drag_init_mouse = {_getMouseDragPos()}

								-- not allowed to be below 0
								if _img_drag_init_mouse[1] < 0 then _img_drag_init_mouse[1] = 0 end
								if _img_drag_init_mouse[2] < 0 then _img_drag_init_mouse[2] = 0 end

								drag_x = _img_drag_init_mouse[1] - (_img_drag_init_mouse[1]%_img_snap[1])
								drag_y = _img_drag_init_mouse[2] - (_img_drag_init_mouse[2]%_img_snap[2])
								drag_width = img_width
								drag_height = img_height

								setImgPlacer()

							-- mouse dragging
							else
								local mouse_pos = {_getMouseDragPos()}
								drag_width = mouse_pos[1] - _img_drag_init_mouse[1] + _img_snap[1]
								drag_height = mouse_pos[2] - _img_drag_init_mouse[2] + _img_snap[2]

								drag_width = drag_width - (drag_width % _img_snap[1])
								drag_height = drag_height - (drag_height % _img_snap[2])

								-- size cannot be less than initial position
								if drag_width < 0 then drag_width = 0 end
								if drag_height < 0 then drag_height = 0 end

								if drag_width+drag_x > img_width then drag_width = img_width - drag_x end
								if drag_height+drag_y > img_height then drag_height = img_height - drag_y end

								setImgPlacer()
							end

						elseif _img_dragging then
							-- mouse released
							_img_dragging = false

						end

						if imgui.IsItemHovered() then
							imgui.BeginTooltip()

							local _mouse_x, _mouse_y = _getMouseDragPos()

							-- not allowed to be below 0
							if _mouse_x < 0 then _mouse_x = 0 end
							if _mouse_y < 0 then _mouse_y = 0 end

							_mouse_x = _mouse_x - (_mouse_x%_img_snap[1])
							_mouse_y = _mouse_y - (_mouse_y%_img_snap[2])

							local img, img_width, img_height = UI.loadImage(img_path) 
							imgui.Image(img, drag_width, drag_height, drag_x/img_width, drag_y/img_width, (drag_x+drag_width)/img_width, (drag_y+drag_height)/img_height, 255, 255, 255, 255, UI.getColor('love2d'))

							imgui.EndTooltip()
						end

					elseif curr_category == 'hitbox' then
						if imgui.Button("Add") then
							curr_scene:addBlankHitboxType()
							refreshObjectList()
						end
						imgui.SameLine()

						-- show currently selected hitbox
						local hitbox_name = '-'
						local sel_color_copy = {UI.getElement('Text')}
						if selected_hitbox then
							sel_color_copy = table.copy(selected_hitbox.color)
							sel_color_copy = {sel_color_copy[1]/255, sel_color_copy[2]/255, sel_color_copy[3]/255, 255/3}
							hitbox_name = selected_hitbox.name
						end
						imgui.Text("Selected: ")
						imgui.SameLine()
						imgui.TextColored(sel_color_copy[1],sel_color_copy[2],sel_color_copy[3],sel_color_copy[4], hitbox_name)
						for o, obj in ipairs(object_list) do
							local hitbox = curr_scene:getHitboxType(obj)
							local color_copy = {}
							if hitbox then
								color_copy = table.copy(hitbox.color)
								local r, g, b = color_copy[1]/255, color_copy[2]/255, color_copy[3]/255
								imgui.PushStyleColor("Text", r, g, b, 255)
							end

							-- hitbox options
							if hitbox and imgui.TreeNodeEx(hitbox.name..'###'..hitbox.uuid, {'OpenOnArrow'}) then
								imgui.PushStyleColor("Text", UI.getElement("Text"))
								-- name
								local name_status, new_name = imgui.InputText("name",hitbox.name,300)
					            if name_status then
					            	curr_scene:renameHitbox(hitbox.name, new_name)
					            	refreshObjectList('hitbox')
					            end

								-- color
								local r, g, b = unpack(hitbox.color)
								local color_status, r, g, b = imgui.ColorEdit3("color", r/255, g/255, b/255)
								if color_status then
									hitbox.color = {r*255, g*255, b*255, 255/3}
									Hitbox._color[hitbox.name] = hitbox.color
								end

								imgui.TreePop()
							elseif hitbox then
								imgui.PushStyleColor("Text", UI.getElement("Text"))
							end

							if hitbox and imgui.IsItemClicked() then
								-- selecting hitbox
								if not selected_hitbox or selected_hitbox.name ~= hitbox.name then
									selected_hitbox = hitbox
								-- deselecting hitbox
								elseif selected_hitbox and selected_hitbox.name == hitbox.name then
									selected_hitbox = nil
								end
								curr_scene:setPlacer('hitbox', selected_hitbox)
							end
						end
					else
						curr_scene:setPlacer()
					end
				else
					curr_scene:setPlacer()
					selected_entity = ''
					selected_hitbox = nil
				end

				if imgui.CollapsingHeader("List") then
					for o, obj in ipairs(listable) do

							if obj == 'entity' then
								local obj_list = curr_scene:getList(obj)
								local obj_count = 0
								for layer, data in pairs(obj_list) do
									obj_count = obj_count + #data
								end
								if imgui.TreeNode(string.format(obj..' (%d)###'..curr_scene.name..'_entity', obj_count)) then
							
									for layer, entities in pairs(obj_list) do
										if imgui.TreeNode(string.format(layer..' (%d)###'..layer,#entities)) then
											for e, ent in ipairs(entities) do

												if not ent._destroyed then
													local clicked = false
													local flags = {'OpenOnArrow'}

													if selected_entity == ent.uuid then
														table.insert(flags, 'Selected')
													end

													inspectObj(ent, string.format('%s (%d,%d)', ifndef(ent.nickname, ent.classname), ent.x, ent.y), flags)

													if imgui.IsItemHovered() then
														ent.show_debug = true

														if imgui.IsKeyReleased(10) or imgui.IsKeyReleased(11) then	
				        									ent:destroy()
														end

													elseif selected_entity ~= ent.uuid then
														ent.show_debug = false
													end

													--[[ camera focus/highlight on entity selection (TODO: BUGGY)
													if imgui.IsItemClicked() then
														if selected_entity == ent.uuid then
															selected_entity = nil
															curr_scene:focusEntity()
														else
															selected_entity = ent.uuid
															curr_scene:focusEntity(ent)
														end
													end]]
												end

											end
											imgui.TreePop()
										end
									end

								imgui.TreePop()
								end
							end

							if obj == 'view' and imgui.TreeNode(obj) then
								_iterateGameGroup('view', function(view, v)
									if view.nickname ~= '_fake_view' and not view._destroyed then
										inspectObj(view, ifndef(view.nickname, 'view'..v))
									end
								end)

								imgui.TreePop()
							end

							if obj =='effect' and imgui.TreeNode(obj) then
								_iterateGameGroup('effect', function(effect, v)
									if not effect._destroyed then
										inspectObj(effect, ifndef(effect.name, 'effect'..v))
									end
								end)

								imgui.TreePop()
							end
					end
				end

				imgui.End()
			end
		end
	end
}

return ideScene