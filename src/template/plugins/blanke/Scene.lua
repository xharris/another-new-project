local _btn_place
local _btn_drag
local _btn_remove
local _btn_confirm
local _btn_no_snap
local _btn_zoom_in

local _last_place = {nil,nil}
local _place_type
local _place_obj
local _place_layer

local _dragging = false
local _view_initial_pos = {0,0}
local _initial_mouse_pos = {0,0}

local _grid_gradient = false

local layer_template = {entity={},tile={},hitbox={}}

-- hitbox placing
local hitbox_points = {}
local hitbox_rem_point = true

-- special type of hashtable that groups objects with similar coordinates
local Scenetable = Class{
	init = function(self)
		self.data = {}
	end,
	hash = function(self, x, y)
		return tostring(x)..','..tostring(y)
	end,
	hash2 = function(self, obj)
		return tostring(obj)
	end,
	add = function(self, x, y, obj)
		local hash_value = self:hash(x, y)
		local hash_obj = self:hash2(obj)

		self.data[hash_value] = ifndef(self.data[hash_value], {})
		self.data[hash_value][hash_obj] = obj
	end,
	-- returns a table containing all objects at a coordinate
	search = function(self, x, y) 
		local hash_value = self:hash(x, y)
		return ifndef(self.data[hash_value],{})
	end,
	delete = function(self, x, y, obj)
		local hash_value = self:hash(x, y)
		local hash_obj = self:hash2(obj)

		if self.data[hash_value] ~= nil then
			if self.data[hash_value][hash_obj] ~= nil then
				local obj = table.copy(self.data[hash_value][hash_obj])
				self.data[hash_value][hash_obj] = nil
				return obj
			end
		end
	end,
	exportList = function(self)
		local ret_list = {}
		for key1, tile_group in pairs(self.data) do
			for key2, tile in pairs(tile_group) do
				table.insert(ret_list, tile)
			end
		end
		return ret_list
	end,
}

