local _btn_place
local _btn_drag
local _btn_remove
local _btn_confirm

local _last_place = {nil,nil}
local _place_type
local _place_obj
local _place_layer = 0

local _dragging = false
local _view_initial_pos = {0,0}
local _initial_mouse_pos = {0,0}

local _grid_gradient = false

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
	init = function(self, name)
		self.load_objects = {}
		self.layers = {}
		self.images = {}
		self.name = name
		self._snap = {32,32}

		self.hash_tile = Scenetable()

		if BlankE._ide_mode then
			_btn_place = Input('mouse.1')
			_btn_drag = Input('mouse.3','space')
			_btn_remove = Input('mouse.2')
			_btn_confirm = Input('return','kpenter')

			self._fake_view = View()
			self._fake_view.port_width, self._fake_view.port_height = love.window.getDesktopDimensions()
			self._fake_view:moveToPosition(self._fake_view.port_width/2,self._fake_view.port_height/2)
			self._fake_view.motion_type = 'smooth' -- (not working as intended)
		end

		if name and assets[name] then
			self:load(assets[name]())
		end

		self.draw_hitboxes = false
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
					if obj._loadedFromFile then
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

		return json.encode(output)
	end,

	load = function(self, path, compressed)
		scene_string = love.filesystem.read(path)
		scene_data = json.decode(scene_string)

		self.load_objects = scene_data["objects"]
		Scene.hitbox = self.load_objects.hitbox

		for layer, data in pairs(scene_data["layers"]) do
			self.layers[layer] = {entity={},tile={},hitbox={}}

			if data["entity"] then
				for i_e, entity in ipairs(data["entity"]) do
					Entity.x = entity.x
					Entity.y = entity.y
					local new_entity = _G[entity.classname](entity.x, entity.y)
					new_entity._loadedFromFile = true
					Entity.x = 0
					Entity.y = 0

					self:addEntity(new_entity, layer)
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
	end,

	_drawGrid = function(self)
		local min_grid_draw = 8
		local grid_alpha = 30

		local g_x, g_y
    	if not self._fake_view.disabled then
	    	g_x, g_y = self._fake_view:position()
	    	g_x = (self._fake_view.port_width/2) - g_x
	    	g_y = (self._fake_view.port_height/2) - g_y
	    else
	    	g_x, g_y = 0, 0
	    end

    	local offx, offy = (g_x%self._snap[1]), (g_y%self._snap[2])

    	local offset = 0
    	local function myStencilFunction() -- TODO: change to shader?
    		local conf_w, conf_h = CONF.window.width+(offset*2), CONF.window.height+(offset*2)

    		local rect_x = (game_width/2)-(conf_w/2)+offset
    		local rect_y = (game_height/2)-(conf_h/2)+offset

		   	love.graphics.rectangle("fill", rect_x, rect_y, conf_w, conf_h)
		end

		local function stencilLine(func)
			-- outside view line
    		love.graphics.setColor(255,255,255,grid_alpha)
			love.graphics.setLineWidth(1)
			func()

			-- bold in-view line
			if _grid_gradient then
    			for o = 0,15,1 do
    				offset = -o
		    		love.graphics.setColor(255,255,255,2)
		    		love.graphics.stencil(myStencilFunction, "replace", 1)
				 	love.graphics.setStencilTest("greater", 0)
				 	love.graphics.setLineWidth(1)
				 	func()
		    		love.graphics.setStencilTest()
    			end
    		else 
    			offset = 0
				love.graphics.setColor(255,255,255,grid_alpha+20)
	    		love.graphics.stencil(myStencilFunction, "replace", 1)
			 	love.graphics.setStencilTest("greater", 0)
			 	love.graphics.setLineWidth(1)
			 	func()
	    		love.graphics.setStencilTest()
    		end

		end

		love.graphics.push('all')
    	love.graphics.setLineWidth(1)
    	love.graphics.setLineStyle("rough")
    	love.graphics.setBlendMode('replace')

    	-- vertical lines
    	if self._snap[1] >= min_grid_draw then
	    	for x = 0,game_width,self._snap[1] do
	    		if x+offx == 0 then
					love.graphics.setLineWidth(3)
	    		else
	    			love.graphics.setLineWidth(1)
	    		end

	    		stencilLine(function()
	    			love.graphics.line(x+offx, 0, x+offx, game_height)
	    		end)
	    	end
	    end

    	-- horizontal lines
    	if self._snap[2] >= min_grid_draw then
	    	for y = 0,game_height,self._snap[2] do
	    		if y+offy == 0 then
	    			love.graphics.setLineWidth(3)
	    		else
	    			love.graphics.setLineWidth(1)
	    		end

	    		stencilLine(function()
	    			love.graphics.line(0, y+offy, game_width, y+offy)
	    		end)
	    	end
	    end
    	love.graphics.pop()
	end,

	_checkLayerArg = function(self, layer)
		if layer == nil then
			return self:_checkLayerArg(0)
		end
		if type(layer) == "number" then
			layer = "layer"..tostring(layer)
			self.layers[layer] = ifndef(self.layers[layer],{})
		end
		return layer
	end,

	getList = function(self, obj_type) 
		local obj_list = {}
		for layer, data in pairs(self.layers) do
			obj_list[layer] = data[obj_type]
		end
		return obj_list
	end,

	addEntity = function(self, ...)
		local args = {...}
		if type(args[1]) == "string" then
			return self:_addEntityStr(unpack(args))
		end
		if type(args[1]) == "table" then
			return self:_addEntityTable(unpack(args))
		end
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

		if not assets[img_name] then return end

		-- check if the spritebatch exists yet
		self.layers[layer]["tile"] = ifndef(self.layers[layer]["tile"], {})
		self.images[img_name] = ifndef(self.images[img_name], Image(img_name))
		self.layers[layer].tile[img_name] = ifndef(self.layers[layer].tile[img_name], love.graphics.newSpriteBatch(self.images[img_name]()))

		-- add tile to batch
		local spritebatch = self.layers[layer].tile[img_name]
		local sb_id = spritebatch:add(love.graphics.newQuad(img_info.x, img_info.y, img_info.width, img_info.height, self.images[img_name].width, self.images[img_name].height), x, y)

		-- add tile info to "hashtable"
		self.hash_tile:add(x,y,
		{
			layer=layer,
			x=x,
			y=y,
			img_name=img_name,
			crop=img_info,
			id=sb_id,
			from_file=from_file
		})
	end,

	removeTile = function(self, x, y, layer, img_name)
		layer = self:_checkLayerArg(layer)
		local rm_tiles = {}

		-- find tiles that should be removed
		local tiles = self.hash_tile:search(x, y)
		for hash, tile in pairs(tiles) do
			local can_remove = true

			if tile.layer ~= layer  then
				can_remove = false
			end
			if img_name and tile.img_name ~= img_name then
				can_remove = false
			end

			if can_remove then
				table.insert(rm_tiles, tile)
				self.hash_tile:delete(x, y, tile)
			end
		end

		-- remove them from spritebatches
		for l_name, it_layer in pairs(self.layers) do
			if layer == l_name then
				for t, tile in ipairs(rm_tiles) do
					it_layer.tile[tile.img_name]:set(tile.id, 0, 0, 0, 0, 0)
				end
			end
		end
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
	end,

	_real_draw = function(self)
		self._is_active = true
		local layer_count = 0
		for nam, lay in pairs(self.layers) do
			layer_count = layer_count + 1
		end

		for l = 0,layer_count-1 do
			local name = 'layer'..tostring(l)
			local layer = self.layers[name]

			if layer.entity then
				for i_e, entity in ipairs(layer.entity) do
					entity:draw()
				end
			end

			if layer.tile then
				for name, tile in pairs(layer.tile) do
					love.graphics.draw(tile)
				end
			end

			if layer.hitbox and self.draw_hitboxes then
				for i_h, hitbox in ipairs(layer.hitbox) do
					hitbox:draw()
				end
			end
		end
	end,

	draw = function(self) 
	    if BlankE._ide_mode then
			function _getMouseXY(dont_snap)
				local cam_x, cam_y
				if not self._fake_view.disabled then
					cam_x, cam_y = self._fake_view.camera:cameraCoords(self._fake_view:mousePosition())
					local cam_pos = {self._fake_view:position()}
					cam_x = cam_x - ((self._fake_view.port_width/2) - cam_pos[1])
					cam_y = cam_y - ((self._fake_view.port_height/2) - cam_pos[2])
				else
					cam_x, cam_y = mouse_x, mouse_y
				end
				local mx, my = cam_x, cam_y

				if not dont_snap then
					mx = mx-(mx%self._snap[1])
					my = my-(my%self._snap[2])
				end

				return {mx, my}
			end

	    	self:_drawGrid() -- work on grid drawing (performace improvement)
	    	self._fake_view:attach()

	    	-- reset hitbox vars
	    	if _place_type ~= 'hitbox' or (_place_type == 'hitbox' and not _place_obj) then
				hitbox_points = {}
				hitbox_rem_point = true
	    	end

	    	-- placing object on click
	    	local _placeXY = _getMouseXY()
	    	BlankE._mouse_x, BlankE._mouse_y = unpack(_placeXY)
	    	if _btn_place() and _place_type then
	    		if _placeXY[1] ~= _last_place[1] or _placeXY[2] ~= _last_place[2] then
	    			_last_place = _placeXY

	    			if _place_type == 'entity' then
	    				local new_entity = self:addEntity(_place_obj, _placeXY[1], _placeXY[2], _place_layer)
	    				new_entity._loadedFromFile = true
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
	    			self:removeTile(_placeXY[1], _placeXY[2], nil, _place_obj.img_name)
	    		end

	    		if _place_type == 'hitbox' then
	    			if #hitbox_points > 0 and hitbox_rem_point then
		    			table.remove(hitbox_points, #hitbox_points)
		    			table.remove(hitbox_points, #hitbox_points)
		    			hitbox_rem_point = false
		    		elseif #hitbox_points == 0 then
		    			local new_mx, new_my = unpack(_getMouseXY(true))
					    self:removeHitboxAtPoint(new_mx, new_my)
		    		end
	    		end
	    	else
	    		if _place_type == 'hitbox' then
	    			hitbox_rem_point = true
	    		end
	    	end

	    	if not self._fake_view.disabled then
		    	if _btn_drag() then
		    		-- on down
			    	if not _dragging then
			    		_dragging = true
			    		_view_initial_pos = {self._fake_view:position()}
			    		_initial_mouse_pos = {mouse_x, mouse_y}
			    	end
			    	-- on hold
			    	if _dragging then
			    		local _drag_dist = {mouse_x-_initial_mouse_pos[1], mouse_y-_initial_mouse_pos[2]}
			    		self._fake_view:moveToPosition(
			    			_view_initial_pos[1] - _drag_dist[1],
			    			_view_initial_pos[2] - _drag_dist[2]
			    		)
			    	end
			    end
		    	-- on release
		    	if not _btn_drag() and _dragging then
		    		_dragging = false
		    	end
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
		    	for h, hitbox in ipairs(layer.hitbox) do
		    		hitbox:draw()
		    	end
		    end

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