Scene = Class{
	hitbox = {},
	_zoom_amt = 1,
	_fake_view_start = {game_width/2, game_height/2},
	init = function(self, name)
		self.load_objects = {}
		self.layers = {}
		self.images = {}
		self.name = name
		self._snap = {32,32}
		self._delete_similar = true

		self.hash_tile = Scenetable()

		if BlankE._ide_mode then
			_btn_place = Input('mouse.1')
			_btn_drag = Input('mouse.3','space')
			_btn_remove = Input('mouse.2')
			_btn_confirm = Input('return','kpenter')
			_btn_no_snap = Input('lctrl','rctrl')
			_btn_zoom_in = Input('wheel.up')
			_btn_zoom_out = Input('wheel.down')

			self._fake_view = View()
			self._fake_view.nickname = '_fake_view'
			BlankE.setGridCamera(self._fake_view)
			BlankE.initial_cam_pos = {0,0}
			--self._fake_view.port_width, self._fake_view.port_height = love.window.getDesktopDimensions()
			self._fake_view.noclip = true
			self._fake_view:moveToPosition(Scene._fake_view_start[1], Scene._fake_view_start[2])
			self._fake_view.motion_type = 'smooth' -- (not working as intended)		
		end

		if name and assets[name] then
			self:load(assets[name]())
		end

		self.draw_hitboxes = false
		self.show_debug = false
		_addGameObject('scene',self)
	end,

	-- returns json
	export = function(self, path)
		local output = {layers={},objects={}}

		for layer, data in pairs(self.layers) do
			output.layers[layer] = {}

			for obj_type, objects in pairs(data) do
				local out_layer = {}
				for o, obj in ipairs(objects) do
					if obj._loadedFromFile and not obj._destroyed then
						if obj_type == 'entity' then
							local ent_data = {
								classname=obj.classname,
								x=obj.xstart,
								y=obj.ystart
							}
							table.insert(out_layer, ent_data)
						end

						if obj_type == 'hitbox' then
							local hit_data = {
								name=obj:getTag(),
								points=obj.args
							}
							table.insert(out_layer, hit_data)
						end
					end
				end
				output.layers[layer][obj_type] = out_layer
			end
		end

		-- save tiles
		local tiles = self.hash_tile:exportList()

		for t, tile in pairs(tiles) do
			output.layers[tile.layer] = ifndef(output.layers[tile.layer],{})
			output.layers[tile.layer]['tile'] = ifndef(output.layers[tile.layer]['tile'],{})
			local img_data = {
				x=tile.x,
				y=tile.y,
				img_name=tile.img_name,
				crop=tile.crop,
			}
			table.insert(output.layers[tile.layer].tile, img_data)
		end

		-- save hitboxes
		output.objects['hitbox'] = Scene.hitbox
		output.objects['layers'] = self.load_objects.layers

		return json.encode(output)
	end,

	load = function(self, path, compressed)
		scene_string = love.filesystem.read(path)
		scene_data = json.decode(scene_string)

		self.load_objects = scene_data["objects"]
		Scene.hitbox = self.load_objects.hitbox

		for l, layer in ipairs(self.load_objects.layers) do
			layer = self:_checkLayerArg(layer)
			local data = scene_data.layers[layer]
			
			if not _place_layer then
				self:setPlaceLayer(layer)
			end
			self.layers[layer] = table.copy(layer_template)

			if data["entity"] then
				for i_e, entity in ipairs(data["entity"]) do
					if _G[entity.classname] then
						Entity.x = entity.x
						Entity.y = entity.y
						local new_entity = _G[entity.classname](entity.x, entity.y)
						new_entity._loadedFromFile = true
						Entity.x = 0
						Entity.y = 0

						self:addEntity(new_entity, layer)
					end
				end
			end

			if data["tile"] then
				for i_i, tile in ipairs(data["tile"]) do
					self:addTile(tile.img_name, tile.x, tile.y, tile.crop, layer, true)
				end
			end

			if data["hitbox"] then
				for i_h, hitbox in ipairs(data["hitbox"]) do

					-- turn points into array
					--hitbox.points = hitbox.points:split(',')

					local new_hitbox = self:addHitbox(hitbox.name, {points=hitbox.points}, layer)
					new_hitbox._loadedFromFile = true
				end
			end
		end
		return self
	end,

	_checkLayerArg = function(self, layer)
		if layer == nil then
			return self:_checkLayerArg(0)
		end
		if type(layer) == "number" then
			layer = "layer"..tostring(layer)
			self.layers[layer] = ifndef(self.layers[layer],table.copy(layer_template))
		end

		self.load_objects.layers = ifndef(self.load_objects.layers,{})
		if not table.has_value(self.load_objects.layers, layer) then
			table.insert(self.load_objects.layers, layer)
		end

		return layer
	end,

	getList = function(self, obj_type) 
		local obj_list = {}
		if obj_type == 'layer' then
			return ifndef(self.load_objects.layers,{})
		else
			for layer, data in pairs(self.layers) do
				obj_list[layer] = data[obj_type]
			end
		end
		return obj_list
	end,

	addLayer = function(self)
		local layer_list = self.load_objects.layers
		local layer_num = #layer_list
		local valid_name = false
		local layer_name = 'layer'..layer_num

		while not valid_name do
			valid_name = true
			for l, layer in ipairs(layer_list) do
				if layer == layer_name then
					valid_name = false
					layer_num = layer_num + 1
					layer_name = 'layer'..layer_num
				end
			end
		end

		self.load_objects['layers'] = ifndef(layer_list, {})
		table.insert(self.load_objects.layers, layer_name)
		self.layers[layer_name] = table.copy(layer_template)
		self:setPlaceLayer(layer_name)
	end,

	removeLayer = function(self)
		local layer_index = table.find(self.load_objects.layers, _place_layer)
		local layer_name = self.load_objects.layers[layer_index]
		self.layers[layer_name] = nil
		table.remove(self.load_objects.layers, layer_index)
	end,

	getPlaceLayer = function(self)
		return _place_layer
	end,

	setPlaceLayer = function(self, layer_num)
		_place_layer = self:_checkLayerArg(layer_num)
	end,

	moveLayerUp = function(self)
		-- get position of current layer
		local curr_layer_pos = 1
		for l, layer in ipairs(self.load_objects.layers) do
			if layer == _place_layer then
				curr_layer_pos = l
			end
		end

		-- able to move the layer up anymore?
		if curr_layer_pos > 1 then
			-- switch their contents
			local prev_layer = self.load_objects.layers[curr_layer_pos-1]
			local curr_layer = self.load_objects.layers[curr_layer_pos]
			self.load_objects.layers[curr_layer_pos] = prev_layer
			self.load_objects.layers[curr_layer_pos-1] = curr_layer
		end
	end,

	moveLayerDown = function(self)
		-- get position of current layer
		local curr_layer_pos = 1
		for l, layer in ipairs(self.load_objects.layers) do
			if layer == _place_layer then
				curr_layer_pos = l
			end
		end

		-- able to move the layer up anymore?
		if curr_layer_pos < #self.load_objects.layers then
			-- switch their contents
			local prev_layer = self.load_objects.layers[curr_layer_pos+1]
			local curr_layer = self.load_objects.layers[curr_layer_pos]
			self.load_objects.layers[curr_layer_pos] = prev_layer
			self.load_objects.layers[curr_layer_pos+1] = curr_layer
		end
	end,

	addEntity = function(self, ...)
		local args = {...}
		local ret_ent
		if type(args[1]) == "string" then
			ret_ent = self:_addEntityStr(unpack(args))
		end
		if type(args[1]) == "table" then
			ret_ent = self:_addEntityTable(unpack(args))
		end
		if ret_ent then
			ret_ent:update(0)
		end
		return ret_ent
	end,

	_addEntityTable = function(self, entity, layer) 
		layer = self:_checkLayerArg(layer)

		self.layers[layer]["entity"] = ifndef(self.layers[layer]["entity"], {})
		table.insert(self.layers[layer].entity, entity)
	end,

	_addEntityStr = function(self, ent_name, x, y, layer, width, height)
		Entity.x = x
		Entity.y = y
		local new_entity = _G[ent_name](x, y, width, height)
		Entity.x = 0
		Entity.y = 0
		--new_entity.x = x
		--new_entity.y = y
		self:_addEntityTable(new_entity, layer)

		return new_entity
	end,

	addTile = function(self, img_name, x, y, img_info, layer, from_file) 
		layer = self:_checkLayerArg(layer)

		--if Image.exists(img_name) then
			-- check if the spritebatch exists yet
			self.layers[layer]["tile"] = ifndef(self.layers[layer]["tile"], {})
			self.images[img_name] = ifndef(self.images[img_name], Image(img_name))
			self.layers[layer].tile[img_name] = ifndef(self.layers[layer].tile[img_name], love.graphics.newSpriteBatch(self.images[img_name]()))

			-- add tile to batch
			local spritebatch = self.layers[layer].tile[img_name]
			local sb_id = spritebatch:add(love.graphics.newQuad(img_info.x, img_info.y, img_info.width, img_info.height, self.images[img_name].width, self.images[img_name].height), x, y)

			-- add tile info to "hashtable"
			self.hash_tile:add(x-(x%self._snap[1]),y-(y%self._snap[2]),
			{
				layer=layer,
				x=x,
				y=y,
				img_name=img_name,
				crop=img_info,
				id=sb_id,
				from_file=from_file
			})
		--end
		return self
	end,

	-- returns list of tile_data
	getTile = function(self, x, y, layer, img_name)
		x = x-(x%self._snap[1])
		y = y-(y%self._snap[2])
		layer = self:_checkLayerArg(layer)
		local ret_tiles = {}

		local tiles = self.hash_tile:search(x, y)
		for hash, tile in pairs(tiles) do
			local can_return = true

			if tile.layer ~= layer then
				can_return = false
			end
			if img_name and self._delete_similar and tile.img_name ~= img_name then
				can_return = false
			end

			if can_return then
				table.insert(ret_tiles, tile)
			end
		end

		return ret_tiles
	end,

	-- same as getTile but returns list of Image()
	getTileImage = function(self, x, y, layer, img_name)
		local ret_tiles = self:getTile(x,y,layer,img_name)
		for t, tile in pairs(ret_tiles) do
			ret_tiles[t] = self:tileToImage(tile)
		end
		return ret_tiles
	end,

	tileToImage = function(self, tile_data)
		local img = self.images[tile_data.img_name]
		local quad = love.graphics.newQuad(
			tile_data.crop.x, 		tile_data.crop.y,
			tile_data.crop.width,	tile_data.crop.height,
			img.width,				img.height)
		return img:crop(tile_data.crop.x, tile_data.crop.y, tile_data.crop.width, tile_data.crop.height)
	end,

	removeTile = function(self, x, y, layer, img_name)
		local rm_tiles = self:getTile(x,y,layer,img_name)

		-- remove them from spritebatches
		for l_name, it_layer in pairs(self.layers) do
			if layer == l_name then
				for t, tile in ipairs(rm_tiles) do
					self.hash_tile:delete(x, y, tile)
					it_layer.tile[tile.img_name]:set(tile.id, 0, 0, 0, 0, 0)
				end
			end
		end
		return self
	end,

	getHitboxType = function(self, name)
		for h, hitbox in pairs(Scene.hitbox) do
			if hitbox.name == name then
				return hitbox
			end
		end
	end,

	addBlankHitboxType = function(self)
		local new_name = self:validateHitboxName('hitbox'..tostring(#Scene.hitbox))

		self:setHitboxInfo(new_name,{
			color={255,255,255,255},
			uuid=uuid()
		})
		return self
	end,

	validateHitboxName = function(self, new_name)
		local count = 1
		while self:getHitboxType(new_name) ~= nil do
			new_name = new_name..tostring(count)
			count = count + 1
		end
		return new_name
	end,

	renameHitbox = function(self, old_name, new_name) 
		for h, hitbox in pairs(Scene.hitbox) do
			if hitbox.name == old_name then
				hitbox.name = self:validateHitboxName(new_name)
				return hitbox
			end
		end
	end,

	setHitboxInfo = function(self, name, info)
		local found = false
		for h, hitbox in pairs(Scene.hitbox) do
			if hitbox.name == name then
				hitbox = info
				found = true
			end
		end

		if not found then
			info.name = name
			table.insert(Scene.hitbox, info)
		end
	end,

	addHitbox = function(self, hit_name, hit_info, layer) 
		layer = self:_checkLayerArg(layer)

		-- hitboxes are accessable to all scenes
		local hitbox_info = self:getHitboxType(hit_name)
		if not hitbox_info then
			self:setHitboxInfo(hit_name,{
				name=hit_name,
				color=hit_info.color,
				uuid=uuid()
			})
			hitbox_info = self:getHitboxType(hit_name)
		end

		self.layers[layer]["hitbox"] = ifndef(self.layers[layer]["hitbox"], {})
		local new_hitbox = Hitbox("polygon", hit_info.points, hit_name)
		new_hitbox:setColor(hitbox_info.color)
		new_hitbox.hitbox_uuid = hit_info.uuid
		table.insert(self.layers[layer].hitbox, new_hitbox)

		return new_hitbox
	end,

	removeHitboxAtPoint = function(self, x, y, in_layer)
		in_layer = self:_checkLayerArg(in_layer)

	    for l_name, layer in pairs(self.layers) do
	    	for h, hitbox in ipairs(layer.hitbox) do
				if l_name == in_layer and hitbox:pointTest(x, y) then
					hitbox:destroy()
					table.remove(self.layers[in_layer].hitbox, h)
				end
			end
		end
	end,

	getEntity = function(self, in_entity, in_layer)
		local entities = {}
		for name, layer in pairs(self.layers) do
			if in_layer == nil or in_layer == layer then
				for i_e, entity in ipairs(layer.entity) do
					if entity.classname == in_entity then
						table.insert(entities, entity)
					end
				end
			end
		end

		if #entities == 1 then
			return entities[1]
		end
			return entities
	end,

	_getMouseXY = function(self, dont_snap)
		dont_snap = ifndef(dont_snap, _btn_no_snap())

		local cam_x, cam_y
		local place_cam = ifndef(BlankE.main_cam, self._fake_view)
		if not place_cam.disabled then
			cam_x, cam_y = place_cam.camera:cameraCoords(place_cam:mousePosition())
			local cam_pos = {place_cam:position()}
			cam_x = cam_x - ((place_cam.port_width/2) - cam_pos[1])
			cam_y = cam_y - ((place_cam.port_height/2) - cam_pos[2])
		else
			cam_x, cam_y = mouse_x, mouse_y
		end
		local mx, my = cam_x*Scene._zoom_amt, cam_y*Scene._zoom_amt

		if not dont_snap then
			mx = mx-(mx%self._snap[1])
			my = my-(my%self._snap[2])
		end

		return {mx, my}
	end,

	update = function(self, dt) 
		-- update entities
		for name, layer in pairs(self.layers) do
			if layer.entity then
				for i_e, entity in ipairs(layer.entity) do
					if entity._destroyed then
						table.remove(layer.entity, i_e)
					else
						entity:update(dt)
					end
				end
			end

			if layer.hitbox then
				for i_h, hitbox in ipairs(layer.hitbox) do
					-- nothing at the moment
				end
			end
		end

		if BlankE._ide_mode then
			-- reset hitbox vars
	    	if _place_type ~= 'hitbox' or (_place_type == 'hitbox' and not _place_obj) then
				hitbox_points = {}
				hitbox_rem_point = true
	    	end

	    	-- placing object on click
	    	local _placeXY = self:_getMouseXY()
	    	BlankE._mouse_x, BlankE._mouse_y = unpack(_placeXY)
	    	if _btn_place() and _place_type then
	    		if _placeXY[1] ~= _last_place[1] or _placeXY[2] ~= _last_place[2] then
	    			_last_place = _placeXY

	    			if _place_type == 'entity' then
	    				local new_entity = self:addEntity(_place_obj, _placeXY[1], _placeXY[2], _place_layer)
	    				if new_entity then
	    					new_entity._loadedFromFile = true
	    				end
	    			end
	    			
	    			if _place_type == 'image' then
	    				local new_tile = self:addTile(_place_obj.img_name, _placeXY[1], _placeXY[2], _place_obj, _place_layer, true)
	    			end

	    			if _place_type == 'hitbox' then
	    				table.insert(hitbox_points, _placeXY[1])
	    				table.insert(hitbox_points, _placeXY[2])
	    			end
	    		end
	    	end

	    	-- removing objects on click
	    	if _btn_remove() and _place_type then
				_last_place = {nil,nil}
	    		if _place_type == 'image' then
	    			self:removeTile(_placeXY[1], _placeXY[2], _place_layer, _place_obj.img_name)
	    		end

	    		if _place_type == 'hitbox' then
	    			if #hitbox_points > 0 and hitbox_rem_point then
		    			table.remove(hitbox_points, #hitbox_points)
		    			table.remove(hitbox_points, #hitbox_points)
		    			hitbox_rem_point = false
		    		elseif #hitbox_points == 0 and hitbox_rem_point then -- added 'hitbox_rem_point' and it just happened to work here
		    			local new_mx, new_my = unpack(_getMouseXY(true))
					    self:removeHitboxAtPoint(new_mx, new_my)
		    		end
	    		end
	    	else
	    		if _place_type == 'hitbox' then
	    			hitbox_rem_point = true
	    		end
	    	end

	    	-- zooming in and out
	    	if _btn_zoom_in() then
	    		Scene._zoom_amt = clamp(Scene._zoom_amt - 0.1, 0, 3)
	    	end

	    	if _btn_zoom_out() then
	    		Scene._zoom_amt = clamp(Scene._zoom_amt + 0.1, 0, 3)
	    	end
	    	self._fake_view:zoom(Scene._zoom_amt)
	    	self._fake_view.port_width = game_width
	    	self._fake_view.port_height = game_height
	    	
	    	-- dragging the view/grid around
	    	BlankE.setGridSnap(self._snap[1], self._snap[2])
	    	if not self._fake_view.disabled then
	    		View._disable_grid = true
				BlankE.setGridCamera(self._fake_view)
		    	if _btn_drag() then
		    		-- on down
			    	if not _dragging then
			    		_dragging = true
			    		_view_initial_pos = {self._fake_view:position()}
			    		_initial_mouse_pos = {mouse_x, mouse_y}
			    		--
			    	end
			    	-- on hold
			    	if _dragging then
			    		local _drag_dist = {mouse_x-_initial_mouse_pos[1], mouse_y-_initial_mouse_pos[2]}
			    		self._fake_view:moveToPosition(
			    			_view_initial_pos[1] - _drag_dist[1],
			    			_view_initial_pos[2] - _drag_dist[2]
			    		)
			    		Scene._fake_view_start = {self._fake_view:position()}
			    	end
			    end
		    	-- on release
		    	if not _btn_drag() and _dragging then
		    		_dragging = false
		    	end
		    else
		    	View._disable_grid = false
		    end

		    -- confirm button
		    if _btn_confirm() and not confirm_pressed then
		    	confirm_pressed = true

		    	if _place_type == 'hitbox' then
		    		if #hitbox_points >= 6 then
		    			-- make sure it's not a straight line
		    			local invalid = true
		    			local slope = 0

		    			for h=1,#hitbox_points-2,2 do
		    				local h1 = {hitbox_points[h], hitbox_points[h+1]}
		    				local h2 = {hitbox_points[h+2], hitbox_points[h+3]}

		    				local new_slope = (h2[2]-h1[2])/(h2[1]-h1[1])
		    				
		    				if slope ~= new_slope then
		    					slope = new_slope
		    					invalid = false
		    				end
		    			end

		    			if not invalid then
		    				local new_hitbox = self:addHitbox(_place_obj.name, {points=hitbox_points})
		    				new_hitbox._loadedFromFile = true
		    				hitbox_points = {}
		    				hitbox_rem_point = true
		    			end
		    		end
		    	end

		    elseif confirm_pressed then
		    	confirm_pressed = false
		    end


		end -- BlankE._ide_mode
	end,

	_real_draw = function(self)
		self._is_active = true

		for l, name in ipairs(self.load_objects.layers) do
			local layer = self.layers[name]

			if BlankE._ide_mode and _place_layer ~= name then
				love.graphics.push('all')
				love.graphics.setColor(255,255,255,255/2.5)
			end

			if layer.entity then
				for i_e, entity in ipairs(layer.entity) do
					entity.scene_show_debug = self.show_debug
					entity:draw()
				end
			end

			if layer.tile then
				for name, tile in pairs(layer.tile) do
					love.graphics.draw(tile)
				end
			end

			if BlankE._ide_mode and _place_layer ~= name then
				love.graphics.pop()
			end

			if layer.hitbox and (self.draw_hitboxes or (self.show_debug and not BlankE._ide_mode)) then
				for i_h, hitbox in ipairs(layer.hitbox) do
					hitbox:draw()
				end
			end
		end
	end,

	draw = function(self) 
	    if BlankE._ide_mode then
	    	self._fake_view:attach()
	    	self:_real_draw()

	    	-- draw hitbox being placed
	    	if _place_type == 'hitbox' and _place_obj and #hitbox_points > 0 then
		    	love.graphics.push('all')
		    	local color_copy = table.copy(_place_obj.color)
	    		color_copy[4] = 255/2
		    	for h=1,#hitbox_points,2 do
		    		love.graphics.setColor(unpack(color_copy))
		    		love.graphics.circle('fill', hitbox_points[h], hitbox_points[h+1], 2)
		    	end
	    		love.graphics.setColor(unpack(color_copy))
	    		if #hitbox_points == 4 then
	    			love.graphics.line(unpack(hitbox_points))
	    		elseif #hitbox_points > 4 then
	    			love.graphics.polygon('fill', unpack(hitbox_points))
	    		end
		    	love.graphics.pop()
		    end

		    -- draw hitboxes
		    for l_name, layer in pairs(self.layers) do
		    	if layer.hitbox then
			    	for h, hitbox in ipairs(layer.hitbox) do
			    		hitbox:draw()
			    	end
			    end
		    end

			--BlankE._drawGrid()
	    	self._fake_view:detach()
	    else
	    	self:_real_draw()
	    end
	end,

	focusEntity = function(self, ent)
		if self._fake_view then
			-- removing followed entity
			if ent == nil and self._fake_view.follow_entity then
				self._fake_view.follow_entity.show_debug = false
				self._fake_view.offset_x = 0
				self._fake_view.offset_y = 0
			end
			-- following entity
			if ent then
				-- TODO: offset not working as intended
				self._fake_view.offset_x = self._fake_view.port_width - game_width 
				self._fake_view.offset_y = self._fake_view.port_height - game_height
				ent.show_debug = true
			end

			self._fake_view:follow(ent)
		end
	end,

	setPlacer = function(self, type, obj)
		_place_type = type
		_place_obj = obj
	end,
}

return Scene